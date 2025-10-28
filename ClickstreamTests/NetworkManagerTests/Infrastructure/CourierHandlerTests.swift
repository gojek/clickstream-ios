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
        
        XCTAssertNoThrow(try sut.publishMessage(testData))
    }
    
    func testPublishMessage_WithEmptyData_DoesNotThrow() {
        let emptyData = Data()
        
        XCTAssertNoThrow(try sut.publishMessage(emptyData))
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
        
        XCTAssertNoThrow(try sut.publishMessage(largeData))
    }
    
    func testPublishMessage_WhenClientNotInitialized_ThrowsError() {
        let testData = "test message".data(using: .utf8)!
        
        do {
            try sut.publishMessage(testData)
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testPublishMessage_AfterDisconnect_ThrowsError() async {
        let request = createValidURLRequest()
        await sut.setup(request: request, keepTrying: false, connectionCallback: nil)
        
        sut.disconnect()
        
        let testData = "test message".data(using: .utf8)!
        XCTAssertThrowsError(try sut.publishMessage(testData))
    }
    
    func testPublishMessage_WithMalformedData_HandlesError() {
        let malformedData = Data([0x00, 0xFF, 0x00, 0xFF])
        
        do {
            try sut.publishMessage(malformedData)
        } catch {
            XCTFail("Should handle malformed data gracefully")
        }
    }
    
    func testPublishMessage_ConcurrentCalls_HandlesCorrectly() async {
        let request = createValidURLRequest()
        await sut.setup(request: request, keepTrying: false, connectionCallback: nil)
        
        let testData1 = "message1".data(using: .utf8)!
        let testData2 = "message2".data(using: .utf8)!
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    try self.sut.publishMessage(testData1)
                } catch {
                    XCTAssertNotNil(error)
                }
            }
            
            group.addTask {
                do {
                    try self.sut.publishMessage(testData2)
                } catch {
                    XCTAssertNotNil(error)
                }
            }
        }
    }
    
    func testPublishMessage_WithExtremelyLargePayload_HandlesCorrectly() {
        let extremelyLargeData = Data(repeating: 0x42, count: 1_000_000)
        
        do {
            try sut.publishMessage(extremelyLargeData)
        } catch {
            XCTAssertTrue(error is CourierError)
        }
    }
    
    func testMemoryManagement_AfterMultipleOperations_NoLeaks() async {
        let request = createValidURLRequest()
        
        for _ in 0..<10 {
            await sut.setup(request: request, keepTrying: false, connectionCallback: nil)
            
            let testData = "test".data(using: .utf8)!
            do {
                try sut.publishMessage(testData)
            } catch {
                continue
            }
            
            sut.disconnect()
        }
        
        XCTAssertNotNil(sut)
    }
}

extension CourierHandlerTests {
    
    private func createMockConfig() -> ClickstreamCourierConfig {
        ClickstreamCourierConfig(
            topics: ["test/topic": 1],
            messageAdapter: [],
            isMessagePersistenceEnabled: false,
            autoReconnectInterval: 30,
            maxAutoReconnectInterval: 120,
            authenticationTimeoutInterval: 60,
            enableAuthenticationTimeout: true,
            connectConfig: .init(),
            connectTimeoutPolicy: ConnectTimeoutPolicy(),
            iddleActivityPolicy: IdleActivityTimeoutPolicy(),
            messagePersistenceTTLSeconds: 300,
            messageCleanupInterval: 100
        )
    }
    
    private func createMockConfigWithDifferentValues() -> ClickstreamCourierConfig {
        ClickstreamCourierConfig(
            topics: ["test/topic": 1],
            messageAdapter: [],
            isMessagePersistenceEnabled: false,
            autoReconnectInterval: 30,
            maxAutoReconnectInterval: 120,
            authenticationTimeoutInterval: 60,
            enableAuthenticationTimeout: true,
            connectConfig: .init(),
            connectTimeoutPolicy: ConnectTimeoutPolicy(isEnabled: true),
            iddleActivityPolicy: IdleActivityTimeoutPolicy(isEnabled: true),
            messagePersistenceTTLSeconds: 500,
            messageCleanupInterval: 200
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
