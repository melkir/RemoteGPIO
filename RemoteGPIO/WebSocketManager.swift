import Foundation
import Combine

enum ConnectionState {
    case disconnected
    case connecting
    case connected
}

@MainActor
class WebSocketManager: NSObject, URLSessionWebSocketDelegate {
    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession!
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    @Published private(set) var connectionState: ConnectionState = .disconnected

    var onMessage: ((String) -> Void)?

    override init() {
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }

    func cancelReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }

    func reconnectIfNeeded() {
        if connectionState == .disconnected {
            connect()
        }
    }
    
    func connect() {
        // Clean up any existing socket
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil

        connectionState = .connecting
        var request = URLRequest(url: Config.baseURL)
        request.setValue(Config.cfAccessClientId, forHTTPHeaderField: "cf-access-client-id")
        request.setValue(Config.cfAccessClientSecret, forHTTPHeaderField: "cf-access-client-secret")

        webSocket = session.webSocketTask(with: request)
        webSocket?.resume()
        receiveMessage()
    }
    
    func send(command: String, led: String? = nil) {
        guard connectionState == .connected else { return }

        var message: [String: String] = ["command": command]
        if let led = led {
            message["led"] = led
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let message = URLSessionWebSocketTask.Message.string(jsonString)
            webSocket?.send(message) { [weak self] error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                    Task { @MainActor in
                        self?.handleConnectionError()
                    }
                }
            }
        }
    }
    
    func sendPing() {
        guard connectionState == .connected else { return }
        webSocket?.sendPing { [weak self] error in
            if let error = error {
                print("WebSocket ping error: \(error)")
                Task { @MainActor in
                    self?.handleConnectionError()
                }
            }
        }
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self?.onMessage?(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self?.onMessage?(text)
                        }
                    @unknown default:
                        break
                    }
                    self?.receiveMessage()
                case .failure(let error):
                    print("WebSocket receive error: \(error)")
                    self?.handleConnectionError()
                }
            }
        }
    }
    
    private func handleConnectionError() {
        // Guard against multiple error handlers firing
        guard connectionState != .disconnected else { return }

        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        connectionState = .disconnected
        scheduleReconnect()
    }

    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0) // 1s, 2s, 4s, 8s, 16s, max 30s
        reconnectAttempts += 1
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                if self?.connectionState == .disconnected {
                    self?.connect()
                }
            }
        }
    }
    
    func disconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        session.invalidateAndCancel()
    }
    
    // MARK: - URLSessionWebSocketDelegate
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Task { @MainActor in
            reconnectAttempts = 0
            connectionState = .connected
            print("WebSocket connected")
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task { @MainActor in
            handleConnectionError()
        }
    }
} 
