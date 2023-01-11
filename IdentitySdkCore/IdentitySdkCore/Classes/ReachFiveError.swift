import Foundation

public enum ReachFiveError: Error {
    public func message() -> String {
        switch self {
        case .RequestError(apiError: let apiError):
            return apiError.errorUserMsg ?? "no message"
        case .AuthFailure(reason: let reason, apiError: let apiError):
            let eum = apiError.flatMap({ $0.errorUserMsg })
            if (reason.isEmpty) {
                return eum ?? "no message"
            } else {
                return eum.map { m in "\(reason): \(m)" } ?? reason
            }
        case .AuthCanceled:
            return "Auth Canceled"
        case .TechnicalError(reason: let reason, apiError: let apiError):
            let eum = apiError.flatMap({ $0.errorUserMsg })
            if (reason.isEmpty) {
                return eum ?? "no message"
            } else {
                return eum.map { m in "\(reason): \(m)" } ?? reason
            }
        }
    }
    
    case RequestError(apiError: ApiError)
    case AuthFailure(reason: String, apiError: ApiError? = nil)
    case AuthCanceled
    case TechnicalError(reason: String, apiError: ApiError? = nil)
}

public class ApiError: Codable {
    public let error: String?
    public let errorId: String?
    public let errorUserMsg: String?
    public let errorMessageKey: String?
    public let errorDescription: String?
    public let errorDetails: [FieldError]?
}

public class FieldError: Codable {
    public let field: String?
    public let message: String?
    public let code: String?
}
