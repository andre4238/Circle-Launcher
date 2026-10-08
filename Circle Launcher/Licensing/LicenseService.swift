//
//  LicenseService.swift
//  Circle Launcher
//
//  Licence-key check of the direct (.dmg) build. Compiled only with the DIRECT condition
//  (configurations Debug-Direct / Release-Direct); the App Store build contains none of it.
//
//  Server: the self-hosted Keygen server that also serves StreamWriter Studio and Editavo PDF.
//  One licence is valid for one device (policy: maxMachines = 1) and never expires.
//

#if DIRECT
import CryptoKit
import Foundation
import IOKit
import Security

/// Where licences are checked and which licences belong to this app.
struct LicenseServer {
    var baseURL: URL
    /// Keygen product of Circle Launcher. Sent as scope, so the server rejects other products.
    var productID: String
    /// Policies whose keys unlock this app. Keys of other policies are rejected even if valid.
    var policyIDs: Set<String>

    static let production = LicenseServer(
        baseURL: URL(string: "https://license.streamwriter.studio/v1/accounts/10a81245-58c2-4480-b8e8-8bc14427097e")!,
        productID: "ec4ff285-95cd-4a21-8bae-73633ba79a3e",
        policyIDs: ["6e440612-07aa-4811-aa17-cc7b1f495f20"])   // Circle Launcher Lifetime

    /// Where a licence key can be bought.
    static let purchasePage = URL(string: "https://a-systems.io/en/software/circle-launcher")!
}

/// Why a key was not accepted. `message` is what the customer reads.
enum LicenseFailure: Error, Equatable {
    case emptyKey
    case notFound
    case wrongProduct
    case deviceLimit
    case suspended
    case expired
    case offline
    case server(String)

    init(code: String) {
        let c = code.uppercased()
        if c.contains("NOT_FOUND") { self = .notFound }
        else if c.contains("PRODUCT_SCOPE") || c.contains("POLICY_SCOPE") || c == "WRONG_PRODUCT" { self = .wrongProduct }
        else if c.contains("TOO_MANY") || c.contains("MACHINE_LIMIT") { self = .deviceLimit }
        else if c.contains("SUSPENDED") || c.contains("BANNED") { self = .suspended }
        else if c.contains("EXPIRED") { self = .expired }
        else { self = .server(c) }
    }

    var message: String {
        switch self {
        case .emptyKey: return "Please enter a license key."
        case .notFound: return "This license key is not known. Please check what you entered."
        case .wrongProduct: return "This license key belongs to a different product and is not valid for Circle Launcher."
        case .deviceLimit: return "This license is already activated on another Mac. Deactivate it there in Settings or contact support."
        case .suspended: return "This license has been suspended. Please contact support."
        case .expired: return "This license has expired."
        case .offline: return "The license server cannot be reached. Please check your internet connection and try again."
        case .server(let code): return "The license could not be confirmed (\(code))."
        }
    }
}

/// Result of a licence check.
enum LicenseOutcome: Equatable {
    /// The server confirmed the licence for this Mac.
    case valid
    /// The server could not be reached; the last confirmation is recent enough.
    case offlineGrace
    /// No key has been entered on this Mac.
    case unlicensed
    case rejected(LicenseFailure)

    var unlocks: Bool { self == .valid || self == .offlineGrace }
}

/// Network access of the licence check (replaced by a stub in tests).
protocol LicenseTransport {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

struct URLSessionLicenseTransport: LicenseTransport {
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }()

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await Self.session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }
}

/// Where the key and the bookkeeping of the last check are kept (replaced in tests).
protocol LicenseStorage: AnyObject {
    var key: String? { get set }
    var lastConfirmed: Date? { get set }
    var machineID: String? { get set }
}

/// Key in the keychain, bookkeeping in the app's settings.
final class KeychainLicenseStorage: LicenseStorage {
    private let service: String
    private let account = "license-key"
    private let defaults: UserDefaults
    private let confirmedKey = "CircleLauncherLicenseLastConfirmed"
    private let machineKey = "CircleLauncherLicenseMachineID"

    init(service: String = "com.asystems.circlelauncher.license", defaults: UserDefaults = .standard) {
        self.service = service
        self.defaults = defaults
    }

    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
    }

    var key: String? {
        get {
            var request = query
            request[kSecReturnData as String] = true
            request[kSecMatchLimit as String] = kSecMatchLimitOne
            var item: CFTypeRef?
            guard SecItemCopyMatching(request as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
            return String(data: data, encoding: .utf8)
        }
        set {
            SecItemDelete(query as CFDictionary)
            guard let newValue, !newValue.isEmpty else { return }
            var item = query
            item[kSecValueData as String] = Data(newValue.utf8)
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(item as CFDictionary, nil)
        }
    }

    var lastConfirmed: Date? {
        get { defaults.object(forKey: confirmedKey) as? Date }
        set { defaults.set(newValue, forKey: confirmedKey) }
    }

    var machineID: String? {
        get { defaults.string(forKey: machineKey) }
        set { defaults.set(newValue, forKey: machineKey) }
    }
}

