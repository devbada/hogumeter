//
//  TemplateSelectionView.swift
//  HoguMeter
//
//  Template selection UI for receipt customization.
//

import SwiftUI

/// 영수증 템플릿 선택 뷰
struct TemplateSelectionView: View {
    @Binding var selectedTemplate: ReceiptTemplate
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(ReceiptTemplate.allCases, id: \.self) { template in
                    TemplateRow(
                        template: template,
                        isSelected: selectedTemplate == template
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTemplate = template
                    }
                }
            }
            .navigationTitle("템플릿 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// 템플릿 행 뷰
private struct TemplateRow: View {
    let template: ReceiptTemplate
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            // 템플릿 아이콘
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(template.previewColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: template.iconName)
                    .font(.title2)
                    .foregroundColor(template.previewColor)
            }

            // 템플릿 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(template.displayName)
                    .font(.headline)

                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 선택 표시
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .padding(.vertical, 8)
    }
}

/// 영수증 미리보기 시트에서 템플릿 선택 버튼
struct TemplatePickerButton: View {
    @Binding var selectedTemplate: ReceiptTemplate
    @State private var showTemplateSheet = false

    var body: some View {
        Button {
            showTemplateSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: template.iconName)
                Text(template.displayName)
            }
            .font(.subheadline)
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
        }
        .sheet(isPresented: $showTemplateSheet) {
            TemplateSelectionView(selectedTemplate: $selectedTemplate)
        }
    }

    private var template: ReceiptTemplate {
        selectedTemplate
    }
}

#Preview {
    @Previewable @State var selected: ReceiptTemplate = .classic
    TemplateSelectionView(selectedTemplate: $selected)
}
