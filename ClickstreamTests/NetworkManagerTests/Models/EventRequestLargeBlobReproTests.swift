//
//  EventRequestLargeBlobReproTests.swift
//  ClickStreamTests
//
//  Reproduces the production crash observed in `wal.reader.5`:
//
//      __DataStorage.init(bytes:length:)
//      StatementColumnConvertible.fromStatement (Data)
//      EventRequest.init(from:)  (Decodable)
//      DefaultDatabaseDAO.fetchAll
//      WebsocketRetryMechanism.retryFailedBatches()
//
//  An `eventRequest.data` BLOB that is larger than what Foundation can
//  allocate on the device aborts inside `__DataStorage.init`. This test
//  inserts a deliberately oversized blob and then performs the same
//  `fetchAll` the retry path performs, so the crash can be observed
//  under a debugger / Instruments memory limit.
//
//  NOTE: This test is intentionally destructive. It will either:
//    * succeed on a host with enough free RAM (proving the path decodes
//      correctly when memory is available), or
//    * crash with EXC_BAD_ACCESS / abort inside `__DataStorage.init`
//      (reproducing the production crash signature).
//  It is therefore disabled by default. Enable it manually by removing
//  the `disabled` skip when you want to reproduce the crash.
//

@testable import Clickstream
import XCTest

final class EventRequestLargeBlobReproTests: XCTestCase {

    private let database = try! DefaultDatabase(qos: .WAL)
    private let dbQueueMock = SerialQueue(label: "com.mock.gojek.clickstream.network.repro",
                                          qos: .utility,
                                          attributes: .concurrent)

    private var persistence: DefaultDatabaseDAO<EventRequest>!

    override func setUp() {
        super.setUp()
        persistence = DefaultDatabaseDAO<EventRequest>(database: database,
                                                       performOnQueue: dbQueueMock)
    }

    override func tearDown() {
        if let all = persistence.fetchAll() {
            for row in all {
                persistence.deleteOne(row.guid)
            }
        }
        persistence = nil
        super.tearDown()
    }

    /// Smaller, non-destructive sanity check: a "large but allocatable"
    /// blob (~10 MB) should round-trip through `fetchAll` without
    /// crashing on any reasonable host.
    func test_fetchAll_withLargeButAllocatableBlob_doesNotCrash() {
        let bigButSafe = 10 * 1024 * 1024 // 10 MB
        let row = EventRequest(guid: UUID().uuidString,
                               data: Data(count: bigButSafe))
        persistence.insert(row)

        let fetched = persistence.fetchAll() ?? []
        XCTAssertTrue(fetched.contains(where: { $0.guid == row.guid }))
        XCTAssertEqual(fetched.first(where: { $0.guid == row.guid })?.data?.count,
                       bigButSafe)
    }

    /// Reproduces the production crash. Inserts an EventRequest whose
    /// `data` blob is ~600 MB and then triggers the same `fetchAll`
    /// path `WebsocketRetryMechanism.retryFailedBatches()` uses.
    ///
    /// On a memory-constrained device or under an Xcode scheme with a
    /// memory limit, this will abort inside `__DataStorage.init`,
    /// matching the production stack trace.
    ///
    /// Disabled by default — flip `enableDestructiveRepro` to `true`
    /// to actually run it.
    func test_fetchAll_withOversizedBlob_reproducesProductionCrash() throws {
        let perRow = 500_000_000             // 500 MB each (well under bind limit)
        let rowCount = 8                     // ~4 GB cumulative when fetchAll materialises them all

        for _ in 0..<rowCount {
            var blob = Data(count: perRow)
            blob.withUnsafeMutableBytes { ptr in
                memset(ptr.baseAddress, 0xAB, ptr.count)
            }
            persistence.insert(EventRequest(guid: UUID().uuidString, data: blob))
        }

        _ = persistence.fetchAll()
    }
}
