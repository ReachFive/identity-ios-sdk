import Foundation

public enum ReachFiveError: Error {
    public func message() -> String {
        switch self {
        case .RequestError(apiError: let apiError):
            return apiError.errorUserMsg ?? "no message"
        case .AuthFailure(reason: let reason, apiError: let apiError):
            if (reason.isEmpty) { return apiError.flatMap({ $0.errorUserMsg }) ?? "no message" } else { return reason }
        case .AuthCanceled:
            return "Auth Canceled"
        case .TechnicalError(reason: let reason, apiError: let apiError):
            if (reason.isEmpty) { return apiError.flatMap({ $0.errorUserMsg }) ?? "no message" } else { return reason }
        }
    }
    
    case RequestError(apiError: ApiError)
    case AuthFailure(reason: String, apiError: ApiError? = nil)
    /// Returned after signin requests. Either the system doesn't find any credentials and the authentification ends silently, or the user cancels the request.
    /// This is a good time to show a traditional login form, or ask the user to create an account.
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
