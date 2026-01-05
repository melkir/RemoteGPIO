# RemoteGPIO

SwiftUI app to control GPIO pins on a remote server via WebSocket with Cloudflare Access authentication.

![RemoteGPIO Screenshot](https://github.com/user-attachments/assets/5eef8ee5-4c99-4839-939e-fc299a29fc59)

## Features

- GPIO control buttons (UP, STOP, DOWN)
- LED selector (L1-L4, ALL)
- Real-time connection status indicator
- Auto-reconnection with exponential backoff
- Haptic feedback on interactions

## Requirements

- iOS 18.0+
- Xcode 16+
- Cloudflare Access credentials for your GPIO server

## Setup

1. Clone the repository

2. Copy and configure credentials:
   ```bash
   cp RemoteGPIO/Config.xcconfig.example RemoteGPIO/Config.xcconfig
   ```

3. Edit `Config.xcconfig` with your values:
   ```
   CF_ACCESS_CLIENT_ID = your_client_id_here
   CF_ACCESS_CLIENT_SECRET = your_client_secret_here
   REMOTE_GPIO_URL = your_server_hostname_here
   ```

4. Open `RemoteGPIO.xcodeproj` in Xcode and run

## Architecture

```
RemoteGPIOApp → ContentView → ContentViewModel → WebSocketManager
                                                        ↓
                                                 EnvironmentConfig
```

- **MVVM pattern** with Combine for reactive state management
- **WebSocketManager**: Native `URLSessionWebSocketTask` with auto-reconnection
- **EnvironmentConfig**: Build-time configuration injection via `Info.plist`

## WebSocket Protocol

Commands are sent as JSON:
```json
{"command": "up|down|stop|select", "led": "L1|L2|L3|L4|ALL"}
```

## License

MIT
