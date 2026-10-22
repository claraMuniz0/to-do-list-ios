import Foundation

/// Asks Claude for a task draft through a forced `create_task_draft` tool call and maps the reply, field by
/// field, into validated domain values. Nothing Claude returns is trusted: ids, lengths and dates are re-checked.
struct ClaudeTaskDraftParser: TaskDraftParsing {
    static let toolName = "create_task_draft"
    private static let maxTokens = 512

    private let client: ClaudeClient

    init(client: ClaudeClient) {
        self.client = client
    }

    /// Today and the category ids change per call, so they are part of the prompt rather than a constant.
    static func systemPrompt(for context: SmartAddContext) -> String {
        let categories = context.categories.map { "\($0.id.value) (\($0.name.value))" }.joined(separator: ", ")
        return """
        You fill in a to-do task from one sentence. Reply only by calling the create_task_draft tool. \
        Today is \(format(context.today)). Resolve relative dates such as "tomorrow", "Friday" or "next Tuesday" \
        from today and answer with a date only, formatted YYYY-MM-DD, never a time. "Next week" means today plus 7 days. \
        Ignore priority and urgency. Pick category_id from exactly these ids: \(categories). \
        Write title, description and steps in the language of the sentence. \
        Do not invent: leave description, due_date and steps out unless the sentence says them, \
        and give steps only if the user listed them.
        """
    }

    private struct Draft: Decodable {
        let title: String?
        let description: String?
        let categoryID: String?
        let dueDate: String?
        let steps: [String]?

        enum CodingKeys: String, CodingKey {
            case title, description, steps
            case categoryID = "category_id"
            case dueDate = "due_date"
        }
    }

    func parse(_ text: SmartAddText, context: SmartAddContext) async throws -> TaskDraft {
        let response: ClaudeResponse
        do {
            response = try await client.send(request(text: text, context: context))
        } catch ClaudeError.offline {
            throw SmartAddError.offline
        } catch {
            throw SmartAddError.failed
        }
        guard response.toolName == Self.toolName,
              let draft = try? JSONDecoder().decode(Draft.self, from: response.toolInput)
        else { throw SmartAddError.failed }
        return try map(draft, context: context)
    }

    /// An overlong title is cut rather than rejected: the sentence allows 280 characters, the title only 120.
    private func map(_ draft: Draft, context: SmartAddContext) throws -> TaskDraft {
        let rawTitle = (draft.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let title = try? TodoItemTitle(String(rawTitle.prefix(TodoItemTitle.maxLength))) else {
            throw SmartAddError.couldNotUnderstand
        }
        return TaskDraft(
            title: title,
            description: draft.description,
            categoryID: Self.category(draft.categoryID, in: context.categories),
            dueDate: draft.dueDate.flatMap { Self.dueDate($0, today: context.today) },
            steps: (draft.steps ?? []).compactMap { try? StepTitle($0) }
        )
    }

    private static func category(_ rawID: String?, in categories: [Category]) -> CategoryID {
        categories.first { $0.id.value == rawID }?.id ?? Category.personal.id
    }

    /// Only `YYYY-MM-DD`, and never a year before today's: a model that resolves "Friday" into last year is wrong.
    private static func dueDate(_ raw: String, today: DueDate) -> DueDate? {
        let parts = raw.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
              year >= today.year
        else { return nil }
        return try? DueDate(year: year, month: month, day: day)
    }

    private static func format(_ date: DueDate) -> String {
        String(format: "%04d-%02d-%02d", date.year, date.month, date.day)
    }

    private func request(text: SmartAddText, context: SmartAddContext) -> ClaudeRequest {
        ClaudeRequest(
            systemPrompt: Self.systemPrompt(for: context),
            userMessage: text.value,
            tool: ClaudeTool(
                name: Self.toolName,
                description: "Returns the task described by the sentence.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "title": .object(["type": .string("string")]),
                        "description": .object(["type": .string("string")]),
                        "category_id": .object(["type": .string("string")]),
                        "due_date": .object(["type": .string("string"), "description": .string("YYYY-MM-DD, no time")]),
                        "steps": .object(["type": .string("array"), "items": .object(["type": .string("string")])])
                    ]),
                    "required": .array([.string("title")])
                ])
            ),
            maxTokens: Self.maxTokens
        )
    }
}
