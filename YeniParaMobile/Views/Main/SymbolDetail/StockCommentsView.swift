import SwiftUI

struct StockCommentsView: View {
    let symbol: String
    @StateObject private var viewModel = StockCommentsViewModel()
    @State private var showingAddComment = false
    @State private var selectedSortType: CommentSortType = .latest
    @State private var replyToComment: StockComment? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with sort options
            VStack(spacing: 16) {
                HStack {
                    Text("Yorumlar")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    // Sort picker
                    Menu {
                        Button(action: {
                            selectedSortType = .latest
                            Task {
                                await viewModel.loadComments(symbol: symbol, sort: selectedSortType)
                            }
                        }) {
                            Label("En Yeni", systemImage: "clock")
                        }
                        
                        Button(action: {
                            selectedSortType = .popular
                            Task {
                                await viewModel.loadComments(symbol: symbol, sort: selectedSortType)
                            }
                        }) {
                            Label("En Popüler", systemImage: "star")
                        }
                        
                        Button(action: {
                            selectedSortType = .oldest
                            Task {
                                await viewModel.loadComments(symbol: symbol, sort: selectedSortType)
                            }
                        }) {
                            Label("En Eski", systemImage: "clock.arrow.circlepath")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(sortTypeText(selectedSortType))
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.cardBackground)
                        .cornerRadius(8)
                    }
                }
                
                // Add comment button
                Button(action: { showingAddComment = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Yorum Yap")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.primary)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
                .background(AppColors.cardBorder)
            
            // Comments list
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 40)
            } else if viewModel.comments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text("Henüz yorum yok")
                        .font(.headline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("İlk yorumu sen yap!")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 60)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.comments) { comment in
                            CommentRowView(
                                comment: comment,
                                onVote: { voteType in
                                    Task {
                                        await viewModel.voteComment(commentId: comment.id, voteType: voteType)
                                    }
                                },
                                onReply: {
                                    replyToComment = comment
                                    showingAddComment = true
                                }
                            )
                            
                            if comment.id != viewModel.comments.last?.id {
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadComments(symbol: symbol, sort: selectedSortType)
            }
        }
        .sheet(isPresented: $showingAddComment) {
            AddCommentView(
                symbol: symbol,
                replyTo: replyToComment,
                onCommentAdded: { newComment in
                    // Add new comment and refresh
                    viewModel.comments.insert(newComment, at: 0)
                    replyToComment = nil
                    
                    // Refresh comments to get updated data
                    Task {
                        await viewModel.loadComments(symbol: symbol, sort: selectedSortType)
                    }
                }
            )
        }
    }
    
    private func sortTypeText(_ type: CommentSortType) -> String {
        switch type {
        case .latest:
            return "En Yeni"
        case .popular:
            return "En Popüler"
        case .oldest:
            return "En Eski"
        }
    }
}

// MARK: - Comment Row View
struct CommentRowView: View {
    let comment: StockComment
    let onVote: (VoteType) -> Void
    let onReply: () -> Void
    @State private var currentVote: VoteType = .none
    @State private var showingPublicProfile = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User info and timestamp
            HStack {
                // User avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(comment.user.username.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Button(action: {
                            print("DEBUG: Comment username clicked: '\(comment.user.username)'")
                            showingPublicProfile = true
                        }) {
                            Text("@\(comment.user.username)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.primary)
                                .underline()
                        }
                        
                        if comment.isAnalysis {
                            Label("Analiz", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.caption)
                                .foregroundColor(AppColors.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppColors.primary.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(TimeFormatter.formatTimeAgo(comment.createdAt))
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                // Sentiment indicator
                SentimentBadge(sentiment: comment.sentiment)
            }
            
            // Comment content
            Text(comment.content)
                .font(.subheadline)
                .foregroundColor(AppColors.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            // Actions
            HStack(spacing: 20) {
                // Like button
                Button(action: {
                    let newVote: VoteType = currentVote == .like ? .none : .like
                    currentVote = newVote
                    onVote(newVote)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: currentVote == .like ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 14))
                        Text("\(comment.likeCount)")
                            .font(.caption)
                    }
                    .foregroundColor(currentVote == .like ? AppColors.primary : AppColors.textSecondary)
                }
                
                // Dislike button
                Button(action: {
                    let newVote: VoteType = currentVote == .dislike ? .none : .dislike
                    currentVote = newVote
                    onVote(newVote)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: currentVote == .dislike ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.system(size: 14))
                        Text("\(comment.dislikeCount)")
                            .font(.caption)
                    }
                    .foregroundColor(currentVote == .dislike ? AppColors.error : AppColors.textSecondary)
                }
                
                // Reply button
                Button(action: onReply) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 14))
                        Text("Yanıtla")
                            .font(.caption)
                        if comment.replyCount > 0 {
                            Text("(\(comment.replyCount))")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Share button
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .onAppear {
            currentVote = comment.userVote ?? .none
        }
        .sheet(isPresented: $showingPublicProfile) {
            PublicProfileView(username: comment.user.username)
        }
    }
}

// MARK: - Sentiment Badge
struct SentimentBadge: View {
    let sentiment: CommentSentiment
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: sentiment.icon)
                .font(.system(size: 12))
            Text(sentiment.title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(sentimentColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(sentimentColor.opacity(0.15))
        .cornerRadius(6)
    }
    
    private var sentimentColor: Color {
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

// MARK: - ViewModel
@MainActor
class StockCommentsViewModel: ObservableObject {
    @Published var comments: [StockComment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var hasMorePages = true
    
    private let apiService = APIService.shared
    
    func loadComments(symbol: String, sort: CommentSortType, page: Int = 1) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("DEBUG: Loading comments for symbol: \(symbol)")
            let response = try await apiService.getStockComments(
                symbol: symbol,
                page: page,
                limit: 20,
                sort: sort.rawValue
            )
            print("DEBUG: Comments response success: \(response.success), count: \(response.data.comments.count)")
            
            if response.success {
                if page == 1 {
                    comments = response.data.comments
                } else {
                    comments.append(contentsOf: response.data.comments)
                }
                currentPage = page
                hasMorePages = response.data.comments.count == 20
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func voteComment(commentId: Int, voteType: VoteType) async {
        do {
            let response = try await apiService.voteComment(commentId: commentId, voteType: voteType)
            
            if response.success {
                // Update the comment in the list
                if let index = comments.firstIndex(where: { $0.id == commentId }) {
                    var updatedComment = comments[index]
                    // Create a mutable copy with updated values
                    comments[index] = StockComment(
                        id: updatedComment.id,
                        symbolCode: updatedComment.symbolCode,
                        userId: updatedComment.userId,
                        parentId: updatedComment.parentId,
                        content: updatedComment.content,
                        sentiment: updatedComment.sentiment,
                        likeCount: response.data.likeCount,
                        dislikeCount: response.data.dislikeCount,
                        replyCount: updatedComment.replyCount,
                        score: response.data.score,
                        isAnalysis: updatedComment.isAnalysis,
                        isActive: updatedComment.isActive,
                        createdAt: updatedComment.createdAt,
                        updatedAt: updatedComment.updatedAt,
                        user: updatedComment.user,
                        userVote: voteType
                    )
                }
            }
        } catch {
            print("Vote error: \(error)")
        }
    }
}