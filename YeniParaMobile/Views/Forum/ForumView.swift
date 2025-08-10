import SwiftUI

struct ForumView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var selectedCategory: ForumCategory?
    @State private var categories: [ForumCategory] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var showCreateThread = false
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                        .scaleEffect(1.2)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            ForumHeaderView(searchText: $searchText, onCreateThread: {
                                showCreateThread = true
                            })
                            
                            // Featured Tags
                            FeaturedTagsSection()
                            
                            // Categories
                            ForEach(categories) { category in
                                CategorySection(category: category, authVM: authVM)
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.top, 20)
                    }
                }
            }
        .navigationBarHidden(true)
        .onAppear {
            loadCategories()
        }
        .sheet(isPresented: $showCreateThread) {
            CreateThreadView(authVM: authVM, categories: categories)
        }
    }
    
    private func loadCategories() {
        Task {
            do {
                guard let token = authVM.accessToken else {
                    print("No access token available")
                    self.isLoading = false
                    return
                }
                
                let fetchedCategories = try await ForumService.shared.getCategories(token: token)
                
                await MainActor.run {
                    self.categories = fetchedCategories
                    self.isLoading = false
                }
            } catch {
                print("Error loading categories: \(error)")
                await MainActor.run {
                    self.isLoading = false
                    // You might want to show an error alert here
                }
            }
        }
    }
}

// MARK: - Forum Header
struct ForumHeaderView: View {
    @Binding var searchText: String
    let onCreateThread: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Title and Create Button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Topluluk")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Yatırımcılarla tartış, fikir alışverişi yap")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Button(action: onCreateThread) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textTertiary)
                
                TextField("Konu ara...", text: $searchText)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(12)
            .background(AppColors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }
}

// MARK: - Featured Tags
struct FeaturedTagsSection: View {
    let tags = ["#UzunVadeciler", "#ETFYatırımcıları", "#TeknolojiHisseleri", "#YeniYatırımcılar"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popüler Etiketler")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, AppConstants.screenPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(title: tag, count: Int.random(in: 5...50))
                    }
                }
                .padding(.horizontal, AppConstants.screenPadding)
            }
        }
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppColors.primary)
            
            Text("\(count)")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppColors.primary.opacity(0.15))
                .cornerRadius(8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Category Section
struct CategorySection: View {
    let category: ForumCategory
    @ObservedObject var authVM: AuthViewModel
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category Header
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(category.description)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(.horizontal, AppConstants.screenPadding)
            }
            
            if isExpanded {
                // Topics in Category
                VStack(spacing: 1) {
                    ForEach(Array(category.topics.enumerated()), id: \.element.id) { index, topic in
                        NavigationLink(destination: TopicThreadsView(topic: topic, authVM: authVM)) {
                            TopicRow(topic: topic)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.7)
                            .delay(Double(index) * 0.03),
                            value: isExpanded
                        )
                    }
                }
                .background(AppColors.cardBackground)
                .cornerRadius(AppConstants.cornerRadius)
                .padding(.horizontal, AppConstants.screenPadding)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Topic Row
struct TopicRow: View {
    let topic: ForumTopic
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon only if it exists and is not empty
            if !topic.icon.isEmpty && topic.icon != "" {
                Text(topic.icon)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(topic.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 12) {
                    Label("\(topic.threadCount) konu", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Label("\(topic.postCount) mesaj", systemImage: "message")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.horizontal, AppConstants.screenPadding)
        .padding(.vertical, 12)
        .background(AppColors.cardBackground)
    }
}

// MARK: - Create Thread View
struct CreateThreadView: View {
    @ObservedObject var authVM: AuthViewModel
    let categories: [ForumCategory]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: ForumCategory?
    @State private var selectedTopic: ForumTopic?
    @State private var title = ""
    @State private var content = ""
    @State private var tags = ""
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Category Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kategori Seç")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Menu {
                                ForEach(categories) { category in
                                    Button(category.name) {
                                        selectedCategory = category
                                        selectedTopic = nil
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedCategory?.name ?? "Kategori seçin")
                                        .foregroundColor(selectedCategory != nil ? AppColors.textPrimary : AppColors.textSecondary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.cardBorder, lineWidth: 1)
                                )
                            }
                        }
                        
                        // Topic Selection
                        if let category = selectedCategory {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Konu Seç")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Menu {
                                    ForEach(category.topics) { topic in
                                        Button(topic.name) {
                                            selectedTopic = topic
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedTopic?.name ?? "Konu seçin")
                                            .foregroundColor(selectedTopic != nil ? AppColors.textPrimary : AppColors.textSecondary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    .padding()
                                    .background(AppColors.cardBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.cardBorder, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Başlık")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Konu başlığı...", text: $title)
                                .font(.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.cardBorder, lineWidth: 1)
                                )
                        }
                        
                        // Content
                        VStack(alignment: .leading, spacing: 8) {
                            Text("İçerik")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextEditor(text: $content)
                                .font(.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .frame(minHeight: 150)
                                .background(AppColors.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.cardBorder, lineWidth: 1)
                                )
                        }
                        
                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Etiketler")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Virgülle ayırın: BIST100, 2025, Analiz", text: $tags)
                                .font(.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.cardBorder, lineWidth: 1)
                                )
                        }
                    }
                    .padding(AppConstants.screenPadding)
                }
            }
            .navigationTitle("Yeni Konu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Paylaş") {
                        createThread()
                    }
                    .foregroundColor(AppColors.primary)
                    .fontWeight(.semibold)
                    .disabled(selectedTopic == nil || title.isEmpty || content.isEmpty)
                }
            }
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .disabled(isCreating)
        .overlay(
            Group {
                if isCreating {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView("Oluşturuluyor...")
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                        .padding()
                        .background(AppColors.cardBackground)
                        .cornerRadius(12)
                }
            }
        )
    }
    
    private func createThread() {
        guard let topic = selectedTopic,
              let token = authVM.accessToken else { return }
        
        isCreating = true
        
        Task {
            do {
                // Parse tags from comma-separated string
                let tagArray = tags.split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                
                _ = try await ForumService.shared.createThread(
                    topicId: topic.id,
                    title: title,
                    content: content,
                    tags: tagArray,
                    token: token
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = "Konu oluşturulamadı. Lütfen tekrar deneyin."
                    showError = true
                }
            }
        }
    }
}

