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
        let webViewProvider = providersCreators.first(where: { $0.name == "webview" })
        return providersConfigsResult.items.filter { $0.clientId != nil }.map({ config in
                let nativeProvider = providersCreators.first(where: { $0.name == config.provider })
                if (nativeProvider != nil) {
                    return nativeProvider?.create(
                        sdkConfig: sdkConfig,
                        providerConfig: config,
                        reachFiveApi: reachFiveApi,
                        clientConfigResponse: clientConfigResponse
                    )
                } else if (webViewProvider != nil) {
                    return webViewProvider?.create(
                        sdkConfig: sdkConfig,
                        providerConfig: config,
                        reachFiveApi: reachFiveApi,
                        clientConfigResponse: clientConfigResponse
                    )
                } else {
                    return nil
                }
            })
            .compactMap { $0 }
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        interceptPasswordless(url)
        for provider in providers {
            let _ = provider.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
        }
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        interceptPasswordless(url)
        for provider in providers {
            let _ = provider.application(app, open: url, options: options)
        }
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        for provider in providers {
            let _ = provider.applicationDidBecomeActive(application)
        }
    }
}
