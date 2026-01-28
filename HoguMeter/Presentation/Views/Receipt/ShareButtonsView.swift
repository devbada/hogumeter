//
//  ShareButtonsView.swift
//  HoguMeter
//
//  Share buttons grid for direct SNS sharing.
//

import SwiftUI

struct ShareButtonsView: View {
    let image: UIImage
    let onDismiss: (() -> Void)?

    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSharing = false
    @State private var sharingDestination: ShareDestination?

    private let shareService = ReceiptShareService.shared

    init(image: UIImage, onDismiss: (() -> Void)? = nil) {
        self.image = image
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("공유하기")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            // First row: SNS
            HStack(spacing: 24) {
                ShareButton(
                    destination: .kakaoTalk,
                    isLoading: sharingDestination == .kakaoTalk && isSharing,
                    action: { share(to: .kakaoTalk) }
                )

                ShareButton(
                    destination: .instagram,
                    isLoading: sharingDestination == .instagram && isSharing,
                    action: { share(to: .instagram) }
                )

                ShareButton(
                    destination: .iMessage,
                    isLoading: sharingDestination == .iMessage && isSharing,
                    action: { share(to: .iMessage) }
                )
            }

            // Second row: Utilities
            HStack(spacing: 24) {
                ShareButton(
                    destination: .saveToPhotos,
                    isLoading: sharingDestination == .saveToPhotos && isSharing,
                    action: { share(to: .saveToPhotos) }
                )

                ShareButton(
                    destination: .copyImage,
                    isLoading: sharingDestination == .copyImage && isSharing,
                    action: { share(to: .copyImage) }
                )

                ShareButton(
                    destination: .more,
                    isLoading: sharingDestination == .more && isSharing,
                    action: { share(to: .more) }
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        .disabled(isSharing)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func share(to destination: ShareDestination) {
        // Check availability first
        guard destination.isAvailable else {
            showUnavailableAlert(for: destination)
            return
        }

        isSharing = true
        sharingDestination = destination

        // Get the current view controller for presentation
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            isSharing = false
            sharingDestination = nil
            return
        }

        // Find the topmost presented view controller
        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }

        shareService.share(image: image, to: destination, from: topVC) { result in
            DispatchQueue.main.async {
                isSharing = false
                sharingDestination = nil

                switch result {
                case .success:
                    handleSuccess(for: destination)
                case .failure(let error):
                    handleError(error, for: destination)
                }
            }
        }
    }

    private func showUnavailableAlert(for destination: ShareDestination) {
        switch destination {
        case .kakaoTalk:
            alertTitle = "카카오톡"
            alertMessage = "카카오톡이 설치되어 있지 않아요."
        case .instagram:
            alertTitle = "인스타그램"
            alertMessage = "인스타그램이 설치되어 있지 않아요."
        case .iMessage:
            alertTitle = "메시지"
            alertMessage = "메시지 기능을 사용할 수 없어요."
        default:
            alertTitle = "알림"
            alertMessage = "해당 기능을 사용할 수 없어요."
        }
        showAlert = true
    }

    private func handleSuccess(for destination: ShareDestination) {
        switch destination {
        case .saveToPhotos:
            alertTitle = "저장 완료"
            alertMessage = "사진첩에 저장되었어요! 📸"
            showAlert = true
        case .copyImage:
            alertTitle = "복사 완료"
            alertMessage = "클립보드에 복사되었어요! 📋"
            showAlert = true
        default:
            break
        }
    }

    private func handleError(_ error: ShareError, for destination: ShareDestination) {
        guard case .cancelled = error else {
            alertTitle = "오류"
            alertMessage = error.errorDescription ?? "알 수 없는 오류가 발생했어요."
            showAlert = true
            return
        }
        // Don't show alert for cancelled
    }
}

// MARK: - Share Button

struct ShareButton: View {
    let destination: ShareDestination
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(destination.backgroundColor)
                        .frame(width: 56, height: 56)

                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: destination.iconColor))
                    } else {
                        Image(systemName: destination.icon)
                            .font(.system(size: 24))
                            .foregroundColor(destination.iconColor)
                    }
                }
                .opacity(destination.isAvailable ? 1.0 : 0.4)

                Text(destination.title)
                    .font(.caption)
                    .foregroundColor(destination.isAvailable ? .primary : .secondary)
            }
        }
        .disabled(!destination.isAvailable || isLoading)
    }
}

// MARK: - ShareDestination UI Extensions

extension ShareDestination {
    var backgroundColor: Color {
        switch self {
        case .kakaoTalk:
            return Color(red: 254/255, green: 229/255, blue: 0/255) // Kakao Yellow
        case .instagram:
            return Color(red: 225/255, green: 48/255, blue: 108/255) // Instagram Pink
        case .iMessage:
            return .green
        case .saveToPhotos:
            return .blue
        case .copyImage:
            return .orange
        case .more:
            return Color(.systemGray4)
        }
    }

    var iconColor: Color {
        switch self {
        case .kakaoTalk:
            return .black
        case .more:
            return .primary
        default:
            return .white
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        ShareButtonsView(
            image: UIImage(systemName: "doc.text")!,
            onDismiss: nil
        )
    }
    .background(Color(.systemGray6))
}
