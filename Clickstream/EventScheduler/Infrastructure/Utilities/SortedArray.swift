//
//  SortedArray.swift
//  Clickstream
//
//  Created by Abhijeet Mallick on 20/05/20.
//  Copyright © 2020 Gojek. All rights reserved.
//

import Foundation

struct SortedArray<Element> where Element: Comparable {
    private var elements: [Element]
    
    /// determines the  sort order of array
    private let sortingOrder: (Element, Element) -> Bool
    
    init() {
        self.init(sortingOrder: <)
    }
    
    init(sortingOrder: @escaping (Element, Element) -> Bool) {
        self.sortingOrder = sortingOrder
        self.elements = []
    }
    
    init<S: Sequence>(sequence: S) where S.Iterator.Element == Element {
        self.init(sequence: sequence, sortingOrder: <)
    }
    
    init<S: Sequence>(sequence: S, sortingOrder: @escaping (Element, Element) -> Bool) where S.Iterator.Element == Element {
        let sorted = sequence.sorted(by: sortingOrder)
        self.elements = sorted
        self.sortingOrder = sortingOrder
    }
    
    mutating func append(with element: Element) {
        self.elements.append(element)
        self.elements.sort(by: self.sortingOrder)
    }
    
    mutating func append<S: Sequence>(with elements: S) where S.Iterator.Element == Element {
        self.elements.append(contentsOf: elements)
        self.elements.sort(by: self.sortingOrder)
    }
    
    mutating func remove(at index: Int) {
        self.elements.remove(at: index)
    }
    
    mutating func removeFirst(_ n: Int) {
        self.elements.removeFirst(n)
    }
    
    mutating func removeAll() {
        self.elements.removeAll()
    }
    
    mutating func prefixAndRemove(_ n: Int) -> [Element] {
        let prefixArray = self.elements.prefix(n)
        self.removeFirst(n)
        return Array(prefixArray)
    }
    
    mutating func prefixAndRemoveAll() -> [Element] {
        defer {
            self.removeAll()
        }
        return self.elements
    }
}

/// Conform to Collection Protocol so that we can accss all the properties/methods of Collection, such as count, contains, filter etc
extension SortedArray: Collection {
    
    public var startIndex: Int {
        return elements.startIndex
    }
    
    public var endIndex: Int {
        return elements.endIndex
    }

    public func index(after i: Int) -> Int {
        return elements.index(after: i)
    }

    public func index(before i: Int) -> Int {
        return elements.index(before: i)
    }

    public subscript(position: Int) -> Element {
        return elements[position]
    }
}
