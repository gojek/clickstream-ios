import Foundation

final class WebsocketManagerDependencies: NetworkManagerDependencies {

    private var request: URLRequest
    private let database: Database
    
    init(with request: URLRequest, db: Database) {
        self.database = db
        self.request = request
    }
    
    private let networkQueue = SerialQueue(label: Constants.QueueIdentifiers.network.rawValue, qos: .utility)
    
    private let daoQueue = DispatchQueue(label: Constants.QueueIdentifiers.dao.rawValue,
                                         qos: .utility,
                                         attributes: .concurrent)

    internal lazy var networkService: NetworkService = {
        return WebsocketNetworkService<DefaultSocketHandler>(with: getNetworkConfig(),
                                                               performOnQueue: networkQueue)
    }()
    
    internal lazy var reachability: NetworkReachability = {
        let reachability = DefaultNetworkReachability(with: networkQueue)
        return reachability
    }()

    internal lazy var retryMech: Retryable = {
       return WebsocketRetryMechanism(networkService: networkService,
                                      reachability: reachability,
                                      deviceStatus: deviceStatus,
                                      appStateNotifier: appStateNotifier,
                                      performOnQueue: networkQueue,
                                      persistence: defaultPersistence,
                                      keepAliveService: keepAliveService)
    }()
    
    private lazy var deviceStatus: DefaultDeviceStatus = {
        let deviceStatus = DefaultDeviceStatus(performOnQueue: networkQueue)
        return deviceStatus
    }()
    
    private lazy var appStateNotifier: AppStateNotifierService = {
        return DefaultAppStateNotifierService(with: networkQueue)
    }()
    
    private lazy var defaultPersistence: DefaultDatabaseDAO<EventRequest> = {
        return DefaultDatabaseDAO<EventRequest>(database: database,
                                                performOnQueue: daoQueue)
    }()
    
    private lazy var keepAliveService: KeepAliveService = {
        return DefaultKeepAliveServiceWithSafeTimer(with: networkQueue,
                                                    duration: Clickstream.configurations.connectionRetryDuration,
                                                    reachability: reachability)
    }()

    internal func getNetworkConfig() -> NetworkConfigurable {
        return WebsocketNetworkConfiguration(request: request)
    }

    func makeNetworkBuilder() -> NetworkBuildable {
        return WebsocketNetworkBuilder(networkConfigs: getNetworkConfig(), retryMech: retryMech, performOnQueue: networkQueue)
    }

    var isConnected: Bool {
        networkService.isConnected
    }
}
