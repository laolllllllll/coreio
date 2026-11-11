import SwiftUI
import PhotosUI

struct ChatEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let isNew: Bool
    private let onSave: (ChatItem) -> Void

    @State private var draft: ChatItem
    @State private var photoItem: PhotosPickerItem?

    private let emojiPresets = ["🙂", "🧑‍💻", "🛍️", "🌱", "🐱", "🍜", "🎧", "📦", "🎬", "🧋", "💼", "🧸"]
    private let colorPresets = ["#34C759", "#FF9500", "#0A84FF", "#FF3B30", "#AF52DE", "#FF2D55", "#8E8E93", "#30B0C7"]
    private let timePresets = ["刚刚", "00:27", "今天 12:30", "昨天", "周一"]

    init(item: ChatItem, isNew: Bool, onSave: @escaping (ChatItem) -> Void) {
        self.isNew = isNew
        self.onSave = onSave
        _draft = State(initialValue: item)
    }

    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("预览") {
                    ChatRow(item: draft)
                        .padding(.vertical, 4)
                }

                Section("名称") {
                    TextField("会话名称", text: $draft.name)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                }

                Section("头像") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        HStack(spacing: 12) {
                            AvatarView(
                                emoji: draft.avatarEmoji,
                                colorHex: draft.avatarColorHex,
                                imageName: draft.avatarImageName,
                                size: 44
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(draft.avatarImageName == nil ? "从相册选择图片" : "更换图片头像")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.primary)
                                Text("图片优先于表情，仅保存在本机")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }

                    if draft.avatarImageName != nil {
                        Button(role: .destructive) {
                            draft.avatarImageName = nil
                        } label: {
                            Label("移除图片头像", systemImage: "trash")
                        }
                    }

                    TextField("一个表情符号，例如 🙂", text: $draft.avatarEmoji)
                        .onChange(of: draft.avatarEmoji) { value in
                            if value.count > 4 {
                                draft.avatarEmoji = String(value.prefix(4))
                            }
                        }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                        ForEach(emojiPresets, id: \.self) { emoji in
                            Button {
                                draft.avatarImageName = nil
                                draft.avatarEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 24))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 42)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(draft.avatarEmoji == emoji ? DemoTheme.accent.opacity(0.18) : Color(white: 0.94))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("头像颜色") {
                    HStack(spacing: 12) {
                        ForEach(colorPresets, id: \.self) { hex in
                            Button {
                                draft.avatarColorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.65), lineWidth: draft.avatarColorHex == hex ? 2 : 0)
                                            .padding(-4)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("最后一条消息") {
                    TextField("消息内容", text: $draft.lastMessage, axis: .vertical)
                        .lineLimit(1...4)
                }

                Section("最后消息时间") {
                    TextField("自由文本，例如 00:27", text: $draft.timeText)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(timePresets, id: \.self) { preset in
                                Button(preset) {
                                    draft.timeText = preset
                                }
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 12)
                                .frame(height: 30)
                                .background(Capsule().fill(Color(white: 0.93)))
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                Section {
                    Toggle("消息免打扰", isOn: $draft.isMuted)
                } footer: {
                    Text("长按首页任意会话即可随时修改或删除。")
                }
            }
            .onChange(of: photoItem) { item in
                guard let item else { return }
                Task { @MainActor in
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let name = AvatarStore.save(imageData: data) {
                        // The previous file is removed by ChatStore.update after saving,
                        // so cancelling the sheet never leaves a broken avatar behind.
                        draft.avatarImageName = name
                    }
                    photoItem = nil
                }
            }
            .navigationTitle(isNew ? "新增会话" : "编辑会话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        var result = draft
                        result.name = result.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if result.avatarEmoji.isEmpty { result.avatarEmoji = "🙂" }
                        if result.timeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            result.timeText = "刚刚"
                        }
                        onSave(result)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
