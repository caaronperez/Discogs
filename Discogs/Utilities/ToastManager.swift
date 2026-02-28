//
//  ToastManager.swift
//  Discogs
//
//  Created by Cristian Perez on 2/27/26.
//

import Combine
import SwiftUI

// Visual style for toast notifications - User-friendly
enum ToastStyle {
    case info
    case success
    case error

    var tint: Color {
        switch self {
        case .info:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }
}

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let style: ToastStyle
}

@MainActor
final class ToastManager: ObservableObject {
    @Published private(set) var currentToast: ToastMessage?

    func show(
        title: String,
        message: String,
        style: ToastStyle = .info,
        duration: Duration = .seconds(2)
    ) {
        currentToast = ToastMessage(title: title, message: message, style: style)

        Task {
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            if self.currentToast?.title == title, self.currentToast?.message == message {
                withAnimation(.easeInOut) {
                    self.currentToast = nil
                }
            }
        }
    }
}

struct ToastView: View {
    let toast: ToastMessage

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(toast.style.tint)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.headline)
                Text(toast.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
        .shadow(radius: 10)
    }
}

struct ToastOverlayModifier: ViewModifier {
    @ObservedObject var manager: ToastManager

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let toast = manager.currentToast {
                    ToastView(toast: toast)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 12)
                }
            }
            .animation(.spring(duration: 0.35), value: manager.currentToast)
    }
}

extension View {
    func toastOverlay(using manager: ToastManager) -> some View {
        modifier(ToastOverlayModifier(manager: manager))
    }
}
