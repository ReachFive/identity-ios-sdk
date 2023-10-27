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
            return createMessage(reason: "", apiError: apiError)
        case .AuthFailure(reason: let reason, apiError: let apiError):
            return createMessage(reason: reason, apiError: apiError)
        case .AuthCanceled:
            return "Auth Canceled"
        case .TechnicalError(reason: let reason, apiError: let apiError):
            return createMessage(reason: reason, apiError: apiError)
        }
    }
    
    private func createMessage(reason: String, apiError: ApiError? = nil) -> String {
        let allMessages: String? = apiError.flatMap { error in
            let topLevelMessage = error.errorUserMsg ?? error.errorDescription
            var fieldMessages = error.errorDetails.flatMap { fieldErrors in fieldErrors.compactMap { $0.message } } ?? []
            
            if let topLevelMessage {
                fieldMessages.insert(topLevelMessage, at: 0)
            }
            
            if !fieldMessages.isEmpty {
                return mkString(start: "", sep: "\n", end: "", fields: fieldMessages)
            }
            
            return nil
        }
        
        if reason.isEmpty {
            return allMessages ?? "no message"
        } else {
            return allMessages.map { m in "\(reason)\n \(m)" } ?? reason
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
            (errorId, "errorId"),
            (errorMessageKey, "errorMessageKey"),
            (errorUserMsg, "errorUserMsg"),
            (errorDescription, "errorDescription"),
            (errorDetails, "errorDetails"))
    }
    
    public let error: String?
    public let errorId: String?
    public let errorUserMsg: String?
    public let errorMessageKey: String?
    public let errorDescription: String?
    public let errorDetails: [FieldError]?
    
    public init(error: String? = nil,
                errorId: String? = nil,
                errorUserMsg: String? = nil,
                errorMessageKey: String? = nil,
                errorDescription: String? = nil,
                errorDetails: [FieldError]? = nil) {
        self.error = error
        self.errorId = errorId
        self.errorUserMsg = errorUserMsg
        self.errorMessageKey = errorMessageKey
        self.errorDescription = errorDescription
        self.errorDetails = errorDetails
    }
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
    
    public init(field: String? = nil, message: String? = nil, code: String? = nil) {
        self.field = field
        self.message = message
        self.code = code
    }
}
