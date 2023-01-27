import Foundation
import Alamofire
import BrightFutures

extension DataRequest {
    
    private func isSuccess(_ status: Int?) -> Bool {
        guard let status else {
            return false
        }
        return status >= 200 && status < 300
    }
    
    private func parseJson<T: Decodable>(json: Data, type: T.Type, decoder: JSONDecoder) -> Swift.Result<T, ReachFiveError> {
        do {
            let value = try decoder.decode(type, from: json)
            return .success(value)
        } catch {
            return .failure(ReachFiveError.TechnicalError(reason: error.localizedDescription))
        }
    }
    
    private func handleResponseStatus<T>(status: Int?, apiError: ApiError?, promise: Promise<T, ReachFiveError>) {
        guard let status else {
            promise.failure(ReachFiveError.TechnicalError(
                reason: "Technical error: Request without error code",
                apiError: apiError
            ))
            return
        }
        if let apiError, status == 400 {
            promise.failure(ReachFiveError.RequestError(apiError: apiError))
        } else if status == 400 {
            promise.failure(ReachFiveError.TechnicalError(reason: "Bad Request"))
        } else if status == 401 {
            promise.failure(ReachFiveError.AuthFailure(reason: "Unauthorized", apiError: apiError))
        } else {
            promise.failure(ReachFiveError.TechnicalError(
                reason: "Technical error: Request with \(status) error code",
                apiError: apiError
            ))
        }
    }
    
    func responseJson(decoder: JSONDecoder) -> Future<(), ReachFiveError> {
        let promise = BrightFutures.Promise<(), ReachFiveError>()
        responseString { responseData in
            let status = responseData.response?.statusCode
            if self.isSuccess(status) {
                promise.success(())
            } else {
                if let data = responseData.data {
                    switch self.parseJson(json: data, type: ApiError.self, decoder: decoder) {
                    case .success(let apiError):
                        self.handleResponseStatus(status: status, apiError: apiError, promise: promise)
                    case .failure(let error):
                        promise.failure(ReachFiveError.TechnicalError(reason: error.message()))
                    }
                } else {
                    self.handleResponseStatus(status: status, apiError: nil, promise: promise)
                }
            }
        }
        return promise.future
    }
    
    func responseJson<T: Decodable>(type: T.Type, decoder: JSONDecoder) -> Future<T, ReachFiveError> {
        let promise = BrightFutures.Promise<T, ReachFiveError>()
        
        responseString { responseData in
            let status = responseData.response?.statusCode
            if self.isSuccess(status) {
                if let data = responseData.data {
                    switch self.parseJson(json: data, type: T.self, decoder: decoder) {
                    case .success(let value):
                        promise.success(value)
                    case .failure(let error):
                        promise.failure(ReachFiveError.TechnicalError(reason: error.message()))
                    }
                } else {
                    promise.failure(ReachFiveError.TechnicalError(reason: "No data from server"))
                }
            } else {
                if let data = responseData.data {
                    switch self.parseJson(json: data, type: ApiError.self, decoder: decoder) {
                    case .success(let apiError):
                        self.handleResponseStatus(status: status, apiError: apiError, promise: promise)
                    case .failure(let error):
                        promise.failure(ReachFiveError.TechnicalError(reason: error.message()))
                    }
                } else {
                    self.handleResponseStatus(status: status, apiError: nil, promise: promise)
                }
            }
        }
        
        return promise.future
    }
}