/// Identifies this Mac towards the licence server: a hash of the hardware UUID. The UUID itself
/// never leaves the device.
enum DeviceFingerprint {
    static let current: String = {
        let digest = SHA256.hash(data: Data("com.asystems.circlelauncher:\(hardwareUUID() ?? fallbackID())".utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }()

    static var deviceName: String { Host.current().localizedName ?? "Mac" }

    private static func hardwareUUID() -> String? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        return IORegistryEntryCreateCFProperty(service, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String
    }

    /// Only used if the hardware UUID cannot be read: a random ID kept in the settings.
    private static func fallbackID() -> String {
        let key = "CircleLauncherLicenseDeviceID"
        if let stored = UserDefaults.standard.string(forKey: key) { return stored }
        let created = UUID().uuidString
        UserDefaults.standard.set(created, forKey: key)
        return created
    }
}

/// Talks to the licence server and remembers the key.
final class LicenseService {
    /// How long the app keeps working without reaching the server after a confirmed check.
    static let offlineGraceDays = 14

    private let server: LicenseServer
    private let transport: LicenseTransport
    private let storage: LicenseStorage
    private let fingerprint: String
    private let deviceName: String
    private let now: () -> Date
    private let mediaType = "application/vnd.api+json"

    init(server: LicenseServer = .production, transport: LicenseTransport = URLSessionLicenseTransport(), storage: LicenseStorage = KeychainLicenseStorage(),
         fingerprint: String = DeviceFingerprint.current, deviceName: String = DeviceFingerprint.deviceName, now: @escaping () -> Date = Date.init) {
        self.server = server
        self.transport = transport
        self.storage = storage
        self.fingerprint = fingerprint
        self.deviceName = deviceName
        self.now = now
    }

    var storedKey: String? { storage.key }

    /// A key is stored and the server confirmed it within the offline grace period.
    var hasRecentConfirmation: Bool {
        guard let key = storage.key, !key.isEmpty, let last = storage.lastConfirmed else { return false }
        let age = now().timeIntervalSince(last)
        return age >= 0 && age <= TimeInterval(Self.offlineGraceDays) * 86_400
    }

    /// Tidies a typed or pasted key: no spaces, plain hyphens (text fields and mail programs may
    /// turn them into dashes), capital letters.
    static func normalized(_ rawKey: String) -> String {
        var key = rawKey.uppercased()
        for dash in ["\u{2010}", "\u{2011}", "\u{2012}", "\u{2013}", "\u{2014}", "\u{2212}"] { key = key.replacingOccurrences(of: dash, with: "-") }
        return key.components(separatedBy: .whitespacesAndNewlines).joined()
    }

    /// Check at launch: confirms the stored key. Without network the last confirmation counts
    /// for `offlineGraceDays`.
    func checkStoredKey() async -> LicenseOutcome {
        guard let key = storage.key, !key.isEmpty else { return .unlicensed }
        let outcome = await confirm(key: key)
        if outcome == .rejected(.offline), hasRecentConfirmation { return .offlineGrace }
        return outcome
    }

    /// Entering a key: validates it and registers this Mac as the licence's device.
    func activate(key rawKey: String) async -> LicenseOutcome {
        let key = Self.normalized(rawKey)
        guard !key.isEmpty else { return .rejected(.emptyKey) }
        let outcome = await confirm(key: key)
        if outcome == .valid { storage.key = key }
        return outcome
    }

    /// Frees the licence for another Mac and forgets the key here. Returns false if the server
    /// could not be reached (the licence then stays bound to this Mac).
    func deactivateThisDevice() async -> Bool {
        guard let key = storage.key, !key.isEmpty else { return true }
        do {
            let validation = try await validate(key: key)
            let machine: String?
            if let id = validation.machineID ?? storage.machineID { machine = id }
            else if let license = validation.licenseID { machine = try await findMachine(key: key, licenseID: license) }
            else { machine = nil }
            if let machine { try await deleteMachine(key: key, machineID: machine) }
        } catch {
            return false
        }
        forgetLocally()
        return true
    }

    /// Removes the key and the bookkeeping from this Mac (the server is not contacted).
    func forgetLocally() {
        storage.key = nil
        storage.lastConfirmed = nil
        storage.machineID = nil
    }

    /// Validates; if the licence is fine but this Mac is not registered yet, registers it.
    private func confirm(key: String) async -> LicenseOutcome {
        do {
            var validation = try await validate(key: key)
            if !validation.valid, validation.needsActivation, let license = validation.licenseID {
                try await activateMachine(key: key, licenseID: license)
                validation = try await validate(key: key)
            }
            guard validation.valid else { return .rejected(LicenseFailure(code: validation.code)) }
            storage.lastConfirmed = now()
            if let machine = validation.machineID { storage.machineID = machine }
            return .valid
        } catch let failure as LicenseFailure {
            return .rejected(failure)
        } catch {
            return .rejected(.offline)
        }
    }

    // MARK: Server calls

    private struct Validation {
        var valid: Bool
        var code: String
        var licenseID: String?
        var machineID: String?
        var needsActivation: Bool { ["NO_MACHINE", "NO_MACHINES", "FINGERPRINT_SCOPE_MISMATCH"].contains(code) }
    }

    private func request(_ path: String, method: String = "GET", key: String? = nil, body: Any? = nil) throws -> URLRequest {
        var request = URLRequest(url: URL(string: server.baseURL.absoluteString + path)!)
        request.httpMethod = method
        request.setValue(mediaType, forHTTPHeaderField: "Accept")
        if let key { request.setValue("License \(key)", forHTTPHeaderField: "Authorization") }
        if let body {
            request.setValue(mediaType, forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return request
    }

    private func validate(key: String) async throws -> Validation {
        let body: [String: Any] = ["meta": ["key": key, "scope": ["fingerprint": fingerprint, "product": server.productID]]]
        let (data, response) = try await transport.send(try request("/licenses/actions/validate-key", method: "POST", body: body))
        guard response.statusCode < 500, let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any], let meta = root["meta"] as? [String: Any] else {
            throw LicenseFailure.offline
        }
        var result = Validation(valid: meta["valid"] as? Bool ?? false, code: (meta["code"] as? String) ?? "UNKNOWN")
        let license = root["data"] as? [String: Any]
        result.licenseID = license?["id"] as? String
        // The key must belong to Circle Launcher: a valid key of another product does not count
        // and is never bound to this Mac.
        if let license {
            let policy = (((license["relationships"] as? [String: Any])?["policy"] as? [String: Any])?["data"] as? [String: Any])?["id"] as? String
            if policy == nil || !server.policyIDs.contains(policy!) {
                result.valid = false
                result.code = "WRONG_PRODUCT"
            }
        }
        for item in (root["included"] as? [[String: Any]]) ?? [] where item["type"] as? String == "machines" {
            if (item["attributes"] as? [String: Any])?["fingerprint"] as? String == fingerprint { result.machineID = item["id"] as? String }
        }
        return result
    }

    private func activateMachine(key: String, licenseID: String) async throws {
        let body: [String: Any] = ["data": [
            "type": "machines",
            "attributes": ["fingerprint": fingerprint, "platform": "macOS", "name": deviceName],
            "relationships": ["license": ["data": ["type": "licenses", "id": licenseID]]],
        ]]
        let (data, response) = try await transport.send(try request("/machines", method: "POST", key: key, body: body))
        switch response.statusCode {
        case 201:
            storage.machineID = (((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?["data"] as? [String: Any])?["id"] as? String
        case 422:
            let codes = errorCodes(in: data)
            // Already registered for this licence: fine.
            if codes.contains(where: { $0.contains("TAKEN") || $0.contains("ALREADY") || $0.contains("CONFLICT") }) { return }
            throw LicenseFailure(code: codes.first ?? "MACHINE_LIMIT_EXCEEDED")
        case 500...:
            throw LicenseFailure.offline
        default:
            throw LicenseFailure(code: errorCodes(in: data).first ?? "ACTIVATION_FAILED_\(response.statusCode)")
        }
    }

    private func findMachine(key: String, licenseID: String) async throws -> String? {
        let (data, response) = try await transport.send(try request("/machines?license=\(licenseID)", key: key))
        guard response.statusCode == 200, let list = ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?["data"] as? [[String: Any]] else { return nil }
        return list.first { ($0["attributes"] as? [String: Any])?["fingerprint"] as? String == fingerprint }?["id"] as? String
    }

    private func deleteMachine(key: String, machineID: String) async throws {
        let (_, response) = try await transport.send(try request("/machines/\(machineID)", method: "DELETE", key: key))
        guard [200, 204, 404].contains(response.statusCode) else { throw LicenseFailure.offline }
    }

    private func errorCodes(in data: Data) -> [String] {
        let errors = ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?["errors"] as? [[String: Any]]
        return (errors ?? []).compactMap { ($0["code"] as? String)?.uppercased() }
    }
}
#endif
