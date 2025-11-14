import Foundation

/// A class resposible to split the event based on the type.
final class SharedEventWarehouser: EventWarehouser {
    
    private let performQueue: SerialQueue
    private let socketPersistance: DefaultDatabaseDAO<Event>
    private let courierPersistance: DefaultDatabaseDAO<CourierEvent>

    private let socketBatchProcessor: DefaultEventBatchProcessor
    private let courierBatchProcessor: CourierEventBatchProcessor?

    private let socketBatchSizeRegulator: BatchSizeRegulator
    private let courierBatchSizeRegulator: BatchSizeRegulator

    private let networkOptions: ClickstreamNetworkOptions

    private lazy var courierWhitelistedEvents: Set<String> = {
        Set(networkOptions.courierEventTypes.map { $0.lowercased() })
    }()

    init(performOnQueue: SerialQueue,
         socketPersistance: DefaultDatabaseDAO<Event>,
         courierPersistance: DefaultDatabaseDAO<CourierEvent>,
         socketBatchProcessor: DefaultEventBatchProcessor,
         courierBatchProcessor: CourierEventBatchProcessor? = nil,
         socketBatchSizeRegulator: BatchSizeRegulator,
         courierBatchSizeRegulator: BatchSizeRegulator,
         networkOptions: ClickstreamNetworkOptions) {

        self.performQueue = performOnQueue
        self.socketPersistance = socketPersistance
        self.courierPersistance = courierPersistance
        self.socketBatchProcessor = socketBatchProcessor
        self.courierBatchProcessor = courierBatchProcessor
        self.socketBatchSizeRegulator = socketBatchSizeRegulator
        self.courierBatchSizeRegulator = courierBatchSizeRegulator
        self.networkOptions = networkOptions

        start()
    }
    
    /// This method starts the event batch processor.
    private func start() {
        socketBatchProcessor.start()
        courierBatchProcessor?.start()
    }

    /// Handle websocket-enabled event
    /// - Parameter event: Event
    private func handleSocketEvent(_ event: Event) {
        if event.type == Constants.EventType.instant.rawValue {
            _ = socketBatchProcessor.sendInstantly(event: event)
        } else {
            if event.type != Constants.EventType.p0Event.rawValue {
                socketBatchSizeRegulator.observe(event)
            }

            socketPersistance.insert(event)

            if event.type == Constants.EventType.p0Event.rawValue {
                socketBatchProcessor.sendP0(classificationType: event.type)
            }

            trackEventVisualizer(event)
        }
    }

    /// Handle courier-enabled event
    /// - Parameter event: Event
    private func handleCourierEvent(_ event: Event) {
        let courierEvent = CourierEvent.initialise(from: event)

        if event.type == Constants.EventType.instant.rawValue {
            _ = courierBatchProcessor?.sendInstantly(event: courierEvent)
        } else {
            if event.type != Constants.EventType.p0Event.rawValue {
                courierBatchSizeRegulator.observe(event)
            }

            // Transform
            courierPersistance.insert(courierEvent)

            if event.type == Constants.EventType.p0Event.rawValue {
                courierBatchProcessor?.sendP0(classificationType: courierEvent.type)
            }

            trackEventVisualizer(courierEvent)
        }
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

    /// Determines if an event is able to dispatch via Courier
    /// - Parameter event: Event
    /// - Returns: Boolean flag
    private func isWhitelistedCourierEvent(_ event: Event) -> Bool {
        guard networkOptions.isCourierEnabled else {
            return false
        }

        let data = event.eventProtoData
        guard let eventType = try? Odpf_Raccoon_Event(serializedBytes: data).type else {
            return false
        }

        return courierWhitelistedEvents.contains(eventType)
    }
}

extension SharedEventWarehouser {
    
    func store(_ event: Event) {
        performQueue.async { [weak self] in
            guard let checkedSelf = self else { return }
            checkedSelf.handleSocketEvent(event)

            if checkedSelf.isWhitelistedCourierEvent(event) {
                checkedSelf.handleCourierEvent(event)
            }
        }
    }
    
    func stop() {
        socketBatchProcessor.stop()
        courierBatchProcessor?.stop()
    }
}
