import AudioToolbox
import Foundation
import UIKit
import Combine

@MainActor
class ContentViewModel: ObservableObject {
    @Published var selectedLed: String?
    @Published var isLongPressing = false
    @Published private(set) var connectionState: ConnectionState = .disconnected
    private var webSocketManager: WebSocketManager!
    private var pingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupWebSocket()
        startPingTimer()
        setupAppStateObserver()
    }

    deinit {
        pingTimer?.invalidate()
        pingTimer = nil
        NotificationCenter.default.removeObserver(self)
    }

    func sendCommand(_ command: String, led: String? = nil) {
        webSocketManager.send(command: command, led: led)
    }

    private func setupWebSocket() {
        webSocketManager = WebSocketManager()
        webSocketManager.onMessage = { [weak self] message in
            self?.selectedLed = message
        }
        webSocketManager.$connectionState
            .assign(to: \.connectionState, on: self)
            .store(in: &cancellables)
        webSocketManager.connect()
    }

    private func setupAppStateObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: .appDidBecomeActive,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc private func handleAppDidBecomeActive() {
        startPingTimer()
        webSocketManager.reconnectIfNeeded()
    }

    @objc private func handleAppDidEnterBackground() {
        pingTimer?.invalidate()
        pingTimer = nil
        webSocketManager.cancelReconnect()
    }

    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.webSocketManager.sendPing()
            }
        }
    }

    func triggerFeedbackConcurrently() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                AudioServicesPlaySystemSound(1104)
            }
            group.addTask {
                await UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
    }
}
