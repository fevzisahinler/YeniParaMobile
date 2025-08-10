import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var pushNotifications = true
    @State private var emailNotifications = false
    @State private var smsNotifications = false
    
    @State private var priceAlerts = true
    @State private var newsAlerts = true
    @State private var portfolioAlerts = true
    @State private var marketOpenClose = false
    @State private var weeklyReports = true
    @State private var promotions = false
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text("Bildirimler")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .opacity(0)
                }
                .padding(.horizontal, AppConstants.screenPadding)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Bildirim Kanalları
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Bildirim Kanalları")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppConstants.screenPadding)
                            
                            VStack(spacing: 1) {
                                NotificationToggleRow(
                                    icon: "bell.badge",
                                    title: "Push Bildirimleri",
                                    subtitle: "Anlık bildirimler",
                                    isOn: $pushNotifications,
                                    color: AppColors.primary
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                NotificationToggleRow(
                                    icon: "envelope",
                                    title: "E-posta Bildirimleri",
                                    subtitle: "Önemli güncellemeler",
                                    isOn: $emailNotifications,
                                    color: Color.blue
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                NotificationToggleRow(
                                    icon: "message",
                                    title: "SMS Bildirimleri",
                                    subtitle: "Kritik uyarılar",
                                    isOn: $smsNotifications,
                                    color: Color.green
                                )
                            }
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppConstants.cornerRadius)
                            .padding(.horizontal, AppConstants.screenPadding)
                        }
                        
                        // Piyasa Bildirimleri
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Piyasa Bildirimleri")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppConstants.screenPadding)
                            
                            VStack(spacing: 1) {
                                NotificationToggleRow(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Fiyat Uyarıları",
                                    subtitle: "Hedef fiyat bildirimleri",
                                    isOn: $priceAlerts,
                                    color: Color.orange
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                NotificationToggleRow(
                                    icon: "newspaper",
                                    title: "Haber Bildirimleri",
                                    subtitle: "Önemli piyasa haberleri",
                                    isOn: $newsAlerts,
                                    color: Color.purple
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                NotificationToggleRow(
                                    icon: "briefcase",
                                    title: "Portföy Uyarıları",
                                    subtitle: "Portföy değişimleri",
                                    isOn: $portfolioAlerts,
                                    color: Color.indigo
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                NotificationToggleRow(
                                    icon: "clock",
                                    title: "Piyasa Açılış/Kapanış",
                                    subtitle: "Günlük piyasa saatleri",
                                    isOn: $marketOpenClose,
                                    color: Color.teal
                                )
                            }
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppConstants.cornerRadius)
                            .padding(.horizontal, AppConstants.screenPadding)
                        }
                        
                        // Diğer Bildirimler
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Diğer")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppConstants.screenPadding)
                            
                            VStack(spacing: 1) {
                                NotificationToggleRow(
                                    icon: "doc.text",
                                    title: "Haftalık Raporlar",
                                    subtitle: "Piyasa özeti raporları",
                                    isOn: $weeklyReports,
                                    color: Color.cyan
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                NotificationToggleRow(
                                    icon: "gift",
                                    title: "Promosyonlar",
                                    subtitle: "Özel teklifler ve kampanyalar",
                                    isOn: $promotions,
                                    color: Color.pink
                                )
                            }
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppConstants.cornerRadius)
                            .padding(.horizontal, AppConstants.screenPadding)
                        }
                        
                        // Bildirim Zamanlaması
                        NotificationScheduleCard()
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct NotificationToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(.horizontal, AppConstants.screenPadding)
        .padding(.vertical, 12)
    }
}

struct NotificationScheduleCard: View {
    @State private var quietHoursEnabled = false
    @State private var startTime = Date()
    @State private var endTime = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sessiz Saatler")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Toggle(isOn: $quietHoursEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rahatsız Etme")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Belirlenen saatlerde bildirim gönderme")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .tint(AppColors.primary)
            
            if quietHoursEnabled {
                VStack(spacing: 12) {
                    HStack {
                        Label("Başlangıç", systemImage: "moon")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    
                    Divider()
                        .background(AppColors.cardBorder)
                    
                    HStack {
                        Label("Bitiş", systemImage: "sun.max")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(AppConstants.cardPadding)
        .background(AppColors.cardBackground)
        .cornerRadius(AppConstants.cornerRadius)
        .padding(.horizontal, AppConstants.screenPadding)
        .animation(.easeInOut, value: quietHoursEnabled)
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NotificationsView()
        }
        .preferredColorScheme(.dark)
    }
}