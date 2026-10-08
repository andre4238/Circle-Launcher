//
//  LicenseTests.swift
//  Circle LauncherTests
//
//  Direct (.dmg) build: licence key, one device per licence, offline grace.
//  Runs with the scheme "Circle Launcher Direct" (configuration Debug-Direct).
//

#if DIRECT
import AppKit
import Foundation
import Testing
@testable import CircleLauncher

/// Behaves like the licence server for a handful of keys.
@MainActor
private final class FakeServer: LicenseTransport {
    struct License { var id: String; var policy: String; var machines: [String: String] = [:]; var suspended = false }
    var licenses: [String: License] = [:]
    var isReachable = true
    private(set) var requests: [URLRequest] = []

    private func reply(_ status: Int, _ object: Any, for request: URLRequest) -> (Data, HTTPURLResponse) {
        (try! JSONSerialization.data(withJSONObject: object), HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        guard isReachable else { throw URLError(.notConnectedToInternet) }
        let path = request.url!.path
        let body = request.httpBody.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]
        let authorized = request.value(forHTTPHeaderField: "Authorization").map { String($0.dropFirst("License ".count)) }

        if path.hasSuffix("/licenses/actions/validate-key") {
            let meta = body?["meta"] as? [String: Any]
            let scope = meta?["scope"] as? [String: Any]
            guard let key = meta?["key"] as? String, let license = licenses[key] else {
                return reply(200, ["meta": ["valid": false, "code": "NOT_FOUND"], "data": NSNull()], for: request)
            }
            let fingerprint = scope?["fingerprint"] as? String ?? ""
            let code: String
            if license.suspended { code = "SUSPENDED" }
            else if license.machines.isEmpty { code = "NO_MACHINES" }
            else if license.machines[fingerprint] == nil { code = "FINGERPRINT_SCOPE_MISMATCH" }
            else { code = "VALID" }
            let data: [String: Any] = ["id": license.id, "type": "licenses", "relationships": ["policy": ["data": ["type": "policies", "id": license.policy]]]]
            return reply(200, ["meta": ["valid": code == "VALID", "code": code], "data": data], for: request)
        }
        if path.hasSuffix("/machines"), request.httpMethod == "POST" {
            guard let key = authorized, var license = licenses[key] else { return reply(401, ["errors": [["code": "LICENSE_INVALID"]]], for: request) }
            let fingerprint = (((body?["data"] as? [String: Any])?["attributes"] as? [String: Any])?["fingerprint"] as? String) ?? ""
            if license.machines[fingerprint] != nil { return reply(422, ["errors": [["code": "FINGERPRINT_TAKEN"]]], for: request) }
            if license.machines.count >= 1 { return reply(422, ["errors": [["code": "MACHINE_LIMIT_EXCEEDED"]]], for: request) }
            let id = "machine-\(license.machines.count + 1)"
            license.machines[fingerprint] = id
            licenses[key] = license
            return reply(201, ["data": ["id": id, "type": "machines"]], for: request)
        }
        if path.contains("/machines/"), request.httpMethod == "DELETE" {
            guard let key = authorized, var license = licenses[key] else { return reply(401, [:], for: request) }
            let id = request.url!.lastPathComponent
            license.machines = license.machines.filter { $0.value != id }
            licenses[key] = license
            return reply(204, [:], for: request)
        }
        if path.hasSuffix("/machines") {
            guard let key = authorized, let license = licenses[key] else { return reply(401, [:], for: request) }
            return reply(200, ["data": license.machines.map { ["id": $0.value, "type": "machines", "attributes": ["fingerprint": $0.key]] }], for: request)
        }
        return reply(404, [:], for: request)
    }
}

@MainActor
private final class MemoryStorage: LicenseStorage {
    var key: String?
    var lastConfirmed: Date?
    var machineID: String?
}

@MainActor
struct LicenseTests {
    private static let circlePolicy = "6e440612-07aa-4811-aa17-cc7b1f495f20"
    private static let otherPolicy = "011f5bc0-640a-4781-9dbb-f19811eb6522"   // Editavo PDF Lifetime

    private let server = FakeServer()
    private var storage = MemoryStorage()
    private final class Clock { var now = Date(timeIntervalSince1970: 1_800_000_000) }
    private let clock = Clock()

