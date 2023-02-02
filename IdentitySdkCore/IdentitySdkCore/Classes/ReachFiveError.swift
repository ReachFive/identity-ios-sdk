import Foundation

public enum ReachFiveError: Error, CustomStringConvertible {
    /// debug friendly message
    public var description: String {
        switch self {
        case let .RequestError(apiError):
            return mkString(start: "RequestError", fields: (apiError, "apiError"))
        case let .AuthFailure(reason, apiError):
            return mkString(start: "AuthFailure", fields: (reason, "reason"), (apiError, "apiError"))
        case .AuthCanceled:
            return "AuthCanceled"
        case let .TechnicalError(reason, apiError):
            return mkString(start: "TechnicalError", fields: (reason, "reason"), (apiError, "apiError"))
        }
    }
    
    /// user friendly message
    public func message() -> String {
        switch self {
        case .RequestError(apiError: let apiError):
            return apiError.errorUserMsg ?? "no message"
        case .AuthFailure(reason: let reason, apiError: let apiError):
            let eum = apiError.flatMap({ $0.errorUserMsg })
            if reason.isEmpty {
                return eum ?? "no message"
            } else {
                return eum.map { m in "\(reason): \(m)" } ?? reason
            }
        case .AuthCanceled:
            return "Auth Canceled"
        case .TechnicalError(reason: let reason, apiError: let apiError):
            let eum = apiError.flatMap({ $0.errorUserMsg })
            if reason.isEmpty {
                return eum ?? "no message"
            } else {
                return eum.map { m in "\(reason): \(m)" } ?? reason
            }
        }
    }
    
    case RequestError(apiError: ApiError)
    case AuthFailure(reason: String, apiError: ApiError? = nil)
    /// Returned after signin requests. Either the system doesn't find any credentials and the authentification ends silently, or the user cancels the request.
    /// This is a good time to show a traditional login form, or ask the user to create an account.
    case AuthCanceled
    case TechnicalError(reason: String, apiError: ApiError? = nil)
}

public class ApiError: Codable, CustomStringConvertible {
    public var description: String {
        mkString(start: "ApiError", fields: (error, "error"),
            (errorMessageKey, "errorMessageKey"),
            (errorUserMsg, "errorUserMsg"),
            (errorDetails, "errorDetails"))
    }
    
    public let error: String?
    public let errorId: String?
    public let errorUserMsg: String?
    public let errorMessageKey: String?
    public let errorDescription: String?
    public let errorDetails: [FieldError]?
}

public class FieldError: Codable, CustomStringConvertible {
    public var description: String {
        mkString(start: "FieldError", fields: (field, "field"),
            (message, "message"),
            (code, "code"))
    }
    
    public let field: String?
    public let message: String?
    public let code: String?
}
