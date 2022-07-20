//
//  SortedArrayTests.swift
//  ClickstreamTests
//
//  Created by Abhijeet Mallick on 20/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

@testable import Clickstream
import XCTest

class SortedArrayTests: XCTestCase {
    
    func testInitWithArray() {
        let sortedArray = SortedArray(sequence: ["a", "c" , "d", "e" ,"b"])
        XCTAssertEqual(Array(sortedArray), ["a", "b", "c", "d", "e"])
    }
    
    func testInit() {
        // given
        let unsortedArray = ["a", "c" , "d", "e" ,"b"]
        
        // when
        var sortedArray = SortedArray<String>()        
        sortedArray.append(with: unsortedArray)
        
        // then
        XCTAssertEqual(Array(sortedArray), ["a", "b", "c", "d", "e"])
    }
    
    func testAppendSingleElement() {
        var sortedArray = SortedArray(sequence: ["b", "c", "d", "e"])
        sortedArray.append(with: "a")
        XCTAssertEqual(Array(sortedArray), ["a", "b" ,"c", "d", "e"])
    }
    
    func testAppendSequenceOfElements() {
        var sortedArray = SortedArray(sequence: ["a", "b", "c", "e"])
        sortedArray.append(with: ["d", "f"])
        XCTAssertEqual(Array(sortedArray), ["a", "b", "c", "d", "e", "f"])
    }
    
    func testRemoveElementAtIndex() {
        var sortedArray = SortedArray(sequence: ["a", "c" , "d", "e" ,"b"])
        sortedArray.remove(at: 2)
        XCTAssertEqual(Array(sortedArray), ["a", "b", "d", "e"])
    }
    
    func testRemoveAllElements() {
        var sortedArray = SortedArray(sequence: ["a", "c" , "d", "e" ,"b"])
        sortedArray.removeAll()
        XCTAssert(sortedArray.isEmpty)
    }
    
    func testRemoveFirst() {
        var sortedArray = SortedArray(sequence: ["a", "c" , "d", "e" ,"b"])
        sortedArray.removeFirst(2)
        XCTAssertEqual(Array(sortedArray), ["c", "d", "e"])
    }
    
    func testPrefixAndRemoveElement() {
        var sortedArray = SortedArray(sequence: ["a", "c" , "d", "e" ,"b"])
        let firstTwoElements = sortedArray.prefixAndRemove(2)
        XCTAssertEqual(Array(sortedArray), ["c", "d", "e"])
        XCTAssertEqual(firstTwoElements, ["a", "b"])
    }
    
    func testPrefixAndRemoveAll() {
        var sortedArray = SortedArray(sequence: ["a", "c" , "d", "e" ,"b"])
        let allElements = sortedArray.prefixAndRemoveAll()
        XCTAssert(sortedArray.isEmpty)
        XCTAssertEqual(allElements, ["a", "b", "c", "d", "e"])
    }
    
    func testIndexBefore() {
        // given
        let indexBefore = 2
        let sortedArray = SortedArray(sequence: ["a", "c" , "d", "e" ,"b"])
        
        // when
        let index = sortedArray.index(before: indexBefore)
        
        // then
        XCTAssertEqual(index, indexBefore - 1 )
    }
}
