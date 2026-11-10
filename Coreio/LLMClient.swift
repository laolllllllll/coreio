import Foundation

enum LLMError: LocalizedError {
    case badURL
    case http(Int, String)
    case empty
    case decode

    var errorDescription: String? {
        switch self {
        case .badURL: return "接口地址不正确"
        case let .http(code, body): return "HTTP \(code)：\(body)"
        case .empty: return "返回内容为空"
        case .decode: return "返回格式无法解析（需要 OpenAI 兼容接口）"
        }
    }
}

struct ChatRequestMessage {
    let role: String
    let content: String

    var json: [String: String] {
        ["role": role, "content": content]
    }
}

struct LLMClient {
    let config: APIConfig

    static func endpoint(for raw: String) -> URL? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return nil }
        if !s.lowercased().hasPrefix("http") { s = "https://" + s }
        while s.hasSuffix("/") { s.removeLast() }
        if s.hasSuffix("/chat/completions") { return URL(string: s) }
        return URL(string: s + "/chat/completions")
    }

    private func makeRequest(messages: [ChatRequestMessage], stream: Bool, maxTokens: Int?) throws -> URLRequest {
        guard let url = LLMClient.endpoint(for: config.baseURL) else { throw LLMError.badURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 120
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("Coreio/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        var body: [String: Any] = [
            "model": config.model.trimmingCharacters(in: .whitespacesAndNewlines),
            "messages": messages.map { $0.json },
            "stream": stream,
        ]
        if let maxTokens { body["max_tokens"] = maxTokens }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return req
    }

    /// 非流式一次性请求，用于配置页的连通性测试
    func complete(messages: [ChatRequestMessage], maxTokens: Int = 32) async throws -> String {
        let request = try makeRequest(messages: messages, stream: false, maxTokens: maxTokens)
        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else {
            throw LLMError.http(code, String(data: data, encoding: .utf8)?.prefix(400).description ?? "")
        }
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = obj["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any]
        else { throw LLMError.decode }

        if let text = message["content"] as? String { return text }
        if let parts = message["content"] as? [[String: Any]] {
            let joined = parts.compactMap { $0["text"] as? String }.joined()
            return joined
        }
        throw LLMError.empty
    }

    /// 流式输出
    func stream(messages: [ChatRequestMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let request = try makeRequest(messages: messages, stream: true, maxTokens: nil)
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                    if code != 200 {
                        var raw = ""
                        for try await line in bytes.lines { raw += line }
                        throw LLMError.http(code, String(raw.prefix(400)))
                    }
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data:") else { continue }
                        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                        if payload == "[DONE]" { break }
                        guard let chunk = try? JSONDecoder().decode(StreamChunk.self, from: Data(payload.utf8)) else { continue }
                        if let delta = chunk.choices.first?.delta.content, !delta.isEmpty {
                            continuation.yield(delta)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

private struct StreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
        }
        let delta: Delta
    }
    let choices: [Choice]
}
