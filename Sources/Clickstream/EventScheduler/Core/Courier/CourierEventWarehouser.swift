import Foundation

/// A class resposible to split the event based on the type.
final class CourierEventWarehouser: EventWarehouser {
    
    typealias EventType = CourierEvent

    private let performQueue: SerialQueue
    private let persistance: DefaultDatabaseDAO<CourierEvent>
    private let batchProcessor: CourierEventBatchProcessor
    private let batchSizeRegulator: CourierBatchSizeRegulator
    private let networkOptions: ClickstreamNetworkOptions

    private lazy var courierWhitelistedEvents: Set<String> = {
        Set(networkOptions.courierEventTypes.map { $0.lowercased() })
    }()

    init(with batchProcessor: CourierEventBatchProcessor,
         performOnQueue: SerialQueue,
         persistance: DefaultDatabaseDAO<CourierEvent>,
         batchSizeRegulator: CourierBatchSizeRegulator,
         networkOptions: ClickstreamNetworkOptions) {

        self.performQueue = performOnQueue
        self.persistance = persistance
        self.batchProcessor = batchProcessor
        self.batchSizeRegulator = batchSizeRegulator
        self.networkOptions = networkOptions

        start()
    }
    
    /// This method starts the event batch processor.
    private func start() {
        batchProcessor.start()
    }

    /// Determines if an event is able to dispatch via Courier
    /// - Parameter event: Event
    /// - Returns: Boolean flag
    private func isWhitelistedCourierEvent(_ event: CourierEvent) -> Bool {
        let data = event.eventProtoData
        guard let eventType = try? Odpf_Raccoon_Event(serializedBytes: data).type else {
            return false
        }

        if networkOptions.isWebsocketEnabled && courierWhitelistedEvents.contains(eventType) {
            return true
        }
        return networkOptions.isCourierEnabled
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

            guard checkedSelf.isWhitelistedCourierEvent(event) else {
                return
            }
            
            if event.type == Constants.EventType.instant.rawValue {
                _ = checkedSelf.batchProcessor.sendInstantly(event: event)
            } else {
                if event.type != Constants.EventType.p0Event.rawValue {
                    checkedSelf.batchSizeRegulator.observe(event)
                }

                // Transform
                checkedSelf.persistance.insert(event)

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
