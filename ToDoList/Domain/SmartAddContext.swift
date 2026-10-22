/// What the parser may know besides the sentence: today, to resolve "tomorrow" or "Friday", and the categories to pick from.
struct SmartAddContext: Equatable {
    let today: DueDate
    let categories: [Category]
}
