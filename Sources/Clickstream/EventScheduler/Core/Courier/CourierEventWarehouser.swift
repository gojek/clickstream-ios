import Foundation

/// A class resposible to split the event based on the type.
final class CourierEventWarehouser: EventWarehouser {
    
    typealias EventType = CourierEvent

    private let performQueue: SerialQueue
    private let persistence: DefaultDatabaseDAO<CourierEvent>
    private let batchProcessor: CourierEventBatchProcessor
    private let batchSizeRegulator: CourierBatchSizeRegulator
    private let networkOptions: ClickstreamNetworkOptions
    private let eventCleanupManager: CourierEventCleanupManager?
    private let classificationCoordinator: CourierClassificationCoordinator?

    init(with batchProcessor: CourierEventBatchProcessor,
         performOnQueue: SerialQueue,
         persistence: DefaultDatabaseDAO<CourierEvent>,
         batchSizeRegulator: CourierBatchSizeRegulator,
         networkOptions: ClickstreamNetworkOptions,
         eventCleanupManager: CourierEventCleanupManager? = nil,
         classificationCoordinator: CourierClassificationCoordinator? = nil) {

        self.performQueue = performOnQueue
        self.persistence = persistence
        self.batchProcessor = batchProcessor
        self.batchSizeRegulator = batchSizeRegulator
        self.networkOptions = networkOptions
        self.eventCleanupManager = eventCleanupManager
        self.classificationCoordinator = classificationCoordinator
        
        start()
        
        eventCleanupManager?.cleanUpExpiredEvents()
    }
    
    /// This method starts the event batch processor.
    ///
    /// When classification is enabled, the classification coordinator drives scheduling instead of
    /// the legacy batch processor (which is left dormant to avoid double-draining persistence).
    private func start() {
        if let classificationCoordinator {
            classificationCoordinator.start()
        } else {
            batchProcessor.start()
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
        let healthEvent = HealthAnalysisEvent(eventName: .Courier_ClickstreamEventCached,
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

            if let coordinator = checkedSelf.classificationCoordinator {
                checkedSelf.store(event, using: coordinator)
                return
            }

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

    /// Routes an event through the classification coordinator while preserving the instant and
    /// P0 fast paths from the legacy flow.
    private func store(_ event: CourierEvent, using coordinator: CourierClassificationCoordinator) {
        if event.type == Constants.EventType.instant.rawValue {
            coordinator.sendInstantly(event)
            return
        }

        if event.type == Constants.EventType.p0Event.rawValue {
            persistence.insert(event)
            coordinator.sendP0(classificationType: event.type)
            trackEventVisualizer(event)
            return
        }

        batchSizeRegulator.observe(event)
        coordinator.store(event, classificationId: event.type)
        trackEventVisualizer(event)
    }
    
    func stop() {
        if let classificationCoordinator {
            classificationCoordinator.stop()
        } else {
            batchProcessor.stop()
        }
    }
}
