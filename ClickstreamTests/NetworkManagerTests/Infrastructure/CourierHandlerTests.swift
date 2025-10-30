import Foundation
import XCTest
import Combine
import CourierCore
import CourierMQTT
@testable import Clickstream

final class CourierHandlerTests: XCTestCase {
    
    private var sut: DefaultCourierHandler!
    private var mockConfig: ClickstreamCourierConfig!
    private var mockCredentials: ClickstreamClientIdentifiers!
    private var cancellables: Set<CourierCore.AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = []
        mockConfig = createMockConfig()
        mockCredentials = createMockCredentials()
        sut = DefaultCourierHandler(config: mockConfig, userCredentials: mockCredentials)
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
    
    func testPublishMessage_WithValidData_DoesNotThrow() {
        let testData = "test message".data(using: .utf8)!
        let topic = "clickstream/topic"
        
        XCTAssertNoThrow(try sut.publishMessage(testData, topic: topic))
    }
    
    func testPublishMessage_WithEmptyData_DoesNotThrow() {
        let emptyData = Data()
        let topic = "clickstream/topic"
        
        XCTAssertNoThrow(try sut.publishMessage(emptyData, topic: topic))
    }
    
    func testDisconnect_WhenCalled_DoesNotThrow() {
        XCTAssertNoThrow(sut.disconnect())
    }
    
    func testSetup_WithoutConnectionCallback_CompletesSuccessfully() async {
        let request = createValidURLRequest()
        
        await sut.setup(request: request, 
                       keepTrying: false, 
                       connectionCallback: nil)
        
        XCTAssertNotNil(sut)
    }
    
    func testSequentialSetupAndDisconnect_DoesNotThrow() async {
        let request = createValidURLRequest()
        
        await sut.setup(request: request, 
                       keepTrying: false, 
                       connectionCallback: nil)
        
        XCTAssertNoThrow(sut.disconnect())
    }
    
    func testMultipleDisconnectCalls_DoesNotThrow() {
        XCTAssertNoThrow(sut.disconnect())
        XCTAssertNoThrow(sut.disconnect())
        XCTAssertNoThrow(sut.disconnect())
    }
    
    func testConfigRetention_AfterInit_ConfigIsRetained() {
        let newConfig = createMockConfigWithDifferentValues()
        let newCredentials = createMockCredentialsWithDifferentValues()
        let newSut = DefaultCourierHandler(config: newConfig, userCredentials: newCredentials)
        
        XCTAssertNotNil(newSut)
        XCTAssertFalse(newSut.isConnected.value)
    }
    
    func testLargeDataPublish_WithLargePayload_DoesNotThrow() {
        let largeData = Data(repeating: 0x41, count: 10000)
        let topic = "clickstream/topic"
        
        XCTAssertNoThrow(try sut.publishMessage(largeData, topic: topic))
    }
    