// MARK: - Topic Threads View
struct TopicThreadsView: View {
    let topic: ForumTopic
    @ObservedObject var authVM: AuthViewModel
    @State private var threads: [ForumThread] = []
    @State private var isLoading = true
    @State private var showCreateThread = false
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            mainContent
            floatingActionButton
        }
        .navigationTitle(topic.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadThreads()
        }
        .sheet(isPresented: $showCreateThread) {
            CreateThreadViewForTopic(authVM: authVM, topic: topic) {
                loadThreads()
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if isLoading {
            loadingView
        } else if threads.isEmpty {
            emptyStateView
        } else {
            threadListView
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                .scaleEffect(1.2)
            
            Text("Konular yükleniyor...")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            emptyStateIcon
            emptyStateText
            createFirstThreadButton
            
            Spacer()
        }
        .padding()
    }
    
    private var emptyStateIcon: some View {
        ZStack {
            Circle()
                .fill(AppColors.primary.opacity(0.1))
                .frame(width: 120, height: 120)
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(AppColors.primary.opacity(0.6))
                .symbolEffect(.pulse, options: .repeating)
        }
    }
    
    private var emptyStateText: some View {
        VStack(spacing: 12) {
            Text("Henüz konu yok")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Bu konuda ilk tartışmayı başlat ve\ntoplulukla fikirlerini paylaş!")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var createFirstThreadButton: some View {
        Button(action: { showCreateThread = true }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.body)
                
                Text("İlk Konuyu Oluştur")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(AppColors.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppColors.primary.opacity(0.15))
            .cornerRadius(12)
        }
    }
    
    private var threadListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(threads) { thread in
                    NavigationLink(destination: ThreadDetailView(thread: thread, authVM: authVM)) {
                        ThreadCard(thread: thread)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, AppConstants.screenPadding)
            .padding(.bottom, 80)
        }
    }
    
    @ViewBuilder
    private var floatingActionButton: some View {
        if !threads.isEmpty {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: { showCreateThread = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Yeni Konu")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(AppColors.primary.opacity(0.9))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 90) // TabBar için boşluk
                }
            }
        }
    }
    
    private func loadThreads() {
        Task {
            do {
                guard let token = authVM.accessToken else {
                    print("No access token available")
                    await MainActor.run {
                        self.isLoading = false
                    }
                    return
                }
                
                let response = try await ForumService.shared.getThreadsByTopic(
                    topicId: topic.id,
                    token: token,
                    page: 1
                )
                
                await MainActor.run {
                    self.threads = response.data.threads
                    self.isLoading = false
                }
            } catch {
                print("Error loading threads: \(error)")
                await MainActor.run {
                    self.isLoading = false
                    // You might want to show an error alert here
                }
            }
        }
    }
}

