import SwiftUI

struct KVKKView: View {
    @Environment(\.dismiss) private var dismiss

    private let kvkkText: String = """
6698 sayılı Kişisel Verilerin Korunması Kanunu, 07.04.2016 tarih ve 29677 sayılı Resmî Gazete’de yayımlanarak yürürlüğe girmiştir. Uluslararası belgeler, müktesebî hukuk uygulamaları ve ülkemiz ihtiyaçları göz önüne alınmak suretiyle hazırlanan Kanun ile kişisel verilerin çağdaş standartlarda işlenmesi ve koruma altına alınması amaçlanmaktadır. Bu kapsamda Kanunun amacı; kişisel verilerin işlenme şartlarını, kişisel verilerin işlenmesine ilişkin temel hak ve özgürlüklerin korunmasını ve kişisel verileri işleyen gerçek ve tüzel kişilerin yükümlülükleri ile uyacakları usul ve esasları düzenlemektir.

Kişisel verileriniz, Şirketimiz tarafından verilen hizmet, ürün ya da ticari faaliyete bağlı olarak değişiklik gösterebilmekle birlikte otomatik veya otomatik olmayan yöntemlerle; internet sitesi, sosyal medya mecraları, mobil uygulamalar ve benzeri vasıtalarla sözlü, yazılı ya da elektronik olarak toplanabilecektir.

Bu metni okudum, anladım ve tüm koşulları kabul ediyorum.
"""

    var body: some View {
        ZStack {
            Color(red: 28/255, green: 29/255, blue: 36/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Text("Sözleşme ve KVKK Aydınlatma Metni")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                ScrollView {
                    Text(kvkkText)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .padding(24)
                }

                PrimaryButton(
                    title: "Kabul Ediyorum",
                    action: { dismiss() },
                    background: Color(red: 143/255, green: 217/255, blue: 83/255),
                    foreground: .white
                )
                .frame(height: 48)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
