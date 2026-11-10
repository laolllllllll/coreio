import Foundation

/// 示例工具：返回设备当前时间。
///
/// 新增工具的方法：
/// 1. 实现 `Tool` 协议，填写 `schema`（名称 / 描述 / 入参）与 `run(arguments:)`；
/// 2. 在启动处调用 `registry.register(你的工具())`；
/// 3. 聊天请求会自动带上 tools 字段，模型发起调用后由注册中心派发执行。
/// 不需要改动预设模型与聊天主流程。
struct TimeTool: Tool {
    let schema = ToolSchema(
        name: "get_current_time",
        description: "获取设备当前的本地时间",
        parameters: [:]
    )

    func run(arguments: [String: Any]) async throws -> String {
        DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
    }
}
