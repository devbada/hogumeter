//
//  ReceiptShareService.swift
//  HoguMeter
//
//  Centralized service for sharing receipt images to various platforms.
//

import UIKit
import Photos
import MessageUI

// MARK: - Share Destination

enum ShareDestination: CaseIterable {
    case kakaoTalk
    case instagram
    case iMessage
    case saveToPhotos
    case copyImage
    case more

    var title: String {
        switch self {
        case .kakaoTalk: return "카카오톡"
        case .instagram: return "인스타그램"
        case .iMessage: return "메시지"
        case .saveToPhotos: return "저장"
        case .copyImage: return "복사"
        case .more: return "더보기"
        }
    }

    var icon: String {
        switch self {
        case .kakaoTalk: return "message.fill"
        case .instagram: return "camera.fill"
        case .iMessage: return "bubble.left.fill"
        case .saveToPhotos: return "square.and.arrow.down"
        case .copyImage: return "doc.on.doc"
        case .more: return "ellipsis"
        }
    }

    var isAvailable: Bool {
        switch self {
        case .kakaoTalk:
            return true // 시스템 공유 시트 사용
        case .instagram:
            guard let url = URL(string: "instagram://") else { return false }
            return UIApplication.shared.canOpenURL(url)
        case .iMessage:
            return MFMessageComposeViewController.canSendText()
        default:
            return true
        }
    }
}

// MARK: - Share Error

enum ShareError: Error, LocalizedError {
    case appNotInstalled
    case permissionDenied
    case failed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .appNotInstalled:
            return "앱이 설치되어 있지 않아요."
        case .permissionDenied:
            return "권한이 필요해요. 설정에서 허용해 주세요."
        case .failed(let message):
            return message
        case .cancelled:
            return nil
        }
    }
}

// MARK: - Receipt Share Service

final class ReceiptShareService: NSObject {
    static let shared = ReceiptShareService()

    private var messageCompletion: ((Result<Void, ShareError>) -> Void)?
    private weak var presentingViewController: UIViewController?

    private override init() {
        super.init()
    }

    /// 영수증 이미지를 지정한 채널로 공유한다.
    /// - Parameters:
    ///   - image: 공유할 영수증 이미지
    ///   - destination: 공유 채널
    ///   - fare: 공유 본문에 노출할 요금(원). nil이면 본문 텍스트를 첨부하지 않는다.
    ///   - viewController: present에 사용할 뷰컨트롤러
    ///   - completion: 결과 콜백
    func share(
        image: UIImage,
        to destination: ShareDestination,
        fare: Int? = nil,
        from viewController: UIViewController,
        completion: @escaping (Result<Void, ShareError>) -> Void
    ) {
        self.presentingViewController = viewController

        // 채널별로 본문 텍스트 노출 여부가 다르므로 빌더에 위임한다.
        let shareText = buildShareText(for: destination, fare: fare)

        switch destination {
        case .kakaoTalk:
            showShareSheet(image: image, text: shareText, from: viewController, completion: completion)
        case .instagram:
            // 인스타그램 스토리는 스티커 방식이라 텍스트가 전달되지 않음. 이미지만 공유.
            shareToInstagram(image: image, completion: completion)
        case .iMessage:
            shareToiMessage(image: image, text: shareText, from: viewController, completion: completion)
        case .saveToPhotos:
            saveToPhotos(image: image, completion: completion)
        case .copyImage:
            copyToClipboard(image: image, completion: completion)
        case .more:
            showShareSheet(image: image, text: shareText, from: viewController, completion: completion)
        }
    }

    // MARK: - Share Text Builder

    /// 채널별로 공유 본문 텍스트를 빌드한다.
    /// - 인스타그램/사진저장/복사 채널은 텍스트가 전달되지 않으므로 nil 반환.
    /// - fare가 nil인 경우에도 nil 반환(요금 없는 공유는 단순 이미지로 처리).
    /// internal 가시성: 단위 테스트에서 호출 가능하도록 함.
    func buildShareText(for destination: ShareDestination, fare: Int?) -> String? {
        guard let fare = fare else { return nil }

        switch destination {
        case .instagram, .saveToPhotos, .copyImage:
            // 텍스트가 전달되지 않거나 의미가 없는 채널
            return nil
        case .kakaoTalk, .iMessage, .more:
            let formattedFare = fare.formattedWithComma
            return Constants.Share.shareCaptionTemplate
                .replacingOccurrences(of: "{fare}", with: formattedFare)
        }
    }

