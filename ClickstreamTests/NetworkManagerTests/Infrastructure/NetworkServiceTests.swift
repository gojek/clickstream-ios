//
//  NetworkServiceTests.swift
//  ClickstreamTests
//
//  Created by Anirudh Vyas on 04/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import XCTest

class NetworkServiceTests: XCTestCase {
    
    func test_whenMockDataIsPassed_shouldReturnConnectedResponse() {
        //given
        let urlRequest = URLRequest(url: URL(string: "ws://mock.clickstream.com/events")!)
        let expectation = self.expectation(description: "Should return correct data")
        let sut = DefaultNetworkService<SocketHandlerMockSuccess>(with: urlRequest, performOnQueue: .main)
        
        //when
        _ = sut.initiateConnection(connectionStatusListener: { result in
            switch result {
            case .success(let state):
                XCTAssertEqual(state, .connected)
                 expectation.fulfill()
            case .failure(_):
                XCTFail("Should return proper response")
            }
        })
        //then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_whenMockDataIsPassed_shouldWriteSuccessfully() {
        //given
        let urlRequest = URLRequest(url: URL(string: "ws://mock.clickstream.com/events")!)
        let expectation = self.expectation(description: "Should return correct data")
        let sut = DefaultNetworkService<SocketHandlerMockSuccess>(with: urlRequest, performOnQueue: .main)
        
        //when
        _ = sut.initiateConnection(connectionStatusListener: { result in
            switch result {
            case .success(let state):
                if state == .connected {
                    sut.write(Data()) { (result: Result<Odpf_Raccoon_EventResponse, ConnectableError>) in
                        expectation.fulfill()
                    }
                }
            case .failure(_):
                XCTFail("Should return proper response")
            }
        })
        //then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_whenMockDataIsPassed_shouldDisconnectSuccessfully() {
        //given
        let urlRequest = URLRequest(url: URL(string: "ws://mock.clickstream.com/events")!)
        let expectation = self.expectation(description: "Should return malformed url error")
        
        let sut = DefaultNetworkService<SocketHandlerMockSuccess>(with: urlRequest, performOnQueue: .main)
        
        //when
        let statusListener: ConnectionStatus = { result in
            switch result {
            case .success(let status):
                if status == .connected {
                    sut.terminateConnection()
                }
                if status == .disconnected {
                    expectation.fulfill()
                }
            case .failure(_):
                XCTFail("Should not throw an error")
            }
        }
        _ = sut.initiateConnection(connectionStatusListener: statusListener)
        
        //then
        wait(for: [expectation], timeout: 2.0)
    }
}