// MARK: - Thread Card
struct ThreadCard: View {
    let thread: ForumThread
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            threadBadges
            threadTitle
            threadContent
            threadTags
            threadFooter
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.cardBorder, lineWidth: 0.5)
        )
    }
    
    @ViewBuilder
    private var threadBadges: some View {
        if thread.isPinned || thread.isFeatured {
            HStack {
                if thread.isPinned {
                    badgeView(title: "Sabitlenmiş", icon: "pin.fill", color: AppColors.warning)
                }
                if thread.isFeatured {
                    badgeView(title: "Öne Çıkan", icon: "star.fill", color: AppColors.success)
                }
                Spacer()
            }
        }
    }
    
    private func badgeView(title: String, icon: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption2)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }
    
    private var threadTitle: some View {
        Text(thread.title)
            .font(.headline)
            .foregroundColor(AppColors.textPrimary)
            .lineLimit(2)
    }
    
    private var threadContent: some View {
        Text(thread.content)
            .font(.subheadline)
            .foregroundColor(AppColors.textSecondary)
            .lineLimit(2)
    }
    
    @ViewBuilder
    private var threadTags: some View {
        if !thread.tagsArray.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(thread.tagsArray.prefix(3)), id: \.self) { tag in
                        tagChip(tag)
                    }
                }
            }
        }
    }
    
    private func tagChip(_ tag: String) -> some View {
        Text("#\(tag)")
            .font(.caption)
            .foregroundColor(AppColors.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(AppColors.primary.opacity(0.1))
            .cornerRadius(4)
    }
    
    private var threadFooter: some View {
        HStack {
            authorInfo
            Spacer()
            threadStats
        }
    }
    
    private var authorInfo: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AppColors.primary.opacity(0.2))
                .frame(width: 24, height: 24)
                .overlay(
                    Text(thread.authorName.prefix(1))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                )
            
            VStack(alignment: .leading, spacing: 0) {
                Text(thread.authorName)
                    .font(.caption)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(thread.formattedCreatedAt)
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }
    
    private var threadStats: some View {
        HStack(spacing: 10) {
            statItem(icon: "eye", count: thread.viewCount)
            statItem(icon: "message", count: thread.replyCount)
            statItem(icon: "hand.thumbsup", count: thread.likeCount)
        }
    }
    
    private func statItem(icon: String, count: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
            Text("\(count)")
                .font(.caption)
        }
        .foregroundColor(AppColors.textTertiary)
    }
}

