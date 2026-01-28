//
//  KakaoShareService.swift
//  HoguMeter
//
//  Kakao SDK native sharing with friend/chat picker.
//
//  ========================================
//  Kakao SDK 네이티브 공유 활성화 방법:
//  ========================================
//  1. Xcode에서: File > Add Package Dependencies
//  2. URL 입력: https://github.com/kakao/kakao-ios-sdk
//  3. "KakaoSDKCommon"과 "KakaoSDKShare" 선택 후 Add
//  4. 이 파일에서 TODO 주석 부분 수정
//  ========================================
//

import UIKit

// TODO: Kakao SDK 추가 후 아래 주석 해제
// import KakaoSDKCommon
// import KakaoSDKShare

// MARK: - Kakao Share Service

final class KakaoShareService {
    static let shared = KakaoShareService()

    private init() {}

    /// Initialize Kakao SDK - call this in app launch
    static func initializeSDK() {
        guard let appKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_APP_KEY") as? String,
              !appKey.isEmpty,
              !appKey.hasPrefix("$(") else {
            print("[KakaoShareService] Warning: KAKAO_APP_KEY not configured")
            return
        }

        // TODO: Kakao SDK 추가 후 아래 주석 해제
        // KakaoSDK.initSDK(appKey: appKey)
        print("[KakaoShareService] Ready with app key (SDK integration pending)")
    }

    /// Check if KakaoTalk is installed
    var isKakaoTalkAvailable: Bool {
        // TODO: Kakao SDK 추가 후 아래 코드로 변경
        // return ShareApi.isKakaoTalkSharingAvailable()

        guard let url = URL(string: "kakaolink://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Share receipt image using Kakao's native share picker
    func shareReceipt(
        image: UIImage,
        tripSummary: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard isKakaoTalkAvailable else {
            completion(.failure(KakaoShareError.kakaoTalkNotInstalled))
            return
        }

        // TODO: Kakao SDK 추가 후 shareWithKakaoSDK() 호출로 변경
        // shareWithKakaoSDK(image: image, tripSummary: tripSummary, completion: completion)

        // Fallback: 카카오톡 앱 직접 열기
        shareWithFallback(completion: completion)
    }

    // MARK: - Kakao SDK Share (SDK 추가 후 활성화)

    /*
    private func shareWithKakaoSDK(
        image: UIImage,
        tripSummary: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // 이미지를 카카오 서버에 업로드
        ShareApi.shared.imageUpload(image: image) { [weak self] imageUploadResult, error in
            if let error = error {
                print("[KakaoShareService] Image upload failed: \(error)")
                completion(.failure(error))
                return
            }

            guard let imageUrl = imageUploadResult?.infos?.original?.url else {
                completion(.failure(KakaoShareError.imageUploadFailed))
                return
            }

            print("[KakaoShareService] Image uploaded: \(imageUrl)")
            self?.shareWithFeedTemplate(imageUrl: imageUrl, summary: tripSummary, completion: completion)
        }
    }

    private func shareWithFeedTemplate(
        imageUrl: String,
        summary: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let content = Content(
            title: "호구미터 영수증",
            imageUrl: URL(string: imageUrl)!,
            description: summary,
            link: Link(
                webUrl: URL(string: "https://hogumeter.app"),
                mobileWebUrl: URL(string: "https://hogumeter.app")
            )
        )

        let feedTemplate = FeedTemplate(
            content: content,
            buttons: [
                Button(
                    title: "앱 열기",
                    link: Link(
                        iosExecutionParams: ["action": "receipt"]
                    )
                )
            ]
        )

        // 네이티브 공유 피커 (친구/채팅방 선택)
        ShareApi.shared.shareDefault(templatable: feedTemplate) { sharingResult, error in
            if let error = error {
                print("[KakaoShareService] Share failed: \(error)")
                completion(.failure(error))
                return
            }

            guard let sharingResult = sharingResult else {
                completion(.failure(KakaoShareError.shareFailed))
                return
            }

            UIApplication.shared.open(sharingResult.url, options: [:]) { success in
                if success {
                    print("[KakaoShareService] Share dialog opened")
                    completion(.success(()))
                } else {
                    completion(.failure(KakaoShareError.shareFailed))
                }
            }
        }
    }
    */

    // MARK: - Fallback (SDK 없이 동작)

    private func shareWithFallback(completion: @escaping (Result<Void, Error>) -> Void) {
        // 카카오톡 앱 직접 열기
        if let url = URL(string: "kakaotalk://") {
            UIApplication.shared.open(url) { success in
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(KakaoShareError.kakaoTalkNotInstalled))
                }
            }
        } else {
            completion(.failure(KakaoShareError.kakaoTalkNotInstalled))
        }
    }

    /// Handle URL callback from Kakao
    static func handleOpenUrl(_ url: URL) -> Bool {
        if url.scheme?.hasPrefix("kakao") == true {
            print("[KakaoShareService] Handling Kakao URL callback")
            return true
        }
        return false
    }
}

// MARK: - Kakao Share Error

enum KakaoShareError: Error, LocalizedError {
    case kakaoTalkNotInstalled
    case imageConversionFailed
    case imageUploadFailed
    case shareFailed
    case sdkNotInitialized

    var errorDescription: String? {
        switch self {
        case .kakaoTalkNotInstalled:
            return "카카오톡이 설치되어 있지 않아요."
        case .imageConversionFailed:
            return "이미지 변환에 실패했어요."
        case .imageUploadFailed:
            return "이미지 업로드에 실패했어요."
        case .shareFailed:
            return "공유에 실패했어요."
        case .sdkNotInitialized:
            return "카카오 SDK가 초기화되지 않았어요."
        }
    }
}
