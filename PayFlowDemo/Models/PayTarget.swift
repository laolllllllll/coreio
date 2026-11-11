import Foundation

/// Who the simulated payment is "addressed" to.
///
/// The scanner never tries to impersonate a real payer/payee: it only reads the
/// plain text of a QR code, and whatever name it can find is labelled as a demo
/// target on screen, next to a permanent "非真实交易" marker.
struct PayTarget: Identifiable, Equatable {
    enum Source: Equatable {
        case qr
        case contact
    }

    let id = UUID()
    var name: String
    var amountText: String?
    var rawPayload: String
    var source: Source

    var rawPreview: String {
        let trimmed = rawPayload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "—" }
        if trimmed.count <= 48 { return trimmed }
        return String(trimmed.prefix(48)) + "…"
    }

    static func fromContact(_ item: ChatItem) -> PayTarget {
        PayTarget(name: item.name, amountText: nil, rawPayload: "会话：\(item.name)", source: .contact)
    }
}

/// Turns arbitrary QR text into a demo target. Deliberately conservative:
/// only explicit `name=` query values, our own `paydemo://` scheme, or very
/// short plain-text codes are treated as a display name.
enum QRCodePayload {
    static func makeTarget(from raw: String) -> PayTarget {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var name: String?
        var amount: Double?

        let allowedNameKeys: Set<String> = ["name", "n", "title", "nick", "nickname", "商户", "名称"]

        if let components = URLComponents(string: text), let queryItems = components.queryItems {
            for item in queryItems {
                let key = item.name.lowercased()
                if allowedNameKeys.contains(key) || allowedNameKeys.contains(item.name) {
                    if let value = item.value, !value.isEmpty {
                        name = name ?? value
                    }
                }
                if ["amount", "money", "fee", "price", "金额"].contains(key) || ["amount", "money", "fee", "price", "金额"].contains(item.name) {
                    if let value = item.value, let parsed = Double(value), parsed > 0 {
                        amount = amount ?? parsed
                    }
                }
            }
        }

        if name == nil, isPlainDisplayName(text) {
            name = text
        }

        let displayName = sanitize(name) ?? "演示对象"
        let amountText = amount.map { String(format: "%.2f", min($0, 99999)) }

        return PayTarget(
            name: displayName,
            amountText: amountText,
            rawPayload: text.isEmpty ? "（空内容）" : text,
            source: .qr
        )
    }

    /// Short, single-line, human looking strings can be used as a label.
    /// URLs, payment codes and long blobs are never interpreted as a name.
    private static func isPlainDisplayName(_ text: String) -> Bool {
        guard !text.isEmpty, text.count <= 24 else { return false }
        guard !text.contains("://"), !text.contains("\n") else { return false }
        guard !text.lowercased().hasPrefix("http"), !text.lowercased().hasPrefix("wxp") else { return false }
        guard text.rangeOfCharacter(from: .alphanumerics) != nil else { return false }
        return true
    }

    private static func sanitize(_ value: String?) -> String? {
        guard var value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        value = value.replacingOccurrences(of: "\n", with: " ")
        if value.count > 16 {
            value = String(value.prefix(16))
        }
        return value
    }
}
