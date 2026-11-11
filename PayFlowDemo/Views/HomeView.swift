import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: ChatStore

    @State private var searchText = ""
    @State private var scannerShown = false
    @State private var payTarget: PayTarget?
    @State private var editorConfig: EditorConfig?
    @State private var pendingTarget: PayTarget?
    @State private var qrShown = false
    @State private var aboutShown = false

    private var filteredItems: [ChatItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return store.items }
        return store.items.filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.lastMessage.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DemoBanner()

                List {
                    ForEach(filteredItems) { item in
                        ChatRow(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture { payTarget = PayTarget.fromContact(item) }
                            .contextMenu {
                                Button {
                                    editorConfig = EditorConfig(item: item, isNew: false)
                                } label: {
                                    Label("编辑名称 / 头像 / 消息 / 时间", systemImage: "pencil")
                                }

                                Button {
                                    payTarget = PayTarget.fromContact(item)
                                } label: {
                                    Label("发起一次模拟支付", systemImage: "yensign.circle")
                                }

                                Button {
                                    editorConfig = EditorConfig(item: ChatItem.newDraft(), isNew: true)
                                } label: {
                                    Label("新增会话", systemImage: "plus.square")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    store.delete(item.id)
                                } label: {
                                    Label("删除会话", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    store.delete(item.id)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }

                                Button {
                                    editorConfig = EditorConfig(item: item, isNew: false)
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .listRowBackground(Color.white)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

                    if filteredItems.isEmpty {
                        Text("没有匹配的会话，点右上角 + 新增一个。")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.white)

                footer
            }
            .background(DemoTheme.pageBackground)
            .navigationTitle("PayDemo")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "搜索演示会话"
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            scannerShown = true
                        } label: {
                            Label("扫一扫（演示）", systemImage: "qrcode.viewfinder")
                        }

                        Button {
                            editorConfig = EditorConfig(item: ChatItem.newDraft(), isNew: true)
                        } label: {
                            Label("新增会话", systemImage: "square.and.pencil")
                        }

                        Button {
                            qrShown = true
                        } label: {
                            Label("生成演示二维码", systemImage: "qrcode")
                        }

                        Divider()

                        Button {
                            aboutShown = true
                        } label: {
                            Label("关于此演示", systemImage: "info.circle")
                        }

                        Button(role: .destructive) {
                            store.resetToSamples()
                        } label: {
                            Label("恢复示例数据", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20, weight: .regular))
                    }
                    .accessibilityLabel("更多操作")
                }
            }
            .fullScreenCover(
                isPresented: $scannerShown,
                onDismiss: {
                    // Present the payment screen only after the scanner is fully gone,
                    // otherwise UIKit can drop the second presentation.
                    if let target = pendingTarget {
                        pendingTarget = nil
                        payTarget = target
                    }
                }
            ) {
                ScannerView(
                    onCancel: { scannerShown = false },
                    onCode: { code in
                        pendingTarget = QRCodePayload.makeTarget(from: code)
                        scannerShown = false
                    }
                )
            }
            .fullScreenCover(item: $payTarget) { target in
                PaymentFlowView(target: target)
            }
            .sheet(item: $editorConfig) { config in
                ChatEditorView(item: config.item, isNew: config.isNew) { saved in
                    if config.isNew {
                        store.add(saved)
                    } else {
                        store.update(saved)
                    }
                }
            }
            .sheet(isPresented: $qrShown) {
                DemoQRCodeView()
            }
            .sheet(isPresented: $aboutShown) {
                AboutDemoView()
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("点会话发起模拟支付 · 长按可编辑 / 删除 / 新增")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text("所有数据只保存在本机，卸载应用即清除")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.black.opacity(0.06)).frame(height: 0.5)
        }
    }
}

struct EditorConfig: Identifiable {
    let id = UUID()
    var item: ChatItem
    var isNew: Bool
}

extension ChatItem {
    static func newDraft() -> ChatItem {
        ChatItem(
            name: "",
            avatarEmoji: "🙂",
            avatarColorHex: "#34C759",
            lastMessage: "",
            timeText: "刚刚"
        )
    }
}