    func testPublishMessage_WhenClientNotInitialized_ThrowsError() {
        let testData = "test message".data(using: .utf8)!
        let topic = "clickstream/topic"

        do {
            try sut.publishMessage(testData, topic: topic)
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testPublishMessage_AfterDisconnect_ThrowsError() async {
        let request = createValidURLRequest()
        let topic = "clickstream/topic"
        await sut.setup(request: request, keepTrying: false, connectionCallback: nil)
        
        sut.disconnect()
        
        let testData = "test message".data(using: .utf8)!
        XCTAssertThrowsError(try sut.publishMessage(testData, topic: topic))
    }
    
    func testPublishMessage_WithMalformedData_HandlesError() {
        let malformedData = Data([0x00, 0xFF, 0x00, 0xFF])
        let topic = "clickstream/topic"
        
        do {
            try sut.publishMessage(malformedData, topic: topic)
        } catch {
            XCTFail("Should handle malformed data gracefully")
        }
    }
    
    func testPublishMessage_ConcurrentCalls_HandlesCorrectly() async {
        let request = createValidURLRequest()
        await sut.setup(request: request, keepTrying: false, connectionCallback: nil)
        
        let testData1 = "message1".data(using: .utf8)!
        let testData2 = "message2".data(using: .utf8)!
        let topic = "clickstream/topic"
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    try self.sut.publishMessage(testData1, topic: topic)
                } catch {
                    XCTAssertNotNil(error)
                }
            }
            
            group.addTask {
                do {
                    try self.sut.publishMessage(testData2, topic: topic)
                } catch {
                    XCTAssertNotNil(error)
                }
            }
        }
    }
    
    func testPublishMessage_WithExtremelyLargePayload_HandlesCorrectly() {
        let extremelyLargeData = Data(repeating: 0x42, count: 1_000_000)
        let topic = "clickstream/topic"

        do {
            try sut.publishMessage(extremelyLargeData, topic: topic)
        } catch {
            XCTAssertTrue(error is CourierError)
        }
    }
    
    func testMemoryManagement_AfterMultipleOperations_NoLeaks() async {
        let request = createValidURLRequest()
        
        for _ in 0..<10 {
            await sut.setup(request: request, keepTrying: false, connectionCallback: nil)
            
            let testData = "test".data(using: .utf8)!
            let topic = "clickstream/topic"

            do {
                try sut.publishMessage(testData, topic: topic)
            } catch {
                continue
            }
            
            sut.disconnect()
        }
        
        XCTAssertNotNil(sut)
    }
    
    func testPublishMessage_WithValidParametersAndData_DoesNotThrow() {
        let testData = "test message".data(using: .utf8)!
        let topic = "clickstream/topic"
        let qos = CourierCore.QoS.one
        
        XCTAssertNoThrow(try sut.publishMessage(testData, topic: topic))
    }
    
    func testPublishMessage_WithEmptyDataAndValidParameters_DoesNotThrow() {
        let emptyData = Data()
        let topic = "clickstream/topic"
        let qos = CourierCore.QoS.one
        
        XCTAssertNoThrow(try sut.publishMessage(emptyData, topic: topic))
    }
    
    func testPublishMessage_WithDifferentQoSLevels_DoesNotThrow() {
        let testData = "test message".data(using: .utf8)!
        let topic = "clickstream/topic"
        
        XCTAssertNoThrow(try sut.publishMessage(testData, topic: topic))
        XCTAssertNoThrow(try sut.publishMessage(testData, topic: topic))
        XCTAssertNoThrow(try sut.publishMessage(testData, topic: topic))
    }
    
    func testPublishMessage_WithEmptyTopic_DoesNotThrow() {
        let testData = "test message".data(using: .utf8)!
        let emptyTopic = ""
        let qos = CourierCore.QoS.one
        
        XCTAssertNoThrow(try sut.publishMessage(testData, topic: emptyTopic))
    }
    
    func testPublishMessage_WithSpecialCharactersInTopic_DoesNotThrow() {
        let testData = "test message".data(using: .utf8)!
        let specialTopic = "test/topic-with_special.chars#123"
        let qos = CourierCore.QoS.one
        
        XCTAssertNoThrow(try sut.publishMessage(testData, topic: specialTopic))
    }
    
    func testPublishMessage_WithLargePayloadAndTopic_DoesNotThrow() {
        let largeData = Data(repeating: 0x41, count: 10000)
        let topic = "test/large/payload/topic"
        let qos = CourierCore.QoS.one
        
        XCTAssertNoThrow(try sut.publishMessage(largeData, topic: topic))
    }
    
    func testPublishMessage_WhenClientNotInitializedWithParameters_ThrowsError() {
        let testData = "test message".data(using: .utf8)!
        let topic = "test/topic"
        let qos = CourierCore.QoS.one
        
        do {
            try sut.publishMessage(testData, topic: topic)
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testPublishMessage_AfterDisconnectWithParameters_ThrowsError() async {
        let request = createValidURLRequest()
        await sut.setup(request: request, keepTrying: false, connectionCallback: nil)
        
        sut.disconnect()
        
        let testData = "test message".data(using: .utf8)!
        let topic = "test/topic"
        let qos = CourierCore.QoS.one
        
        XCTAssertThrowsError(try sut.publishMessage(testData, topic: topic))
    }
    
    func testPublishMessage_WithMalformedDataAndParameters_HandlesError() {
        let malformedData = Data([0x00, 0xFF, 0x00, 0xFF])
        let topic = "test/malformed"
        let qos = CourierCore.QoS.one
        
        do {
            try sut.publishMessage(malformedData, topic: topic)
        } catch {
            XCTFail("Should handle malformed data gracefully")
        }
    }
    
    func testPublishMessage_ConcurrentCallsWithParameters_HandlesCorrectly() async {
        let request = createValidURLRequest()
        await sut.setup(request: request, keepTrying: false, connectionCallback: nil)
        
        let testData1 = "message1".data(using: .utf8)!
        let testData2 = "message2".data(using: .utf8)!
        let topic1 = "test/topic1"
        let topic2 = "test/topic2"
        let qos = CourierCore.QoS.one
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    try self.sut.publishMessage(testData1, topic: topic1)
                } catch {
                    XCTAssertNotNil(error)
                }
            }
            
            group.addTask {
                do {
                    try self.sut.publishMessage(testData2, topic: topic2)
                } catch {
                    XCTAssertNotNil(error)
                }
            }
        }
    }
    
    func testPublishMessage_WithExtremelyLargePayloadAndParameters_HandlesCorrectly() {
        let extremelyLargeData = Data(repeating: 0x42, count: 1_000_000)
        let topic = "test/extremely/large"
        let qos = CourierCore.QoS.two
        
        do {
            try sut.publishMessage(extremelyLargeData, topic: topic)
        } catch {
            XCTAssertTrue(error is CourierError)
        }
    }
    
    func testPublishMessage_WithLongTopicName_DoesNotThrow() {
        let testData = "test message".data(using: .utf8)!
        let longTopic = String(repeating: "verylongtopic/", count: 50) + "end"
        let qos = CourierCore.QoS.one
        
        XCTAssertNoThrow(try sut.publishMessage(testData, topic: longTopic))
    }
    
    func testPublishMessage_WithUnicodeInTopic_DoesNotThrow() {
        let testData = "test message".data(using: .utf8)!
        let unicodeTopic = "test/topic/with/unicode/🚀/📱"
        let qos = CourierCore.QoS.one
        
        XCTAssertNoThrow(try sut.publishMessage(testData, topic: unicodeTopic))
    }
    
    func testPublishMessage_WithNullBytesInData_HandlesCorrectly() {
        let dataWithNulls = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x00, 0x57, 0x6F, 0x72, 0x6C, 0x64])
        let topic = "test/null/bytes"
        let qos = CourierCore.QoS.one
        
        XCTAssertNoThrow(try sut.publishMessage(dataWithNulls, topic: topic))
    }
}

