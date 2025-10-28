import Foundation


/** The final leg in the EventScheduler block.
    This class is the interface between NetworkManager and the scheduler. Use this to forward requests to the network builder.
 */
final class CourierEventBatchCreator: EventBatchCreator {
    
    private let networkBuilder: NetworkBuildable
    private let performOnQueue: SerialQueue
    
    init(with networkBuilder: NetworkBuildable,
         performOnQueue: SerialQueue) {
        self.networkBuilder = networkBuilder
        self.performOnQueue = performOnQueue
    }
}

extension CourierEventBatchCreator {
    func forward(with events: [Event]) -> Bool {
        if canForward {
            let batch = EventBatch(uuid: UUID().uuidString, events: events)
            networkBuilder.trackBatch(batch, completion: nil)
            
            self.trackHealthEvents(batch: batch, events: events)
            return true
        }
        return false
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
}

// MARK: - Track Clickstream health.
extension CourierEventBatchCreator {
    private func trackHealthEvents(batch: EventBatch, events: [Event]) {
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
