import Foundation
import BrightFutures

public extension ReachFive {
    func getProvider(name: String) -> Provider? {
        providers.first(where: { $0.name == name })
    }
    
    func getProviders() -> [Provider] {
        providers
    }
    
    func initialize() -> Future<[Provider], ReachFiveError> {
        switch state {
        case .NotInitialized:
            return reachFiveApi.clientConfig().flatMap({ clientConfig -> Future<[Provider], ReachFiveError> in
                self.scope = clientConfig.scope.components(separatedBy: " ")
                return self.reachFiveApi.providersConfigs().map { providersConfigs in
                    let providers = self.createProviders(providersConfigsResult: providersConfigs, clientConfigResponse: clientConfig)
                    self.providers = providers
                    self.state = .Initialized
                    return providers
                }
            })
        
        case .Initialized:
            return Future.init(value: providers)
        }
    }
    
    private func createProviders(providersConfigsResult: ProvidersConfigsResult, clientConfigResponse: ClientConfigResponse) -> [Provider] {
        return providersConfigsResult.items.filter { $0.clientId != nil }.map({ config in
            if let nativeCreator = providersCreators.first(where: { $0.name == config.provider }) {
                return nativeCreator.create(
                    sdkConfig: sdkConfig,
                    providerConfig: config,
                    reachFiveApi: reachFiveApi,
                    clientConfigResponse: clientConfigResponse
                )
            }
            return DefaultProvider(reachfive: self, providerConfig: config)
        })
    }
}
