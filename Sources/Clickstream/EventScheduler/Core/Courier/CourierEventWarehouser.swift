import Foundation

/// A class resposible to split the event based on the type.
final class CourierEventWarehouser: EventWarehouser {
    
    typealias EventType = CourierEvent

    private let performQueue: SerialQueue
    private let persistence: DefaultDatabaseDAO<CourierEvent>
    private let batchProcessor: CourierEventBatchProcessor
    private let batchSizeRegulator: CourierBatchSizeRegulator
    private let networkOptions: ClickstreamNetworkOptions

    private lazy var courierWhitelistedEvents: Set<String> = {
        Set(networkOptions.courierEventTypes.map { $0.lowercased() })
    }()

    init(with batchProcessor: CourierEventBatchProcessor,
         performOnQueue: SerialQueue,
         persistence: DefaultDatabaseDAO<CourierEvent>,
         batchSizeRegulator: CourierBatchSizeRegulator,
         networkOptions: ClickstreamNetworkOptions) {

        self.performQueue = performOnQueue
        self.persistence = persistence
        self.batchProcessor = batchProcessor
        self.batchSizeRegulator = batchSizeRegulator
        self.networkOptions = networkOptions

        start()
    }
    
    /// This method starts the event batch processor.
    private func start() {
        batchProcessor.start()
    }

    /// Track event for Visualiaser
    /// - Parameter event: Event
    private func trackEventVisualizer<T: EventPersistable>(_ event: T) {
        #if EVENT_VISUALIZER_ENABLED
        /// Update the status of the event to cached
        /// to check if the delegate is connected, if not no event should be sent to client
        if let stateViewer = Clickstream._stateViewer {
            /// Updating the event state to client to cache based on eventGuid
            stateViewer.updateStatus(providedEventGuid: event.guid, state: .cached)
        }
        #endif
        #if TRACKER_ENABLED
        let healthEvent = HealthAnalysisEvent(eventName: .ClickstreamEventCached,
                                              eventGUID: event.guid,
                                              eventCount: 1)
        if event.type != Constants.EventType.instant.rawValue {
            Tracker.sharedInstance?.record(event: healthEvent)
        }
        #endif
    }
}

extension CourierEventWarehouser {
    
    func store(_ event: CourierEvent) {
        performQueue.async { [weak self] in
            guard let checkedSelf = self else { return }

            if event.type == Constants.EventType.instant.rawValue {
                _ = checkedSelf.batchProcessor.sendInstantly(event: event)
            } else {
                if event.type != Constants.EventType.p0Event.rawValue {
                    checkedSelf.batchSizeRegulator.observe(event)
                }

                // Transform
                checkedSelf.persistence.insert(event)

                if event.type == Constants.EventType.p0Event.rawValue {
                    checkedSelf.batchProcessor.sendP0(classificationType: event.type)
                }

                checkedSelf.trackEventVisualizer(event)
            }
        }
    }
    
    func stop() {
        batchProcessor.stop()
    }
}
