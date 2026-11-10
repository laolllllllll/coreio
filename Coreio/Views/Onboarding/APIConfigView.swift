import SwiftUI

struct APIConfigView: View {
    @EnvironmentObject private var settings: AppSettings

    @State private var busy = false
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        !settings.apiBaseURL.trimmingCharacters(in: .whitespaces).isEmpty &&
        !settings.modelID.trimmingCharacters(in: .whitespaces).isEmpty &&
        !busy
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("接入 AI 服务")
                        .font(.largeTitle.bold())
                    Text("填写 OpenAI 兼容接口的地址、密钥与模型 ID，点击继续后会自动发起一次测试请求，连通后进入程序。")
                        .foregroundColor(.secondary)

                    VStack(spacing: 14) {
                        TextField("API 地址，例如 https://host/v1", text: $settings.apiBaseURL)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        SecureField("ApiKey", text: $settings.apiKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("模型 ID", text: $settings.modelID)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        Task { await continueTapped() }
                    } label: {
                        HStack {
                            if busy { ProgressView().tint(.white) }
                            Text(busy ? "正在请求…" : "继续")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSubmit ? Color.accentColor : Color.secondary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canSubmit)
                }
                .padding(24)
            }
            .navigationTitle("Coreio")
            .alert("连接失败", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "未知错误")
            }
        }
    }

    private func continueTapped() async {
        busy = true
        defer { busy = false }
        let client = APIClient(
            baseURL: settings.apiBaseURL,
            apiKey: settings.apiKey,
            modelID: settings.modelID
        )
        do {
            try await client.testConnection()
            settings.didCompleteOnboarding = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
