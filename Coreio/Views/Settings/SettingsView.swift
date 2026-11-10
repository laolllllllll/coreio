import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var registry: ToolRegistry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("API 配置") {
                    TextField("API 地址", text: $settings.apiBaseURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("ApiKey", text: $settings.apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("模型 ID", text: $settings.modelID)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("外观") {
                    Picker("主题", selection: $settings.appearance) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("工具调用（Function Calling）") {
                    if registry.schemas.isEmpty {
                        Text("暂无已注册工具").foregroundColor(.secondary)
                    } else {
                        ForEach(registry.schemas, id: \.name) { schema in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(schema.name).font(.headline)
                                Text(schema.description).font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Text("新增工具：实现 Tool 协议后调用 registry.register(工具实例)，聊天请求会自动携带 tools 字段，无需改动预设模型。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("关于") {
                    LabeledContent("Bundle ID", value: "ai.Coreio.app")
                    LabeledContent("名称", value: "Coreio")
                }
            }
            .navigationTitle("设置")
            .toolbar {
                Button("完成") { dismiss() }
            }
        }
    }
}
