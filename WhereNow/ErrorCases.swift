public enum ErrorCases: Error {
    case Unknown
    case Described(String)
    
    var description: String {
        switch self {
        case .Unknown: return "Unknown"
        case .Described(let description): return description
        }
    }
}