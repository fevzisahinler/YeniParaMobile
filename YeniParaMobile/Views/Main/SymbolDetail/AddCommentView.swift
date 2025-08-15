import SwiftUI

struct AddCommentView: View {
    let symbol: String
    let replyTo: StockComment?
    let onCommentAdded: (StockComment) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @State private var selectedSentiment: CommentSentiment = .neutral
    @State private var isAnalysis = false
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let maxCharacters = 500
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    Divider()
                        .background(AppColors.cardBorder)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            if replyTo != nil {
                                replyContextView
                            }
                            
                            commentInputView
                            
                            sentimentSelectorView
                            
                            analysisToggleView
                            
                            guidelinesView
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button("İptal") {
                dismiss()
            }
            .font(.system(size: 16))
            .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Text(replyTo != nil ? "Yanıtla" : "Yorum Yap")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            submitButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var submitButton: some View {
        Button(action: submitComment) {
            if isSubmitting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                    .scaleEffect(0.8)
            } else {
                Text("Gönder")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(commentText.isEmpty ? AppColors.textTertiary : AppColors.primary)
            }
        }
        .disabled(commentText.isEmpty || isSubmitting)
    }
    
    // MARK: - Reply Context View
    private var replyContextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text("@\(replyTo?.user.username ?? "") kullanıcısına yanıt")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Text(replyTo?.content ?? "")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
                .lineLimit(2)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .cornerRadius(8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Comment Input View
    private var commentInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            commentTextEditor
            
            HStack {
                Spacer()
                Text("\(commentText.count)/\(maxCharacters)")
                    .font(.caption)
                    .foregroundColor(characterCountColor)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var commentTextEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $commentText)
                .font(.body)
                .foregroundColor(AppColors.textPrimary)
                .padding(4)
                .background(Color.clear)
                .frame(minHeight: 120, maxHeight: 200)
                .onChange(of: commentText) { oldValue, newValue in
                    if newValue.count > maxCharacters {
                        commentText = String(newValue.prefix(maxCharacters))
                    }
                }
            
            if commentText.isEmpty {
                Text("Hisse hakkındaki düşüncelerinizi paylaşın...")
                    .font(.body)
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }
        }
        .padding(12)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }
    
    private var characterCountColor: Color {
        commentText.count > maxCharacters * Int(0.9) ? AppColors.warning : AppColors.textTertiary
    }
    
    // MARK: - Sentiment Selector View
    private var sentimentSelectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Görüşünüz")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 12) {
                ForEach(CommentSentiment.allCases, id: \.self) { sentiment in
                    SentimentButton(
                        sentiment: sentiment,
                        isSelected: selectedSentiment == sentiment
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSentiment = sentiment
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Analysis Toggle View
    private var analysisToggleView: some View {
        VStack(spacing: 16) {
            Toggle(isOn: $isAnalysis) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Teknik Analiz")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Bu yorum teknik analiz içeriyor")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .tint(AppColors.primary)
            
            if isAnalysis {
                analysisInfoBox
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var analysisInfoBox: some View {
        HStack {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundColor(AppColors.primary)
            
            Text("Teknik analiz olarak işaretlenen yorumlar özel olarak vurgulanır")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(AppColors.primary.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Guidelines View
    private var guidelinesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Topluluk Kuralları")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textSecondary)
            
            VStack(alignment: .leading, spacing: 6) {
                GuidelineRow(text: "Saygılı ve yapıcı yorumlar yapın")
                GuidelineRow(text: "Yanıltıcı bilgi paylaşmayın")
                GuidelineRow(text: "Yatırım tavsiyesi vermekten kaçının")
                GuidelineRow(text: "Spam ve tekrarlayan içerik paylaşmayın")
            }
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Submit Comment
    private func submitComment() {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Lütfen bir yorum girin"
            showError = true
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                let response = try await APIService.shared.createStockComment(
                    symbol: symbol,
                    content: commentText,
                    sentiment: selectedSentiment,
                    isAnalysis: isAnalysis,
                    parentId: replyTo?.id
                )
                
                if response.success {
                    await MainActor.run {
                        onCommentAdded(response.data)
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Sentiment Button
struct SentimentButton: View {
    let sentiment: CommentSentiment
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: sentiment.icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                
                Text(sentiment.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundView)
            .overlay(overlayView)
        }
    }
    
    private var iconColor: Color {
        isSelected ? buttonColor : AppColors.textTertiary
    }
    
    private var textColor: Color {
        isSelected ? buttonColor : AppColors.textTertiary
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? buttonColor.opacity(0.15) : AppColors.cardBackground)
    }
    
    private var overlayView: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                isSelected ? buttonColor : AppColors.cardBorder,
                lineWidth: isSelected ? 2 : 1
            )
    }
    
    private var buttonColor: Color {
        switch sentiment {
        case .bullish:
            return AppColors.primary
        case .bearish:
            return AppColors.error
        case .neutral:
            return AppColors.textSecondary
        }
    }
}

// MARK: - Guideline Row
struct GuidelineRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(AppColors.primary)
            
            Text(text)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
        }
    }
}
