import Foundation

/// A class resposible to split the event based on the type.
final class SharedEventWarehouser: EventWarehouser {
    
    private let performQueue: SerialQueue
    private let eventBatchProcessor: EventBatchProcessor
    private let secondaryEventBatchProcessor: EventBatchProcessor?
    private let persistence: DefaultDatabaseDAO<Event>
    private let batchRegulator: BatchSizeRegulator
    private let secondaryBatchRegulator: BatchSizeRegulator
    private let networkOptions: ClickstreamNetworkOptions

    private lazy var courierWhitelistedEvents: Set<String> = {
        Set(networkOptions.courierEventTypes.map { $0.lowercased() })
    }()

    init(with eventBatchProcessor: EventBatchProcessor,
         secondary secondaryEventBatchProcessor: EventBatchProcessor? = nil,
         performOnQueue: SerialQueue,
         persistence: DefaultDatabaseDAO<Event>,
         batchSizeRegulator: BatchSizeRegulator,
         secondaryBatchSizeRegulator: BatchSizeRegulator,
         networkOptions: ClickstreamNetworkOptions) {

        self.eventBatchProcessor = eventBatchProcessor
        self.secondaryEventBatchProcessor = secondaryEventBatchProcessor
        self.performQueue = performOnQueue
        self.persistence = persistence
        self.batchRegulator = batchSizeRegulator
        self.secondaryBatchRegulator = secondaryBatchSizeRegulator
        self.networkOptions = networkOptions

        start()
    }
    
    /// This method starts the event batch processor.
    private func start() {
        self.eventBatchProcessor.start()
    }

    /// Determines if the event can be dispatch via Courier
    /// - Parameter event: Event
    /// - Returns: Boolean flag
    private func isCourierWhitelistedEvent(_ event: Event) -> Bool {
        let data = event.eventProtoData
        guard let eventType = try? Odpf_Raccoon_Event(serializedBytes: data).type else {
            return false
        }
        return networkOptions.isCourierEnabled && courierWhitelistedEvents.contains(eventType)
    }

    /// Send `instant` event type
    /// - Parameter event: Determines the event processor action given condition flag
    private func sendInstantEvent(_ event: Event) {
        if isCourierWhitelistedEvent(event) {
            _ = secondaryEventBatchProcessor?.sendInstantly(event: event)
        } else {
            _ = eventBatchProcessor.sendInstantly(event: event)
        }
    }

    /// Send `p0Event` event type
    /// - Parameter event: Determines the event processor action given condition flag
    private func sendP0Event(_ event: Event) {
        if isCourierWhitelistedEvent(event) {
            secondaryEventBatchProcessor?.sendP0(classificationType: event.type)
        } else {
            eventBatchProcessor.sendP0(classificationType: event.type)
        }
    }

    private func observeBatchRegulator(_ event: Event) {
        if isCourierWhitelistedEvent(event) {
            secondaryBatchRegulator.observe(event)
        } else {
            batchRegulator.observe(event)
        }
    }
}

extension SharedEventWarehouser {
    
    func store(_ event: Event) {
        performQueue.async { [weak self] in guard let checkedSelf = self else { return }
            if event.type == Constants.EventType.instant.rawValue {
                checkedSelf.sendInstantEvent(event)
            } else {
                if event.type != Constants.EventType.p0Event.rawValue {
                    checkedSelf.observeBatchRegulator(event)
                }
                checkedSelf.persistence.insert(event)
                if event.type == Constants.EventType.p0Event.rawValue {
                    checkedSelf.sendP0Event(event)
                }
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
    }
    
    func stop() {
        eventBatchProcessor.stop()
        secondaryEventBatchProcessor?.stop()
    }
}