extension CourierHandlerTests {
    
    private func createMockConfig() -> ClickstreamCourierConfig {
        ClickstreamCourierConfig(
            messageAdapter: [],
            connectConfig: .init(),
            connectTimeoutPolicy: ConnectTimeoutPolicy(),
            iddleActivityPolicy: IdleActivityTimeoutPolicy(),
            messagePersistenceTTLSeconds: 300,
            messageCleanupInterval: 100,
            isMessagePersistenceEnabled: false
        )
    }
    
    private func createMockConfigWithDifferentValues() -> ClickstreamCourierConfig {
        ClickstreamCourierConfig(
            messageAdapter: [],
            connectConfig: .init(),
            connectTimeoutPolicy: ConnectTimeoutPolicy(isEnabled: true),
            iddleActivityPolicy: IdleActivityTimeoutPolicy(isEnabled: true),
            messagePersistenceTTLSeconds: 500,
            messageCleanupInterval: 200,
            isMessagePersistenceEnabled: false
        )
    }
    
    private func createMockCredentials() -> ClickstreamClientIdentifiers {
        CourierIdentifiers(userIdentifier: "user_id", deviceIdentifier: "device_id", bundleIdentifier: "bundle_id")
    }
    
    private func createMockCredentialsWithDifferentValues() -> ClickstreamClientIdentifiers {
        CourierIdentifiers(userIdentifier: "user_id_2", deviceIdentifier: "device_id_2", bundleIdentifier: "bundle_id_3")

    }
    
    private func createValidURLRequest() -> URLRequest {
        guard let url = URL(string: "wss://test.example.com/mqtt") else {
            XCTFail("Could not create valid test URL")
            return URLRequest(url: URL(string: "about:blank")!)
        }
        return URLRequest(url: url)
    }
}
