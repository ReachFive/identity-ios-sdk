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
        let webViewCreator = providersCreators.first(where: { $0.name == "webview" })
        return providersConfigsResult.items.filter { $0.clientId != nil }.map({ config in
                let nativeCreator = providersCreators.first(where: { $0.name == config.provider })
                return (nativeCreator ?? webViewCreator)?.create(
                    sdkConfig: sdkConfig,
                    providerConfig: config,
                    reachFiveApi: reachFiveApi,
                    clientConfigResponse: clientConfigResponse
                )
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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initialize().onSuccess { providers in
            for provider in providers {
                let _ = provider.application(application, didFinishLaunchingWithOptions: launchOptions)
            }
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        for provider in providers {
            let _ = provider.applicationDidBecomeActive(application)
        }
    }
}
