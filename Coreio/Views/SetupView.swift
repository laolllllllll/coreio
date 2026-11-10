import SwiftUI

struct SetupView: View {
    @EnvironmentObject private var store: AppStore

    @State private var baseURL = ""
    @State private var apiKey = ""
    @State private var model = ""
    @State private var testing = false
    @State private var errorText: String?
    @State private var replyText: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                        Text("Coreio").font(.title2.weight(.bold))
                        Text("填入 AI 接口信息，验证通过后进入")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .listRowBackground(Color.clear)
                }

                Section {
                    TextField("API 地址", text: $baseURL, prompt: Text("https://api.openai.com/v1"))
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("API Key", text: $apiKey, prompt: Text("sk-..."))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("模型 ID", text: $model, prompt: Text("gpt-4o-mini"))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("接口配置")
                } footer: {
                    Text("兼容 OpenAI 格式的接口都行，如智谱 / DeepSeek / Groq / OpenRouter / Gemini。地址写到版本号即可，App 会自动补 /chat/completions。")
                }

                Section {
                    if testing {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("正在请求，等待模型回复…").font(.subheadline)
                        }
                    } else {
                        Button {
                            Task { await runTest() }
                        } label: {
                            Text("继续").frame(maxWidth: .infinity, alignment: .center).font(.body.weight(.semibold))
                        }
                        .disabled(!isFillComplete)
                    }
                }

                if let errorText {
                    Section {
                        Text(errorText).font(.footnote).foregroundStyle(.red)
                    }
                }

                if let replyText {
                    Section("模型原始回复") {
                        Text(replyText.isEmpty ? "（空）" : replyText)
                            .font(.system(.footnote, design: .monospaced))
                    }
                }
            }
            .navigationTitle("初始化")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if baseURL.isEmpty { baseURL = store.config.baseURL }
                if model.isEmpty { model = store.config.model }
            }
        }
    }

    private var isFillComplete: Bool {
        !baseURL.trimmingCharacters(in: .whitespaces).isEmpty
            && !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
            && !model.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func runTest() async {
        errorText = nil
        replyText = nil

        let candidate = APIConfig(
            baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines),
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            model: model.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        guard candidate.isValid else {
            errorText = "三项都要填完整"
            return
        }

        testing = true
        do {
            let text = try await store.verify(candidate)
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            replyText = cleaned
            if cleaned.contains("1") {
                store.finishSetup(with: candidate)
            } else {
                errorText = "没有识别到 1，无法进入。请检查模型 ID 是否可用，或换一个模型再试。"
            }
        } catch {
            errorText = "连接失败：\(error.localizedDescription)"
        }
        testing = false
    }
}