    init() {
        server.licenses["GOOD-KEY"] = .init(id: "lic-1", policy: Self.circlePolicy)
        server.licenses["EDITAVO-KEY"] = .init(id: "lic-2", policy: Self.otherPolicy)
    }

    private func service(_ storage: MemoryStorage, fingerprint: String = "this-mac") -> LicenseService {
        let clock = clock
        return LicenseService(transport: server, storage: storage, fingerprint: fingerprint, deviceName: "Test-Mac", now: { clock.now })
    }

    @Test func firstActivationRegistersThisMacAndStoresTheKey() async throws {
        let outcome = await service(storage).activate(key: "  good–key \n")   // typed with a dash and spaces
        #expect(outcome == .valid)
        #expect(storage.key == "GOOD-KEY")
        #expect(storage.lastConfirmed == clock.now)
        #expect(storage.machineID == "machine-1")
        #expect(server.licenses["GOOD-KEY"]?.machines == ["this-mac": "machine-1"])

        // The validation names this app's product and this device; the activation is authorised by the key.
        let validation = try #require(server.requests.first)
        #expect(validation.url?.host == "license.streamwriter.studio")
        let body = try #require(validation.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let scope = try #require((json["meta"] as? [String: Any])?["scope"] as? [String: String])
        #expect(scope == ["fingerprint": "this-mac", "product": LicenseServer.production.productID])
        #expect(validation.value(forHTTPHeaderField: "Authorization") == nil)
        let activation = server.requests.first { $0.httpMethod == "POST" && $0.url!.path.hasSuffix("/machines") }
        #expect(activation?.value(forHTTPHeaderField: "Authorization") == "License GOOD-KEY")

        // Next launch: confirmed with a single request, without registering again.
        let before = server.requests.count
        #expect(await service(storage).checkStoredKey() == .valid)
        #expect(server.requests.count == before + 1)
    }

    @Test func keysOfOtherProductsUnknownKeysAndEmptyInputAreRejected() async {
        #expect(await service(storage).activate(key: "EDITAVO-KEY") == .rejected(.wrongProduct))
        #expect(server.licenses["EDITAVO-KEY"]!.machines.isEmpty, "a key of another product must not be bound to this Mac")
        #expect(await service(storage).activate(key: "NO-SUCH-KEY") == .rejected(.notFound))
        #expect(await service(storage).activate(key: "   ") == .rejected(.emptyKey))
        server.licenses["GOOD-KEY"]?.suspended = true
        #expect(await service(storage).activate(key: "GOOD-KEY") == .rejected(.suspended))
        #expect(storage.key == nil)
    }

    @Test func oneLicenceIsValidForOneMacOnly() async {
        #expect(await service(storage, fingerprint: "mac-a").activate(key: "GOOD-KEY") == .valid)
        let second = MemoryStorage()
        #expect(await service(second, fingerprint: "mac-b").activate(key: "GOOD-KEY") == .rejected(.deviceLimit))
        #expect(second.key == nil)
        #expect(server.licenses["GOOD-KEY"]?.machines.count == 1)
    }

    @Test func deactivatingFreesTheLicenceForAnotherMac() async {
        _ = await service(storage, fingerprint: "mac-a").activate(key: "GOOD-KEY")
        #expect(await service(storage, fingerprint: "mac-a").deactivateThisDevice())
        #expect(storage.key == nil)
        #expect(storage.lastConfirmed == nil)
        #expect(server.licenses["GOOD-KEY"]!.machines.isEmpty)
        #expect(await service(storage, fingerprint: "mac-a").checkStoredKey() == .unlicensed)

        let macB = MemoryStorage()
        #expect(await service(macB, fingerprint: "mac-b").activate(key: "GOOD-KEY") == .valid)
        // Without network the licence stays where it is.
        server.isReachable = false
        #expect(await service(macB, fingerprint: "mac-b").deactivateThisDevice() == false)
        #expect(macB.key == "GOOD-KEY")
    }