// MARK: - Thread Detail View
struct ThreadDetailView: View {
    let thread: ForumThread
    @ObservedObject var authVM: AuthViewModel
    @State private var threadDetail: ForumThreadDetail?
    @State private var isLoading = true
    @State private var replyText = ""
    @State private var isSubmittingReply = false
    @State private var showReplyField = false
    @State private var replyingTo: ForumReply?
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
            } else if let detail = threadDetail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Thread Content
                        VStack(alignment: .leading, spacing: 16) {
                            Text(detail.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            // Author Info
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(AppColors.primary.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text((detail.user?.fullName ?? "Anonim").prefix(1))
                                            .font(.headline)
                                            .foregroundColor(AppColors.textPrimary)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(detail.user?.fullName ?? "Anonim")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Text(detail.createdAt)
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            
                            Text(detail.content)
                                .font(.body)
                                .foregroundColor(AppColors.textPrimary)
                                .lineSpacing(4)
                            
                            // Tags
                            if !detail.tags.isEmpty {
                                let tagArray = detail.tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                                HStack(spacing: 8) {
                                    ForEach(tagArray, id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.caption)
                                            .foregroundColor(AppColors.primary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(AppColors.primary.opacity(0.15))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        .padding(AppConstants.cardPadding)
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppConstants.cornerRadius)
                        
                        // Actions
                        HStack(spacing: 20) {
                            Button(action: { voteThread(voteType: ForumVoteType.like) }) {
                                Label("\(detail.likeCount)", systemImage: "hand.thumbsup")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Button(action: { voteThread(voteType: ForumVoteType.dislike) }) {
                                Label("\(detail.dislikeCount)", systemImage: "hand.thumbsdown")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Button(action: { showReplyField = true }) {
                                Label("Yanıtla", systemImage: "bubble.left")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.primary)
                            }
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(.horizontal, AppConstants.screenPadding)
                        
                        // Reply Input Field
                        if showReplyField {
                            VStack(alignment: .leading, spacing: 12) {
                                if let replyingTo = replyingTo {
                                    HStack {
                                        Text("Yanıtlanıyor: @\(replyingTo.user?.fullName ?? "Anonim")")
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                        
                                        Spacer()
                                        
                                        Button(action: { self.replyingTo = nil }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(AppColors.textTertiary)
                                        }
                                    }
                                }
                                
                                TextEditor(text: $replyText)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .frame(minHeight: 80)
                                    .background(AppColors.cardBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.cardBorder, lineWidth: 1)
                                    )
                                
                                HStack {
                                    Button("İptal") {
                                        showReplyField = false
                                        replyText = ""
                                        replyingTo = nil
                                    }
                                    .foregroundColor(AppColors.textSecondary)
                                    
                                    Spacer()
                                    
                                    Button("Gönder") {
                                        submitReply()
                                    }
                                    .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmittingReply)
                                    .foregroundColor(AppColors.primary)
                                    .fontWeight(.semibold)
                                }
                            }
                            .padding(AppConstants.screenPadding)
                            .background(AppColors.cardBackground.opacity(0.5))
                            .cornerRadius(AppConstants.cornerRadius)
                        }
                        
                        // Replies Section
                        if let replies = detail.replies, !replies.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Yanıtlar (\(replies.count))")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.horizontal, AppConstants.screenPadding)
                                
                                ForEach(replies, id: \.id) { reply in
                                    ReplyCard(reply: reply, onReply: { replyTo in
                                        self.replyingTo = replyTo
                                        self.showReplyField = true
                                    })
                                }
                            }
                        } else {
                            Text("Henüz yanıt yok")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, AppConstants.screenPadding)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadThreadDetail()
        }
    }
    
    private func loadThreadDetail() {
        Task {
            do {
                guard let token = authVM.accessToken else { return }
                
                let detail = try await ForumService.shared.getThreadDetail(
                    threadId: thread.id,
                    token: token
                )
                
                await MainActor.run {
                    self.threadDetail = detail
                    self.isLoading = false
                }
            } catch {
                print("Error loading thread detail: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func submitReply() {
        guard let token = authVM.accessToken,
              !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSubmittingReply = true
        
        Task {
            do {
                _ = try await ForumService.shared.createReply(
                    threadId: thread.id,
                    content: replyText,
                    parentId: replyingTo?.id,
                    token: token
                )
                
                await MainActor.run {
                    replyText = ""
                    showReplyField = false
                    replyingTo = nil
                    isSubmittingReply = false
                    // Reload thread to show new reply
                    loadThreadDetail()
                }
            } catch {
                print("Error submitting reply: \(error)")
                await MainActor.run {
                    isSubmittingReply = false
                }
            }
        }
    }
    
    private func voteThread(voteType: ForumVoteType) {
        guard let token = authVM.accessToken else { return }
        
        Task {
            do {
                _ = try await ForumService.shared.voteThread(
                    threadId: thread.id,
                    voteType: voteType,
                    token: token
                )
                
                // Reload to update vote counts
                loadThreadDetail()
            } catch {
                print("Error voting: \(error)")
            }
        }
    }
}

// MARK: - Reply Card
struct ReplyCard: View {
    let reply: ForumReply
    let onReply: (ForumReply) -> Void
    @State private var showChildren = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Reply Content
            VStack(alignment: .leading, spacing: 8) {
                // Author Info
                HStack(spacing: 8) {
                    Circle()
                        .fill(AppColors.primary.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text((reply.user?.fullName ?? "Anonim").prefix(1))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                        )
                    
                    Text(reply.user?.fullName ?? "Anonim")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("•")
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text(reply.createdAt)
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                    
                    if reply.isBestAnswer {
                        Label("En İyi Yanıt", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(AppColors.success)
                    }
                    
                    Spacer()
                }
                
                Text(reply.content)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                    .lineSpacing(2)
                
                // Actions
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Label("\(reply.likeCount)", systemImage: "hand.thumbsup")
                            .font(.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Button(action: {}) {
                        Label("\(reply.dislikeCount)", systemImage: "hand.thumbsdown")
                            .font(.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Button(action: { onReply(reply) }) {
                        Label("Yanıtla", systemImage: "arrow.turn.up.left")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if let children = reply.children, !children.isEmpty {
                        Button(action: { withAnimation { showChildren.toggle() } }) {
                            Label("\(children.count) yanıt", systemImage: showChildren ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
            }
            .padding(AppConstants.cardPadding)
            .background(AppColors.cardBackground)
            .cornerRadius(AppConstants.cornerRadius)
            .padding(.horizontal, AppConstants.screenPadding)
            
            // Nested Replies
            if showChildren, let children = reply.children {
                VStack(spacing: 8) {
                    ForEach(children, id: \.id) { childReply in
                        HStack(alignment: .top, spacing: 0) {
                            Rectangle()
                                .fill(AppColors.primary.opacity(0.2))
                                .frame(width: 2)
                                .padding(.leading, 40)
                            
                            ReplyCard(reply: childReply, onReply: onReply)
                                .padding(.leading, -10)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Create Thread View For Specific Topic
struct CreateThreadViewForTopic: View {
    @ObservedObject var authVM: AuthViewModel
    let topic: ForumTopic
    let onSuccess: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var content = ""
    @State private var tags = ""
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Topic Info Card
                        HStack(spacing: 12) {
                            Image(systemName: "folder.fill")
                                .font(.title3)
                                .foregroundColor(AppColors.primary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Konu")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Text(topic.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [AppColors.primary.opacity(0.1), AppColors.primary.opacity(0.05)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        
                        // Title Field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Başlık", systemImage: "text.quote")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Dikkat çekici bir başlık...", text: $title)
                                .font(.body)
                                .foregroundColor(AppColors.textPrimary)
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(title.isEmpty ? AppColors.cardBorder : AppColors.primary.opacity(0.5), lineWidth: 1)
                                )
                        }
                        
                        // Content Field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("İçerik", systemImage: "doc.text")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            ZStack(alignment: .topLeading) {
                                if content.isEmpty {
                                    Text("Düşüncelerini ve fikirlerini paylaş...")
                                        .font(.body)
                                        .foregroundColor(AppColors.textTertiary)
                                        .padding(.top, 12)
                                        .padding(.leading, 4)
                                }
                                
                                TextEditor(text: $content)
                                    .font(.body)
                                    .foregroundColor(AppColors.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .frame(minHeight: 180)
                            }
                            .padding(8)
                            .background(AppColors.cardBackground)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(content.isEmpty ? AppColors.cardBorder : AppColors.primary.opacity(0.5), lineWidth: 1)
                            )
                        }
                        
                        // Tags Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Etiketler", systemImage: "tag")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text("(opsiyonel)")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                            
                            TextField("Örn: BIST100, Analiz, 2025", text: $tags)
                                .font(.body)
                                .foregroundColor(AppColors.textPrimary)
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(AppColors.cardBorder, lineWidth: 1)
                                )
                            
                            if !tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }, id: \.self) { tag in
                                            if !tag.isEmpty {
                                                Text("#\(tag)")
                                                    .font(.caption)
                                                    .foregroundColor(AppColors.primary)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 4)
                                                    .background(AppColors.primary.opacity(0.15))
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppConstants.screenPadding)
                }
            }
            .navigationTitle("Yeni Tartışma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createThread) {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                                .scaleEffect(0.8)
                        } else {
                            Text("Paylaş")
                                .fontWeight(.semibold)
                                .foregroundColor(title.isEmpty || content.isEmpty ? AppColors.textTertiary : AppColors.primary)
                        }
                    }
                    .disabled(title.isEmpty || content.isEmpty || isCreating)
                }
            }
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createThread() {
        guard let token = authVM.accessToken else { return }
        
        isCreating = true
        
        Task {
            do {
                let tagArray = tags.split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                
                _ = try await ForumService.shared.createThread(
                    topicId: topic.id,
                    title: title,
                    content: content,
                    tags: tagArray,
                    token: token
                )
                
                await MainActor.run {
                    onSuccess()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = "Konu oluşturulamadı. Lütfen tekrar deneyin."
                    showError = true
                }
            }
        }
    }
}

struct ForumView_Previews: PreviewProvider {
    static var previews: some View {
        ForumView(authVM: AuthViewModel())
            .preferredColorScheme(.dark)
    }
}