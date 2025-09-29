import Foundation

final class WebsocketNetworkManager: NetworkManager {

    private(set) var dependencies: DefaultNetworkDependencies
    
    init(with dependencies: DefaultNetworkDependencies) {
        self.dependencies = dependencies
    }

    private(set) lazy var networkService: NetworkService = {
         WebsocketNetworkService<DefaultSocketHandler>(with: getNetworkConfig(),
                                                             performOnQueue: dependencies.networkQueue)
    }()

    private(set) lazy var retryMech: Retryable = {
        WebsocketRetryMechanism(networkService: networkService,
                                reachability: dependencies.reachability,
                                deviceStatus: dependencies.deviceStatus,
                                appStateNotifier: dependencies.appStateNotifier,
                                performOnQueue: dependencies.networkQueue,
                                persistence: dependencies.defaultPersistence,
                                keepAliveService: dependencies.keepAliveService)
    }()

    func getNetworkConfig() -> NetworkConfigurable {
        WebsocketNetworkConfiguration(request: dependencies.request)
    }

    func makeNetworkBuilder() -> NetworkBuildable {
        WebsocketNetworkBuilder(networkConfigs: getNetworkConfig(),
                                retryMech: retryMech,
                                performOnQueue: dependencies.networkQueue)
    }

    var isConnected: Bool {
        networkService.isConnected
    }
}
