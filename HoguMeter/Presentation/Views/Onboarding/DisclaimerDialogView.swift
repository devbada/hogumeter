//
//  DisclaimerDialogView.swift
//  HoguMeter
//
//  Created on 2025-12-11.
//

import SwiftUI

struct DisclaimerDialogView: View {

    @StateObject private var viewModel = DisclaimerViewModel()
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // 배경 딤 처리
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            // 다이얼로그 카드
            VStack(spacing: 20) {
                // 헤더
                headerSection

                // 경고 내용
                warningSection

                // 재미 노트
                funNoteSection

                // 체크박스
                checkboxSection

                // 버튼
                confirmButton
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 24)
        }
        .interactiveDismissDisabled(true) // 스와이프로 닫기 방지
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("🐴 호구미터 🐴")
                .font(.title2)
                .fontWeight(.bold)

            Text(DisclaimerText.title)
                .font(.headline)
                .foregroundColor(.orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private var warningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(DisclaimerText.intro)
                .font(.body)
                .multilineTextAlignment(.center)

            Divider()

            Text("📌 반드시 알아두세요!")
                .font(.subheadline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(DisclaimerText.warnings, id: \.self) { warning in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text(warning)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }

    private var funNoteSection: some View {
        VStack {
            Divider()

            Text(DisclaimerText.funNote)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private var checkboxSection: some View {
        Button(action: {
            viewModel.isAgreed.toggle()
        }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: viewModel.isAgreed ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(viewModel.isAgreed ? .blue : .gray)

                Text(DisclaimerText.checkboxLabel)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var confirmButton: some View {
        Button(action: {
            viewModel.acceptDisclaimer()
            isPresented = false
        }) {
            Text(DisclaimerText.buttonTitle)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isAgreed ? Color.blue : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!viewModel.isAgreed)
    }
}

#Preview {
    DisclaimerDialogView(isPresented: .constant(true))
}
