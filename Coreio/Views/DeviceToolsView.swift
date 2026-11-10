import SwiftUI

struct DeviceToolsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var command = "id"
    @State private var output = ""
    @State private var running = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: JailbreakEnv.deviceToolsAvailable ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(JailbreakEnv.deviceToolsAvailable ? Color.green : Color.orange)
                        Text(JailbreakEnv.describe).font(.footnote)
                    }
                } header: {
                    Text("环境")
                }

                Section {
                    TextField("主机", text: $store.ssh.host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    HStack {
                        Text("端口")
                        Spacer()
                        TextField("22", value: $store.ssh.port, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    TextField("用户名", text: $store.ssh.user)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("密码（密码登录时使用）", text: $store.ssh.password)
                    TextField("私钥路径（可选，填了就优先用密钥）", text: $store.ssh.keyPath)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button {
                        run("id")
                    } label: {
                        Text(running ? "测试中…" : "测试连接")
                    }
                    .disabled(running)
                } header: {
                    Text("连接")
                } footer: {
                    Text("rootless 越狱装好 OpenSSH 后，本机服务默认是 root@127.0.0.1:22，密码一般是 alpine（你可以自己改）。私钥路径指向 App 能读到的文件，比如 /var/jb/var/root/.ssh/id_ed25519。")
                }

                Section {
                    Picker("权限", selection: $store.permission) {
                        ForEach(ToolPermissionMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    Text(store.permission.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("AI 执行权限")
                } footer: {
                    Text("AI 回复里的 ```ssh 代码块会按这里的选择被执行，执行结果自动回传给模型继续处理。")
                }

                Section("手动执行") {
                    TextField("命令", text: $command, axis: .vertical)
                        .lineLimit(1...4)
                        .font(.system(.footnote, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button {
                        run(command)
                    } label: {
                        Text(running ? "执行中…" : "执行")
                    }
                    .disabled(running || command.trimmingCharacters(in: .whitespaces).isEmpty)

                    if !output.isEmpty {
                        ScrollView {
                            Text(output)
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 180)
                    }
                }
            }
            .navigationTitle("设备工具")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func run(_ text: String) {
        let cmd = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else { return }
        let config = store.ssh
        running = true
        output = "执行中…"
        Task {
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try SSHRunner.run(cmd, config: config)
                }.value
                output = "$ \(cmd)\n[exit \(result.exitCode)]\n\(result.output)"
            } catch {
                output = "$ \(cmd)\n❌ \(error.localizedDescription)"
            }
            running = false
        }
    }
}
