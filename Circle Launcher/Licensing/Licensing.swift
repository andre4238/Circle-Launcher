//
//  Licensing.swift
//  Circle Launcher
//
//  Licence state of the direct (.dmg) build: locked until a valid key has been entered.
//  Compiled only with the DIRECT condition.
//

#if DIRECT
import Foundation
import Observation

@Observable
final class Licensing {
    enum State: Equatable {
        /// The licence server has not answered yet (shortly after launch).
        case checking
        case locked
        case unlocked
    }

    static let shared: Licensing = {
        #if DEBUG
        // The self-test (`-CircleAutoActivate`) must never touch a licence that is really in use
        // on this Mac: it gets its own keychain entry and its own settings.
        if UserDefaults.standard.string(forKey: "CircleAutoActivate") != nil,
           let defaults = UserDefaults(suiteName: "com.asystems.circlelauncher.selftest") {
            return Licensing(service: LicenseService(storage: KeychainLicenseStorage(service: "com.asystems.circlelauncher.license.selftest", defaults: defaults)))
        }
        #endif
        return Licensing()
    }()
    static let stateDidChange = Notification.Name("CircleLauncherLicensingStateDidChange")

    private(set) var state: State
    /// A key is being checked right now.
    private(set) var isCheckingKey = false
    var lastError: String?

    @ObservationIgnored private let service: LicenseService

    init(service: LicenseService = LicenseService()) {
        self.service = service
        // A launcher should work the moment the Mac has started – also before the network is up.
        // With a recently confirmed key the app is usable at once; the check then runs in the
        // background and locks the app again if the server says the licence is no longer valid.
        state = service.hasRecentConfirmation ? .unlocked : .checking
    }

    var isUnlocked: Bool { state == .unlocked }

    /// The stored key with everything but the ends hidden, for display in Settings.
    var maskedLicenseKey: String? {
        guard let key = service.storedKey, key.count >= 8 else { return nil }
        return "\(key.prefix(4))…\(key.suffix(4))"
    }

    private func apply(_ outcome: LicenseOutcome) {
        switch outcome {
        case .valid, .offlineGrace, .unlicensed: lastError = nil
        case .rejected(let failure): lastError = failure.message
        }
        let new: State = outcome.unlocks ? .unlocked : .locked
        guard state != new else { return }
        state = new
        NotificationCenter.default.post(name: Self.stateDidChange, object: self)
    }

    /// Launch: confirms the key stored on this Mac (if any) with the licence server.
    func checkStoredKey() async {
        guard !isCheckingKey else { return }
        isCheckingKey = true
        defer { isCheckingKey = false }
        apply(await service.checkStoredKey())
    }

    /// Checks the entered key and registers this Mac for it. Returns true when the app is unlocked.
    @discardableResult
    func activate(licenseKey: String) async -> Bool {
        guard !isCheckingKey else { return false }
        isCheckingKey = true
        lastError = nil
        defer { isCheckingKey = false }
        apply(await service.activate(key: licenseKey))
        return isUnlocked
    }

    /// Frees the licence for another Mac. Afterwards this Mac needs a key again.
    @discardableResult
    func deactivateThisDevice() async -> Bool {
        guard !isCheckingKey else { return false }
        isCheckingKey = true
        defer { isCheckingKey = false }
        guard await service.deactivateThisDevice() else {
            lastError = LicenseFailure.offline.message
            return false
        }
        apply(.unlicensed)
        return true
    }

    #if DEBUG
    /// Debug hook: removes the key from this Mac without telling the server.
    func forgetStoredKeyForTesting() { service.forgetLocally() }
    #endif
}
#endif
