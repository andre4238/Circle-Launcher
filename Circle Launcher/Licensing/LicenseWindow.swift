//
//  LicenseWindow.swift
//  Circle Launcher
//
//  Licence window of the direct (.dmg) build: asks for the licence key. It has no close button;
//  while the app is locked, the launcher and the settings are not available.
//  Compiled only with the DIRECT condition.
//

#if DIRECT
import AppKit
import SwiftUI

struct LicenseGateView: View {
    @Bindable var licensing: Licensing
    let quit: () -> Void
    @State private var key = ""
    @FocusState private var keyFocused: Bool

    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 84, height: 84)
                .accessibilityHidden(true)
            Text("Activate Circle Launcher")
                .font(.system(size: 20, weight: .semibold))
                .multilineTextAlignment(.center)
            Text("Enter your license key to use Circle Launcher on this Mac.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            TextField("License key", text: $key)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, design: .monospaced))
                .autocorrectionDisabled()
                .focused($keyFocused)
                .disabled(licensing.isCheckingKey)
                .onSubmit(activate)
                .padding(.top, 4)

            Button(action: activate) {
                Group {
                    if licensing.isCheckingKey {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Activate")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(licensing.isCheckingKey || key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if let error = licensing.lastError {
                Text(error)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("A license is valid permanently for one Mac. To check it, the key is sent to the license server together with an anonymous device identifier.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("Buy a License …") { NSWorkspace.shared.open(LicenseServer.purchasePage) }
                Spacer()
                Button("Quit", action: quit)
            }
            .controlSize(.small)
        }
        .padding(28)
        .frame(width: 420)
        .onAppear { keyFocused = true }
    }

    private func activate() {
        guard !licensing.isCheckingKey else { return }
        Task { await licensing.activate(licenseKey: key) }
    }
}

/// Settings → General → License: the key in use and the way to move it to another Mac.
struct LicenseSettingsSection: View {
    @Bindable private var licensing = Licensing.shared
    @State private var confirmDeactivate = false
    @State private var deactivationFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundStyle(.blue)
                Text("License")
                    .font(.headline)
                Spacer()
                if let key = licensing.maskedLicenseKey {
                    Text(key)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            Text("The license is bound to this Mac. To use it on another Mac, deactivate it here first.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Deactivate License on This Mac", role: .destructive) { confirmDeactivate = true }
                .disabled(licensing.isCheckingKey)
                .confirmationDialog("Deactivate the license on this Mac? Afterwards Circle Launcher can only be used here again after entering a license key.", isPresented: $confirmDeactivate, titleVisibility: .visible) {
                    Button("Deactivate License on This Mac", role: .destructive, action: deactivate)
                    Button("Cancel", role: .cancel) {}
                }
                .alert("The license could not be deactivated.", isPresented: $deactivationFailed) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(licensing.lastError ?? "")
                }
        }
        .padding(.vertical, 8)
    }

    /// Talks to the licence state directly. (With `NSApplicationDelegateAdaptor`, `NSApp.delegate`
    /// is SwiftUI's own object and cannot be cast to `AppDelegate` – a call through it does nothing.)
    /// Once the app is locked again, the app delegate closes the settings and the licence window appears.
    private func deactivate() {
        Task {
            if await licensing.deactivateThisDevice() == false { deactivationFailed = true }
        }
    }
}

final class LicenseWindowController: NSWindowController {
    static let shared = LicenseWindowController(licensing: .shared)
    private let licensing: Licensing
    private var observer: NSObjectProtocol?

    init(licensing: Licensing) {
        self.licensing = licensing
        // No .closable: the window can only be left with a valid key or by quitting the app.
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 420), styleMask: [.titled, .fullSizeContentView], backing: .buffered, defer: false)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.level = .floating
        super.init(window: window)
        window.contentView = NSHostingView(rootView: LicenseGateView(licensing: licensing) { NSApp.terminate(nil) })
        window.setAccessibilityLabel("Activate Circle Launcher")
        // The window goes away by itself as soon as the app is unlocked.
        observer = NotificationCenter.default.addObserver(forName: Licensing.stateDidChange, object: licensing, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.licensing.isUnlocked { self.window?.orderOut(nil) } else { self.present() }
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// Shows the licence window (only while the app is locked).
    func present() {
        guard !licensing.isUnlocked, let window else { return }
        if !window.isVisible { window.center() }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif
