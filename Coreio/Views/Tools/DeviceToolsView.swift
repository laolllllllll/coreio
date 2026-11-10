import SwiftUI

struct DeviceToolsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var shell: ShellExecutor
    @Environment(\.dismiss) private var dismiss

    @State private var command = ""
    @State private var pendingCommand: String?
    @State private var running = false
    @State private var status: JailbreakStatus = ShellExecutor.detect()

    var body: some View {
        NavigationStack {
            Form {
                Section("设备状态") {
                    LabeledContent("越狱环境", value: status.title)
                    if !status.isAvailable {
                        Text("终端工具仅在越狱（Rootless / Roothide）环境下可用。")
                            .foregroundColor(.secondary)
                    }
                }

                Section("权限模式") {
                    Picker("确认方式", selection: $settings.shellPermission) {
                        ForEach(ShellPermissionMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                    Text(settings.shellPermission.subtitle)
                        .font(.caption)
                        .foregroundColor(settings.shellPermission == .allow ? .red : .secondary)
                }

                if status.isAvailable {
                    Section("终端") {
                        TextField("输入命令", text: $command)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Button {
                            run()
                        } label: {
                            Label(running ? "执行中…" : "执行", systemImage: "play")
                        }
                        .disabled(running || command.trimmingCharacters(in: .whitespaces).isEmpty)

                        outputView
                    }
                }
            }
            .navigationTitle("设备工具")
            .toolbar {
                Button("完成") { dismiss() }
            }
            .alert("确认执行命令？", isPresented: Binding(
                get: { pendingCommand != nil },
                set: { if !$0 { pendingCommand = nil } }
            )) {
                Button("取消", role: .cancel) { pendingCommand = nil }
                Button("执行", role: .destructive) {
                    if let cmd = pendingCommand { execute(cmd, confirmed: true) }
                    pendingCommand = nil
                }
            } message: {
                Text(pendingCommand ?? "")
            }
            .onAppear { status = ShellExecutor.detect() }
        }
    }

    private var outputView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                if shell.lines.isEmpty {
                    Text("暂无输出").foregroundColor(.secondary)
                }
                ForEach(shell.lines) { line in
                    Text(line.text)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(line.kind == .error ? .red : line.kind == .input ? .accentColor : .primary)
                }
            }
        }
        .frame(minHeight: 160)
    }

    private func run() {
        let cmd = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else { return }
        shell.append(.init(kind: .input, text: cmd))
        command = ""

        if shell.shouldConfirm(command: cmd, permission: settings.shellPermission) {
            pendingCommand = cmd
        } else {
            execute(cmd, confirmed: true)
        }
    }

    private func execute(_ cmd: String, confirmed: Bool) {
        running = true
        Task {
            do {
                let out = try await shell.execute(
                    cmd,
                    permission: settings.shellPermission,
                    confirmed: confirmed
                )
                await MainActor.run {
                    shell.append(.init(kind: .output, text: out.isEmpty ? "(无输出)" : out))
                    running = false
                }
            } catch {
                await MainActor.run {
                    shell.append(.init(kind: .error, text: error.localizedDescription))
                    running = false
                }
            }
        }
    }
}
