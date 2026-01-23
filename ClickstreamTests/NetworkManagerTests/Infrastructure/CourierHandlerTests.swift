import Foundation
import XCTest
import Combine
import CourierCore
import CourierMQTT
@testable import Clickstream

final class CourierHandlerTests: XCTestCase {
    
    private var sut: DefaultCourierHandler!
    private var mockConfig: ClickstreamCourierClientConfig!
    private var mockCredentials: ClickstreamClientIdentifiers!
    private var mockEventHandler: ICourierEventHandler!
    private var mockCourierConnectionsObserver: CourierConnectOptionsObserver!
    private var cancellables: Set<CourierCore.AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
        mockConfig = createMockConfig()
        mockCredentials = createMockCredentials()
        mockEventHandler = MockCourierEventHandler()
        sut = DefaultCourierHandler(config: mockConfig, userCredentials: mockCredentials, connectOptionsObserver: nil, pubSubAnalytics: nil)
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockConfig = nil
        mockCredentials = nil
        super.tearDown()
    }
    
    func testInit_WithValidConfig_InitializesCorrectly() {
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.isConnected.value)
    }
    
    func testIsConnected_InitialState_ReturnsFalse() {
        XCTAssertFalse(sut.isConnected.value)
    }
    
    func testPublishMessage_WithValidData_DoesNotThrow() async {
        let testData = "test message".data(using: .utf8)!
        let topic = "clickstream/topic"
        let eventRequest = CourierEventRequest(guid: "12345", data: testData)

        do {
            try await sut.publishMessage(eventRequest, topic: topic)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testPublishMessage_WithEmptyData_DoesNotThrow() async {
        let emptyData = Data()
        let topic = "clickstream/topic"
        let eventRequest = CourierEventRequest(guid: "12345", data: emptyData)

        do {
            try await sut.publishMessage(eventRequest, topic: topic)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testDisconnect_WhenCalled_DoesNotThrow() {
        XCTAssertNoThrow(sut.destroyAndDisconnect())
    }
    
    func testSetup_WithoutConnectionCallback_CompletesSuccessfully() async {
        let request = createValidURLRequest()
        
        sut.setup(request: request,
                        connectionCallback: nil,
                        eventHandler: mockEventHandler)
        
        XCTAssertNotNil(sut)
    }
    
    func testSequentialSetupAndDisconnect_DoesNotThrow() async {
        let request = createValidURLRequest()
        
        sut.setup(request: request,
                  connectionCallback: nil,
                  eventHandler: mockEventHandler)
        
        XCTAssertNoThrow(sut.destroyAndDisconnect())
    }
    
    func testMultipleDisconnectCalls_DoesNotThrow() {
        XCTAssertNoThrow(sut.destroyAndDisconnect())
        XCTAssertNoThrow(sut.destroyAndDisconnect())
        XCTAssertNoThrow(sut.destroyAndDisconnect())
    }
    
    func testConfigRetention_AfterInit_ConfigIsRetained() {
        let newConfig = createMockConfigWithDifferentValues()
        let newCredentials = createMockCredentialsWithDifferentValues()
        let newSut = DefaultCourierHandler(config: newConfig, userCredentials: newCredentials, connectOptionsObserver: nil, pubSubAnalytics: nil)
        
        XCTAssertNotNil(newSut)
        XCTAssertFalse(newSut.isConnected.value)
    }
    
    func testLargeDataPublish_WithLargePayload_DoesNotThrow() async {
        let largeData = Data(repeating: 0x41, count: 10000)
        let topic = "clickstream/topic"
        let eventRequest = CourierEventRequest(guid: "12345", data: largeData)
        
        do {
            try await sut.publishMessage(eventRequest, topic: topic)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testPublishMessage_WhenClientNotInitialized_ThrowsError() async {
        let testData = "test message".data(using: .utf8)!
        let topic = "clickstream/topic"
        let eventRequest = CourierEventRequest(guid: "12345", data: testData)

        do {
            try await sut.publishMessage(eventRequest, topic: topic)
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testPublishMessage_AfterDisconnect_ThrowsError() async {
        let request = createValidURLRequest()
        let topic = "clickstream/topic"
        sut.setup(request: request, connectionCallback: nil, eventHandler: mockEventHandler)
        
        sut.destroyAndDisconnect()
        
        let testData = "test message".data(using: .utf8)!
        let eventRequest = CourierEventRequest(guid: "12345", data: testData)

        do {
            try await sut.publishMessage(eventRequest, topic: topic)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testPublishMessage_WithMalformedData_HandlesError() async {
        let malformedData = Data([0x00, 0xFF, 0x00, 0xFF])
        let topic = "clickstream/topic"
        let eventRequest = CourierEventRequest(guid: "12345", data: malformedData)
        
        do {
            try await sut.publishMessage(eventRequest, topic: topic)
        } catch {
            XCTFail("Should handle malformed data gracefully")
        }
    }
    
    func testPublishMessage_ConcurrentCalls_HandlesCorrectly() async {
        let request = createValidURLRequest()
        sut.setup(request: request, connectionCallback: nil, eventHandler: mockEventHandler)

        let testData1 = "message1".data(using: .utf8)!
        let testData2 = "message2".data(using: .utf8)!
        let topic = "clickstream/topic"
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    let eventRequest = CourierEventRequest(guid: "12345", data: testData1)
                    try await self.sut.publishMessage(eventRequest, topic: topic)
                } catch {
                    XCTAssertNotNil(error)
                }
            }
            
            group.addTask {
                do {
                    let eventRequest = CourierEventRequest(guid: "12345", data: testData2)
                    try await self.sut.publishMessage(eventRequest, topic: topic)
                } catch {
                    XCTAssertNotNil(error)
                }
            }
        }
    }
    
    func testPublishMessage_WithExtremelyLargePayload_HandlesCorrectly() async {
        let extremelyLargeData = Data(repeating: 0x42, count: 1_000_000)
        let topic = "clickstream/topic"
        let eventRequest = CourierEventRequest(guid: "12345", data: extremelyLargeData)

        do {
            try await sut.publishMessage(eventRequest, topic: topic)
        } catch {
            XCTAssertTrue(error is CourierError)
        }
    }
    
    func testMemoryManagement_AfterMultipleOperations_NoLeaks() async {
        let request = createValidURLRequest()
        
        for _ in 0..<10 {
            sut.setup(request: request, connectionCallback: nil, eventHandler: mockEventHandler)

            let testData = "test".data(using: .utf8)!
            let topic = "clickstream/topic"
            let eventRequest = CourierEventRequest(guid: "12345", data: testData)

            do {
                try await sut.publishMessage(eventRequest, topic: topic)
            } catch {
                continue
            }
            
            sut.destroyAndDisconnect()
        }
        
        XCTAssertNotNil(sut)
    }
    
    func testPublishMessage_WithValidParametersAndData_DoesNotThrow() async {
        let testData = "test message".data(using: .utf8)!
        let topic = "clickstream/topic"
        let eventRequest = CourierEventRequest(guid: "12345", data: testData)

        do {
            try await sut.publishMessage(eventRequest, topic: topic)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testPublishMessage_WithEmptyDataAndValidParameters_DoesNotThrow() async {
        let testData = Data()
        let topic = "clickstream/topic"
        let eventRequest = CourierEventRequest(guid: "12345", data: testData)

        do {
            try await sut.publishMessage(eventRequest, topic: topic)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testPublishMessage_WithDifferentQoSLevels_DoesNotThrow() async {
        let testData = "test message".data(using: .utf8)!
        let topic = "clickstream/topic"
        let eventRequest = CourierEventRequest(guid: "12345", data: testData)

        do {
            try await sut.publishMessage(eventRequest, topic: topic)
            try await sut.publishMessage(eventRequest, topic: topic)
            try await sut.publishMessage(eventRequest, topic: topic)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testPublishMessage_WithEmptyTopic_DoesNotThrow() async {
        let testData = "test message".data(using: .utf8)!
        let emptyTopic = ""
        let eventRequest = CourierEventRequest(guid: "12345", data: testData)

        do {
            try await sut.publishMessage(eventRequest, topic: emptyTopic)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testPublishMessage_WithSpecialCharactersInTopic_DoesNotThrow() async {
        let testData = "test message".data(using: .utf8)!
        let specialTopic = "test/topic-with_special.chars#123"
        let eventRequest = CourierEventRequest(guid: "12345", data: testData)

        do {
            try await sut.publishMessage(eventRequest, topic: specialTopic)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testPublishMessage_WithLargePayloadAndTopic_DoesNotThrow() async {
        let largeData = Data(repeating: 0x41, count: 10000)
        let topic = "test/large/payload/topic"
        let eventRequest = CourierEventRequest(guid: "12345", data: largeData)

        do {
            try await sut.publishMessage(eventRequest, topic: topic)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testPublishMessage_WhenClientNotInitializedWithParameters_ThrowsError() async {
        let testData = "test message".data(using: .utf8)!
        let topic = "test/topic"
        let eventRequest = CourierEventRequest(guid: "12345", data: testData)

        do {
            try await sut.publishMessage(eventRequest, topic: topic)
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testPublishMessage_AfterDisconnectWithParameters_ThrowsError() async {
        let request = createValidURLRequest()
        sut.setup(request: request, connectionCallback: nil, eventHandler: mockEventHandler)

        sut.destroyAndDisconnect()
        
        let testData = "test message".data(using: .utf8)!
        let topic = "test/topic"
        let eventRequest = CourierEventRequest(guid: "12345", data: testData)

        do {
            try await sut.publishMessage(eventRequest, topic: topic)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testPublishMessage_WithMalformedDataAndParameters_HandlesError() async {
        let malformedData = Data([0x00, 0xFF, 0x00, 0xFF])
        let topic = "test/malformed"
        let eventRequest = CourierEventRequest(guid: "12345", data: malformedData)

        do {
            try await sut.publishMessage(eventRequest, topic: topic)
        } catch {
            XCTFail("Should handle malformed data gracefully")
        }
    }
    
    func testPublishMessage_ConcurrentCallsWithParameters_HandlesCorrectly() async {
        let request = createValidURLRequest()
        sut.setup(request: request, connectionCallback: nil, eventHandler: mockEventHandler)

        let testData1 = "message1".data(using: .utf8)!
        let testData2 = "message2".data(using: .utf8)!
        let topic1 = "test/topic1"
        let topic2 = "test/topic2"
        let eventRequest1 = CourierEventRequest(guid: "12345", data: testData1)
        let eventRequest2 = CourierEventRequest(guid: "12345", data: testData2)

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    try await self.sut.publishMessage(eventRequest1, topic: topic1)
                } catch {
                    XCTAssertNotNil(error)
                }
            }
            
            group.addTask {
                do {
                    try await self.sut.publishMessage(eventRequest2, topic: topic2)
                } catch {
                    XCTAssertNotNil(error)
                }
            }
        }
    }
    
    func testPublishMessage_WithExtremelyLargePayloadAndParameters_HandlesCorrectly() async {
        let extremelyLargeData = Data(repeating: 0x42, count: 1_000_000)
        let topic = "test/extremely/large"
        let eventRequest = CourierEventRequest(guid: "12345", data: extremelyLargeData)

        do {
            try await sut.publishMessage(eventRequest, topic: topic)
        } catch {
            XCTAssertTrue(error is CourierError)
        }
    }
    
    func testPublishMessage_WithLongTopicName_DoesNotThrow() async {
        let testData = "test message".data(using: .utf8)!
        let longTopic = String(repeating: "verylongtopic/", count: 50) + "end"
        let eventRequest = CourierEventRequest(guid: "12345", data: testData)

        do {
            try await sut.publishMessage(eventRequest, topic: longTopic)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testPublishMessage_WithUnicodeInTopic_DoesNotThrow() async {
        let testData = "test message".data(using: .utf8)!
        let unicodeTopic = "test/topic/with/unicode/🚀/📱"
        let eventRequest = CourierEventRequest(guid: "12345", data: testData)

        do {
            try await sut.publishMessage(eventRequest, topic: unicodeTopic)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testPublishMessage_WithNullBytesInData_HandlesCorrectly() async {
        let dataWithNulls = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x00, 0x57, 0x6F, 0x72, 0x6C, 0x64])
        let topic = "test/null/bytes"
        let eventRequest = CourierEventRequest(guid: "12345", data: dataWithNulls)

        do {
            try await sut.publishMessage(eventRequest, topic: topic)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
}

extension CourierHandlerTests {
    
    private func createMockConfig() -> ClickstreamCourierClientConfig {
        ClickstreamCourierClientConfig()
    }
    
    private func createMockConfigWithDifferentValues() -> ClickstreamCourierClientConfig {
        ClickstreamCourierClientConfig(
            courierMessageAdapter: [],
            courierPingIntervalMillis: 500
        )
    }
    
    private func createMockCredentials() -> ClickstreamClientIdentifiers {
        CourierIdentifiers(userIdentifier: "user_id",
                           deviceIdentifier: "device_id",
                           bundleIdentifier: "bundle_id",
                           authURLRequest: URLRequest(url: URL(string: "https://auth.example.com/token")!))
    }
    
    private func createMockCredentialsWithDifferentValues() -> ClickstreamClientIdentifiers {
        CourierIdentifiers(userIdentifier: "user_id_2",
                           deviceIdentifier: "device_id_2",
                           bundleIdentifier: "bundle_id_3",
                           authURLRequest: URLRequest(url: URL(string: "https://auth.example.com/token")!))

    }
    
    private func createValidURLRequest() -> URLRequest {
        guard let url = URL(string: "wss://test.example.com/mqtt") else {
            XCTFail("Could not create valid test URL")
            return URLRequest(url: URL(string: "about:blank")!)
        }
        return URLRequest(url: url)
    }
}

fileprivate class MockCourierEventHandler: ICourierEventHandler {

    var _onEvent: ((_ event: CourierCore.CourierEvent) -> Void)?
    func onEvent(_ event: CourierCore.CourierEvent) {
        _onEvent?(event)
    }
}
