# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RemoteGPIO is a native iOS app (SwiftUI) that controls GPIO pins on a remote server via WebSocket. The app connects through Cloudflare Access authentication to send commands (up/down/stop) for LED control.

## Build Commands

```bash
# Build the project
xcodebuild build -project RemoteGPIO.xcodeproj -scheme RemoteGPIO -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'

# Run unit tests
xcodebuild test -project RemoteGPIO.xcodeproj -scheme RemoteGPIO -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4'

# Run UI tests
xcodebuild test -project RemoteGPIO.xcodeproj -scheme RemoteGPIO -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -only-testing:RemoteGPIOUITests
```

## Configuration Setup

Before building, copy and configure the credentials file:
```bash
cp RemoteGPIO/Config.xcconfig.example RemoteGPIO/Config.xcconfig
```

Edit `Config.xcconfig` with actual values for:
- `CF_ACCESS_CLIENT_ID` - Cloudflare Access client ID
- `CF_ACCESS_CLIENT_SECRET` - Cloudflare Access client secret
- `REMOTE_GPIO_URL` - WebSocket server hostname

These values are injected into `Info.plist` at build time and accessed via `EnvironmentConfig`.

## Architecture

**MVVM Pattern with Combine:**

```
RemoteGPIOApp (lifecycle) → ContentView (UI) → ContentViewModel → WebSocketManager
                                                      ↓
                                              EnvironmentConfig (credentials)
```

- **ContentView**: SwiftUI UI with action buttons (UP/STOP/DOWN) and LED selectors (L1-L4, ALL). Uses haptic feedback.
- **ContentViewModel**: `@MainActor` ViewModel managing state (`selectedLed`, `connectionState`), app lifecycle observers, and 30-second keepalive pings.
- **WebSocketManager**: Handles `URLSessionWebSocketTask` with auto-reconnection, Cloudflare Access headers, and connection state broadcasting.
- **EnvironmentConfig**: Type-safe loader for build-time configuration from `Info.plist`.

## WebSocket Protocol

Commands sent as JSON:
```json
{"command": "up|down|stop|select", "led": "L1|L2|L3|L4|ALL"}
```

Connection URL format: `wss://<REMOTE_GPIO_URL>/ws?name=ios`

## Key Implementation Details

- iOS 18.0+ deployment target
- No external dependencies (pure Apple frameworks)
- App pauses WebSocket ping timer when backgrounded, resumes on foreground
- Auto-reconnection on WebSocket errors with 5-second fallback timer
- `pong` messages are filtered out from UI state updates
