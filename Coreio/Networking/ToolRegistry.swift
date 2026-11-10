import Foundation
import Combine

/// 工具入参声明（OpenAI function calling 风格）
struct ToolParameter: Codable, Equatable {
    let type: String
    let description: String?
    let enumValues: [String]?

    init(type: String, description: String? = nil, enumValues: [String]? = nil) {
        self.type = type
        self.description = description
        self.enumValues = enumValues
    }
}

/// 工具 Schema
struct ToolSchema: Codable, Equatable {
    let name: String
    let description: String
    let parameters: [String: ToolParameter]
}

/// 可被模型调用的工具协议。新增工具时实现该协议并注册到 ToolRegistry 即可，
/// 不需要改动预设模型与聊天主流程。
protocol Tool {
    var schema: ToolSchema { get }
    /// 执行工具，arguments 为模型解析后的 JSON 字典，返回纯文本结果回传给模型。
    func run(arguments: [String: Any]) async throws -> String
}

/// 工具注册中心：负责持有已注册工具，并生成请求体里的 tools 字段。
final class ToolRegistry: ObservableObject {
    @Published private(set) var schemas: [ToolSchema] = []
    private var tools: [String: Tool] = [:]

    func register(_ tool: Tool) {
        schemas.append(tool.schema)
        tools[tool.schema.name] = tool
    }

    func removeAll() {
        schemas.removeAll()
        tools.removeAll()
    }

    func tool(named name: String) -> Tool? {
        tools[name]
    }

    /// 拼接成 chat/completions 请求体中的 `tools` 数组。
    func schemaPayload() -> [[String: Any]] {
        schemas.map { schema in
            var properties: [String: Any] = [:]
            for (key, param) in schema.parameters {
                var p: [String: Any] = ["type": param.type, "description": param.description ?? ""]
                if let enumValues = param.enumValues, !enumValues.isEmpty {
                    p["enum"] = enumValues
                }
                properties[key] = p
            }
            return [
                "type": "function",
                "function": [
                    "name": schema.name,
                    "description": schema.description,
                    "parameters": [
                        "type": "object",
                        "properties": properties
                    ]
                ]
            ]
        }
    }
}