    @Test func withoutNetworkTheLastConfirmationCountsForTwoWeeks() async {
        _ = await service(storage).activate(key: "GOOD-KEY")
        server.isReachable = false
        clock.now.addTimeInterval(13 * 86_400)
        #expect(service(storage).hasRecentConfirmation)
        #expect(await service(storage).checkStoredKey() == .offlineGrace)
        clock.now.addTimeInterval(2 * 86_400)
        #expect(service(storage).hasRecentConfirmation == false)
        #expect(await service(storage).checkStoredKey() == .rejected(.offline))
        // A key that was never confirmed cannot be entered offline.
        let fresh = MemoryStorage()
        #expect(await service(fresh).activate(key: "GOOD-KEY") == .rejected(.offline))
        #expect(fresh.key == nil)
        // A licence removed on the server locks the app as soon as the server answers again.
        storage.lastConfirmed = clock.now
        server.isReachable = true
        server.licenses["GOOD-KEY"] = nil
        #expect(await service(storage).checkStoredKey() == .rejected(.notFound))
    }

    @Test func theAppStaysLockedUntilAValidKeyIsEntered() async {
        let licensing = Licensing(service: service(storage))
        #expect(licensing.state == .checking)
        #expect(licensing.isUnlocked == false)

        await licensing.checkStoredKey()
        #expect(licensing.state == .locked)
        #expect(licensing.lastError == nil, "no key yet is not an error")

        #expect(await licensing.activate(licenseKey: "EDITAVO-KEY") == false)
        #expect(licensing.state == .locked)
        #expect(licensing.lastError == LicenseFailure.wrongProduct.message)

        #expect(await licensing.activate(licenseKey: "GOOD-KEY"))
        #expect(licensing.state == .unlocked)
        #expect(licensing.lastError == nil)
        #expect(licensing.maskedLicenseKey == "GOOD…-KEY")

        // Next launch with a recently confirmed key: usable at once, before the server has answered.
        #expect(Licensing(service: service(storage)).state == .unlocked)

        #expect(await licensing.deactivateThisDevice())
        #expect(licensing.state == .locked)
        #expect(licensing.maskedLicenseKey == nil)
        #expect(Licensing(service: service(storage)).state == .checking)
    }

    @Test func aLicenceRevokedOnTheServerLocksAnAppThatStartedUnlocked() async {
        _ = await service(storage).activate(key: "GOOD-KEY")
        let licensing = Licensing(service: service(storage))
        #expect(licensing.isUnlocked)
        server.licenses["GOOD-KEY"]?.suspended = true
        await licensing.checkStoredKey()
        #expect(licensing.state == .locked)
        #expect(licensing.lastError == LicenseFailure.suspended.message)
    }

    @Test func licenceWindowCannotBeClosedAndFollowsTheLicenceState() async throws {
        let licensing = Licensing(service: service(storage))
        await licensing.checkStoredKey()
        let controller = LicenseWindowController(licensing: licensing)
        let window = try #require(controller.window)
        #expect(window.styleMask.contains(.closable) == false)
        #expect(window.styleMask.contains(.miniaturizable) == false)
        controller.present()
        #expect(window.isVisible)

        // A rejected key leaves the window open; the right key closes it.
        await licensing.activate(licenseKey: "NO-SUCH-KEY")
        try await Task.sleep(for: .milliseconds(150))
        #expect(window.isVisible)
        await licensing.activate(licenseKey: "GOOD-KEY")
        try await Task.sleep(for: .milliseconds(150))
        #expect(window.isVisible == false)
        // Unlocked: asking for the window does nothing.
        controller.present()
        #expect(window.isVisible == false)
        // Deactivating brings it back.
        await licensing.deactivateThisDevice()
        try await Task.sleep(for: .milliseconds(150))
        #expect(window.isVisible)
        window.orderOut(nil)
    }

    /// The real keychain of the sandboxed app, with its own entry (the customer's key is not touched).
    @Test func keyIsKeptInTheKeychainAcrossLaunches() throws {
        let suite = "com.asystems.circlelauncher.tests.license-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = KeychainLicenseStorage(service: suite, defaults: defaults)
        #expect(first.key == nil)
        first.key = "ABCDEF-123456-V3"
        first.lastConfirmed = clock.now
        first.machineID = "machine-9"
        let second = KeychainLicenseStorage(service: suite, defaults: defaults)
        #expect(second.key == "ABCDEF-123456-V3")
        #expect(second.lastConfirmed == clock.now)
        #expect(second.machineID == "machine-9")
        second.key = nil
        #expect(KeychainLicenseStorage(service: suite, defaults: defaults).key == nil)
    }
}
#endif
