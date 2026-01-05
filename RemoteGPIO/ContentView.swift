import AudioToolbox  // Add this import at the top of the file
import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 32)

                ActionButton(
                    action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.sendCommand("up")
                    }, icon: "chevron.up",
                    size: geometry.size.width * 0.24)

                Spacer()

                ActionButton(
                    action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.sendCommand("stop")
                    }, icon: "pause.fill",
                    size: geometry.size.width * 0.27)

                Spacer()

                ActionButton(
                    action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.sendCommand("down")
                    }, icon: "chevron.down",
                    size: geometry.size.width * 0.24)

                Spacer()

                HStack(spacing: geometry.size.width * 0.18) {
                    ForEach(["L1", "L2", "L3", "L4"], id: \.self) { led in
                        LedButton(
                            led: led,
                            isSelected: viewModel.selectedLed == led
                                || viewModel.selectedLed == "ALL"
                        ) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            viewModel.sendCommand("select", led: led)
                        }
                        .frame(
                            width: geometry.size.width * 0.052, height: geometry.size.width * 0.052
                        )
                        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedLed)
                    }
                }
                .frame(width: geometry.size.width * 0.8)

                Spacer()

                ActionButton(
                    action: {}, icon: "circle.circle.fill",
                    size: geometry.size.width * 0.24,
                    connectionState: viewModel.connectionState
                )
                .scaleEffect(viewModel.isLongPressing ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isLongPressing)
                .simultaneousGesture(
                    LongPressGesture().onEnded { _ in
                        viewModel.isLongPressing = true
                        Task {
                            await viewModel.triggerFeedbackConcurrently()
                        }
                        viewModel.sendCommand("select", led: "ALL")

                        // Add a small delay before setting isLongPressing to false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            viewModel.isLongPressing = false
                        }
                    }
                )
                .simultaneousGesture(
                    TapGesture().onEnded {
                        if viewModel.isLongPressing {
                            return
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.sendCommand("select")
                    })
                Spacer().frame(height: 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
    }
}

struct ActionButton: View {
    let action: () -> Void
    let icon: String
    let size: CGFloat
    var connectionState: ConnectionState? = nil

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(
                        Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5, opacity: 0.5), lineWidth: 1
                    )
                    .frame(width: size, height: size)

                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.22, height: size * 0.22)
                    .foregroundColor(connectionState == nil ? .white :
                                   connectionState == .connected ? .white :
                                   connectionState == .connecting ? .yellow : .red)
                    .animation(.easeInOut(duration: 0.3), value: connectionState)
            }
        }
    }
}

struct LedButton: View {
    let led: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(isSelected ? Color.white : Color.clear)
                .background(
                    Circle().stroke(
                        Color(.white), lineWidth: 2)
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
    }
}

#Preview {
    ContentView()
}