    // MARK: - Instagram Stories Sharing

    private func shareToInstagram(
        image: UIImage,
        completion: @escaping (Result<Void, ShareError>) -> Void
    ) {
        guard let instagramURL = URL(string: "instagram://"),
              UIApplication.shared.canOpenURL(instagramURL) else {
            completion(.failure(.appNotInstalled))
            return
        }

        guard let imageData = image.pngData() else {
            completion(.failure(.failed("이미지 변환 실패")))
            return
        }

        let pasteboardItems: [String: Any] = [
            "com.instagram.sharedSticker.backgroundImage": imageData
        ]

        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(300) // 5 minutes
        ]

        UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)

        // Get bundle identifier
        let bundleId = Bundle.main.bundleIdentifier ?? "com.hogumeter.app"

        if let url = URL(string: "instagram-stories://share?source_application=\(bundleId)") {
            UIApplication.shared.open(url) { success in
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(.failed("인스타그램 스토리 열기 실패")))
                }
            }
        } else {
            completion(.failure(.failed("인스타그램 URL 생성 실패")))
        }
    }

    // MARK: - iMessage Sharing

    private func shareToiMessage(
        image: UIImage,
        text: String?,
        from viewController: UIViewController,
        completion: @escaping (Result<Void, ShareError>) -> Void
    ) {
        guard MFMessageComposeViewController.canSendText() else {
            completion(.failure(.appNotInstalled))
            return
        }

        let messageVC = MFMessageComposeViewController()
        messageVC.messageComposeDelegate = self
        self.messageCompletion = completion

        if MFMessageComposeViewController.canSendAttachments() {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                messageVC.addAttachmentData(imageData, typeIdentifier: "public.jpeg", filename: "호구미터_영수증.jpg")
            }
        }

        // 본문에 자랑용 멘트 + 앱스토어 링크가 포함된다.
        // 텍스트가 없으면 기존 짧은 멘트로 폴백.
        messageVC.body = text ?? "🐴 호구미터 영수증"

        viewController.present(messageVC, animated: true)
    }

    // MARK: - Save to Photos

    private func saveToPhotos(
        image: UIImage,
        completion: @escaping (Result<Void, ShareError>) -> Void
    ) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    completion(.success(()))
                case .denied, .restricted:
                    completion(.failure(.permissionDenied))
                default:
                    completion(.failure(.failed("사진 저장 권한이 필요해요.")))
                }
            }
        }
    }

    // MARK: - Copy to Clipboard

    private func copyToClipboard(
        image: UIImage,
        completion: @escaping (Result<Void, ShareError>) -> Void
    ) {
        UIPasteboard.general.image = image
        completion(.success(()))
    }

    // MARK: - iOS Share Sheet

    private func showShareSheet(
        image: UIImage,
        text: String?,
        from viewController: UIViewController,
        completion: @escaping (Result<Void, ShareError>) -> Void
    ) {
        // 시스템 시트는 [이미지, 텍스트] 순으로 넘기면 채널에 따라 자동으로 적절히 사용한다.
        // 텍스트가 nil이면 이미지만 공유.
        var activityItems: [Any] = [image]
        if let text = text {
            activityItems.append(text)
        }

        let activityVC = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        // For iPad
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }

        activityVC.completionWithItemsHandler = { _, completed, _, error in
            if let error = error {
                completion(.failure(.failed(error.localizedDescription)))
            } else if completed {
                completion(.success(()))
            } else {
                completion(.failure(.cancelled))
            }
        }

        viewController.present(activityVC, animated: true)
    }
}

// MARK: - MFMessageComposeViewControllerDelegate

extension ReceiptShareService: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(
        _ controller: MFMessageComposeViewController,
        didFinishWith result: MessageComposeResult
    ) {
        controller.dismiss(animated: true) { [weak self] in
            switch result {
            case .sent:
                self?.messageCompletion?(.success(()))
            case .cancelled:
                self?.messageCompletion?(.failure(.cancelled))
            case .failed:
                self?.messageCompletion?(.failure(.failed("메시지 전송 실패")))
            @unknown default:
                self?.messageCompletion?(.failure(.failed("알 수 없는 오류")))
            }
            self?.messageCompletion = nil
        }
    }
}
