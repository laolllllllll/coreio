import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var baseURL = ""
    @State private var apiKey = ""
    @State private var model = ""
    @State private var appearance: AppearanceMode = .system
    @State private var forceShowTools = false
    @State private var message: String?
    @State private var busy = false
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("API 地址", text: $baseURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("模型 ID", text: $model)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button {
                        Task { await saveAndTest() }
                    } label: {
                        HStack {
                            if busy { ProgressView().padding(.trailing, 4) }
                            Text(busy ? "验证中…" : "验证并保存")
                        }
                    }
                    .disabled(busy)

                    if let message {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(message.hasPrefix("已保存") ? Color.green : Color.red)
                    }
                } header: {
                    Text("接口")
                } footer: {
                    Text("更换模型 / 换服务商都在这里改，保存前会发一条测试请求验证能不能用。")
                }

                Section {
                    ForEach(Presets.list) { preset in
                        Button {
                            baseURL = preset.baseURL
                            model = preset.model
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.name).font(.subheadline.weight(.medium))
                                    Text("\(preset.model) · \(preset.note)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if model == preset.model {
                                    Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Text("常用模型")
                } footer: {
                    Text("点一下自动填地址和模型 ID，Key 需要自己填。")
                }

                Section("外观") {
                    Picker("主题", selection: $appearance) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle("始终显示设备工具", isOn: $forceShowTools)
                    Text(JailbreakEnv.describe)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("设备")
                } footer: {
                    Text("正常情况下只有 rootless 越狱并且装了 OpenSSH，底部才会出现「设备工具」。这个开关只是强制显示，用来调试。")
                }

                Section("数据") {
                    Button("清空所有对话") { showClearConfirm = true }
                        .foregroundStyle(.red)
                    Button("重新配置接口") {
                        store.resetSetup()
                        dismiss()
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { commit(); dismiss() }
                }
            }
            .alert("清空所有对话？", isPresented: $showClearConfirm) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) { store.clearAllConversations() }
            } message: {
                Text("包含已归档的对话，删除后无法恢复。")
            }
            .onAppear {
                baseURL = store.config.baseURL
                apiKey = store.config.apiKey
                model = store.config.model
                appearance = store.appearance
                forceShowTools = store.forceShowTools
            }
            .onChange(of: appearance) { value in
                store.appearance = value
            }
            .onChange(of: forceShowTools) { value in
                store.forceShowTools = value
            }
        }
    }

    private func commit() {
        store.config = APIConfig(
            baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines),
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            model: model.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        store.appearance = appearance
        store.forceShowTools = forceShowTools
    }

    private func saveAndTest() async {
        message = nil
        let candidate = APIConfig(
            baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines),
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            model: model.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        guard candidate.isValid else {
            message = "三项都要填完整"
            return
        }
        busy = true
        do {
            let text = try await store.verify(candidate)
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.contains("1") {
                store.config = candidate
                message = "已保存，模型回复 1，接口可用"
            } else {
                message = "模型没有回复 1：\(String(cleaned.prefix(40)))，未保存"
            }
        } catch {
            message = "连接失败：\(error.localizedDescription)"
        }
        busy = false
    }
}
