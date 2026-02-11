import Foundation


/** The final leg in the EventScheduler block.
    This class is the interface between NetworkManager and the scheduler. Use this to forward requests to the network builder.
 */
final class CourierEventBatchCreator: EventBatchCreator {
    typealias EventType = CourierEvent
    typealias BatchType = CourierEventBatch
    
    private let networkBuilder: any NetworkBuildable
    private let performOnQueue: SerialQueue
    private let healthTrackingConfig: ClickstreamCourierHealthConfig
    
    init(with networkBuilder: any NetworkBuildable,
         performOnQueue: SerialQueue,
         healthTrackingConfig: ClickstreamCourierHealthConfig) {
        self.networkBuilder = networkBuilder
        self.performOnQueue = performOnQueue
        self.healthTrackingConfig = healthTrackingConfig
    }
    
    func forward(with events: [CourierEvent]) -> Bool {        
        let batch = CourierEventBatch(uuid: UUID().uuidString, events: events)
        networkBuilder.trackBatch(batch, completion: nil)
        
        if isCSHealthTrackingEnabled {
            self.trackHealthEvents(batch: batch, events: events)
        }

        return true
    }
    
    func requestForConnection() {
        networkBuilder.openConnectionForcefully()
    }
    
    func stop() {
        networkBuilder.stopTracking()
    }
}

extension CourierEventBatchCreator {
    var canForward: Bool {
        networkBuilder.isAvailable
    }
    
    var isCSHealthTrackingEnabled: Bool {
        healthTrackingConfig.csTrackingHealthEventsEnabled
    }
}

// MARK: - Track Clickstream health.
extension CourierEventBatchCreator {
    private func trackHealthEvents(batch: CourierEventBatch, events: [CourierEvent]) {
        #if TRACKER_ENABLED
        // We are checking only first event's type since batches are created on the basis of evemt priority i.e. realTime, healthEvent etc.
        if events.first?.type != TrackerConstant.HealthEventType && events.first?.type != Constants.EventType.instant.rawValue {
            let eventGUIDs = batch.events.map { $0.guid }
            let eventGUIDString = "\(eventGUIDs.joined(separator: ", "))"
            let batchCreatedEvent = HealthAnalysisEvent(eventName: .ClickstreamEventBatchCreated,
                                                        events: eventGUIDString,
                                                        eventBatchGUID: batch.uuid)
            Tracker.sharedInstance?.record(event: batchCreatedEvent)
        }
        #endif
    }
}
