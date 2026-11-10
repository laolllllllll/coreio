import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse(Int, String)
    case decodingFailed
    case emptyModelID

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "API 地址无效"
        case .invalidResponse(let code, let body):
            return "请求失败（\(code)）：\(body)"
        case .decodingFailed: return "返回数据解析失败"
        case .emptyModelID: return "请先填写模型 ID"
        }
    }
}

/// OpenAI 兼容的 Chat Completions 客户端。
/// 仅负责请求/解析，不内置或改写任何预设模型名。
final class APIClient {
    private let baseURL: String
    private let apiKey: String
    private let modelID: String

    init(baseURL: String, apiKey: String, modelID: String) {
        self.baseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.modelID = modelID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var endpoint: URL? {
        let trimmed = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        return URL(string: trimmed + "/chat/completions")
    }

    /// 首次进入 / 更换配置后的连通性测试：发一条最小请求，HTTP 2xx 即视为通过。
    func testConnection() async throws {
        guard !modelID.isEmpty else { throw APIError.emptyModelID }
        let body: [String: Any] = [
            "model": modelID,
            "messages": [["role": "user", "content": "ping"]],
            "max_tokens": 1
        ]
        _ = try await perform(body: body)
    }

    /// 发送一轮对话。messages 为 OpenAI 兼容消息数组；tools 为已注册工具的 schema。
    /// 返回助手文本内容（工具调用结果由上层 ToolRegistry 继续派发）。
    @discardableResult
    func send(messages: [[String: Any]], tools: [[String: Any]] = []) async throws -> String {
        guard !modelID.isEmpty else { throw APIError.emptyModelID }
        var body: [String: Any] = [
            "model": modelID,
            "messages": messages
        ]
        if !tools.isEmpty {
            body["tools"] = tools
        }
        let json = try await perform(body: body)
        return Self.extractContent(from: json)
    }

    private func perform(body: [String: Any]) async throws -> [String: Any] {
        guard let url = endpoint else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(-1, "无响应")
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw APIError.invalidResponse(http.statusCode, msg)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.decodingFailed
        }
        return json
    }

    private static func extractContent(from json: [String: Any]) -> String {
        guard
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else { return "" }
        return content
    }
}
