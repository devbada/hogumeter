//
//  AppInfoView.swift
//  HoguMeter
//
//  Created on 2025-12-11.
//

import SwiftUI

struct AppInfoView: View {

    @StateObject private var viewModel = DisclaimerViewModel()
    @State private var showResetAlert = false

    var body: some View {
        List {
            // 앱 헤더
            appHeaderSection

            // 앱 소개
            appDescriptionSection

            // 면책 조항
            disclaimerSection

            // 개발자 정보
            developerSection

            // 면책 동의 초기화
            resetSection
        }
        .navigationTitle("앱 정보")
        .navigationBarTitleDisplayMode(.inline)
        .alert("면책 동의 초기화", isPresented: $showResetAlert) {
            Button("취소", role: .cancel) {}
            Button("초기화", role: .destructive) {
                viewModel.resetDisclaimer()
            }
        } message: {
            Text("면책 동의를 초기화하면 앱을 재시작할 때 다시 동의 화면이 표시됩니다.")
        }
    }

    // MARK: - Sections

    private var appHeaderSection: some View {
        Section {
            VStack(spacing: 12) {
                Text("🐴 호구미터")
                    .font(.title)
                    .fontWeight(.bold)

                Text("\"내 차 탔으면 내놔\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("버전 \(version) (\(build))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .listRowBackground(Color.clear)
    }

    private var appDescriptionSection: some View {
        Section {
            Text(DisclaimerText.appDescription)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 8)
        } header: {
            Label("앱 소개", systemImage: "book")
                .font(.headline)
        }
    }

    private var disclaimerSection: some View {
        Section {
            Text(DisclaimerText.disclaimer)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 8)
        } header: {
            Label("면책 조항", systemImage: "exclamationmark.triangle")
                .font(.headline)
        }
    }

    private var developerSection: some View {
        Section {
            Button {
                openEmail()
            } label: {
                HStack {
                    Text("문의하기")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Button {
                openAppStore()
            } label: {
                HStack {
                    Text("앱 리뷰 남기기")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            NavigationLink {
                LicenseView()
            } label: {
                Text("오픈소스 라이선스")
            }
        } header: {
            Label("개발자 정보", systemImage: "person")
                .font(.headline)
        }
    }

    private var resetSection: some View {
        Section {
            Button {
                showResetAlert = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("면책 동의 초기화")
                            .fontWeight(.medium)
                        Text("(다이얼로그 다시 보기)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.red)
            }
        }
    }

    // MARK: - Actions

    private func openEmail() {
        let email = "imdevbada@gmail.com"
        let subject = "호구미터 문의"
        let body = """


        ---
        앱 버전: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
        iOS 버전: \(UIDevice.current.systemVersion)
        기기 모델: \(UIDevice.current.model)
        """

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)"

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func openAppStore() {
        if let url = URL(string: Constants.Share.appStoreReviewURL) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - License View

struct LicenseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("오픈소스 라이선스")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)

                Text("이 앱은 다음 오픈소스 라이브러리를 사용합니다:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 20) {
                    licenseItem(
                        name: "SwiftUI",
                        license: "Apple Inc.",
                        description: "iOS UI Framework"
                    )

                    // 추가 라이브러리가 있다면 여기에 추가
                }
            }
            .padding()
        }
        .navigationTitle("라이선스")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func licenseItem(name: String, license: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("License: \(license)")
                .font(.caption)
                .foregroundColor(.secondary)
            Divider()
        }
    }
}

#Preview {
    NavigationStack {
        AppInfoView()
    }
}
