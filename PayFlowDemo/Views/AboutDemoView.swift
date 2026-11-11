import SwiftUI

struct AboutDemoView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Fact: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
    }

    private let facts: [Fact] = [
        Fact(title: "纯本地演示", detail: "整个应用没有网络代码，不接入任何支付 SDK，也不会上传任何数据。"),
        Fact(title: "没有真实扣款", detail: "“模拟支付”只是页面切换，不会创建订单、不会产生账单。"),
        Fact(title: "扫码只读文本", detail: "相机识别到的二维码内容只会被当成字符串解析，用来在界面上显示一个演示对象名称。"),
        Fact(title: "水印不可关闭", detail: "付款页和成功页始终带有“演示 / 非真实交易”标记，避免被误认为真实凭证。"),
        Fact(title: "数据在本机", detail: "首页的会话、头像、消息、时间保存在应用沙盒内的 JSON 文件里。")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PayDemo · 支付流程演示")
                            .font(.system(size: 20, weight: .bold))
                        Text("一个用来练习 SwiftUI + AVFoundation 扫码 + 本地持久化的示例工程，不是任何真实支付工具的替代品。")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                Section("边界") {
                    ForEach(facts) { fact in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(fact.title)
                                .font(.system(size: 15, weight: .semibold))
                            Text(fact.detail)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("功能") {
                    Label("首页会话长按：编辑名称、头像、最后消息、时间；可删除、可新增", systemImage: "hand.tap")
                    Label("右上角 + 扫码或手动输入，进入付款页", systemImage: "qrcode.viewfinder")
                    Label("成功页点“完成”回到首页", systemImage: "checkmark.circle")
                }
                .font(.system(size: 13))

                Section {
                    Text("Bundle ID: com.example.paydemo — 可在 Xcode 的 Signing & Capabilities 里改成你自己的。")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("关于此演示")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("好") { dismiss() }
                }
            }
        }
    }
}
