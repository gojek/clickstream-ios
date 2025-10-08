import Foundation
import SwiftProtobuf

final class WebsocketNetworkService<C: Connectable>: NetworkService {
    
    private let connectableAccessQueue = DispatchQueue(label: Constants.QueueIdentifiers.connectableAccess.rawValue,
                                                       attributes: .concurrent)
    
    private let performQueue: SerialQueue
    private let networkConfig: NetworkConfigurable
    private var connectionCallback: ConnectionStatus?
    private var connectable: Connectable?
    private var _connectable: Connectable? {
        get {
            connectableAccessQueue.sync {
                return connectable
            }
        }
        set {
            connectableAccessQueue.sync(flags: .barrier) { [weak self] in
                guard let checkedSelf = self else { return }
                checkedSelf.connectable = newValue
            }
        }
    }
    
    /// Initializer
    /// - Parameters:
    ///   - networkConfig: Network Configuration.
    ///   - endpoint: Endpoint to which the connectable needs to connect to.
    ///   - performOnQueue: A SerialQueue on which the networkService needs to be run.
    init(with networkConfig: NetworkConfigurable,
         performOnQueue: SerialQueue) {
        self.networkConfig = networkConfig
        self.performQueue = performOnQueue
    }
}

extension WebsocketNetworkService {

    func initiateConnection(connectionStatusListener: ConnectionStatus?,
                            keepTrying: Bool = false) {
        guard _connectable == nil else { return }
        self.connectionCallback = connectionStatusListener
        let request = networkConfig.request
        _connectable = C(performOnQueue: performQueue)
        connectable?.setup(request: request,
                           keepTrying: false,
                           connectionCallback: self.connectionCallback)
    }
    
    func write<T>(_ data: Data, completion: @escaping (Result<T, ConnectableError>) -> Void) where T : Message {
        performQueue.async {
            self._connectable?.write(data) { [weak self] result in guard let _ = self else { return }
                switch result {
                case .success(let response):
                    guard let responseData = response else {
                        completion(Result.failure(ConnectableError.noResponse))
                        return
                    }
                    do {
                        let result = try T(serializedData: responseData) // Deserialise the proto data.
                        completion(.success(result))
                    } catch {
                        completion(Result.failure(ConnectableError.parsingData))
                    }
                case .failure(let error):
                    #if TRACKER_ENABLED
                    if Tracker.debugMode {
                        let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamWriteToSocketFailed,
                                                              reason: error.localizedDescription)
                        Tracker.sharedInstance?.record(event: healthEvent)
                    }
                    #endif
                    completion(Result.failure(ConnectableError.networkError(error)))
                }
            }
        }
    }
    
    func terminateConnection() {
        _connectable?.disconnect()
    }
    
    func flushConnectable() {
        _connectable = nil
    }
}

extension WebsocketNetworkService {
    
    var isConnected: Bool {
        _connectable?.isConnected.value ?? false
    }
}
