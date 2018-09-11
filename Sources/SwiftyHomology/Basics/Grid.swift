//
//  GradedModuleStructure.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/18.
//

import Foundation
import SwiftyMath

public typealias Grid1<Object: Equatable> = GridN<_1, Object>
public typealias Grid2<Object: Equatable> = GridN<_2, Object>

public struct GridN<n: _Int, Object: Equatable>: CustomStringConvertible {
    public var name: String
    internal var grid: [IntList : Object?]
    internal let defaultObject: Object?

    public init(name: String? = nil, grid: [IntList : Object?] = [:], default defaultObject: Object? = nil) {
        self.name = name ?? ""
        self.grid = grid.exclude{ $0.value == defaultObject }
        self.defaultObject = defaultObject
    }
    
    public init<S: Sequence>(name: String? = nil, list: S, default defaultObject: Object? = nil) where S.Element == (IntList, Object?) {
        self.init(name: name, grid: Dictionary(pairs: list), default: defaultObject)
    }
    
    public subscript(I: IntList) -> Object? {
        get {
            return grid[I] ?? defaultObject
        } set {
            grid[I] = newValue
        }
    }
    
    public var gridDim: Int {
        return n.intValue
    }
    
    public var mDegrees: [IntList] {
        return grid.keys.sorted()
    }
    
    public var isEmpty: Bool {
        return mDegrees.isEmpty
    }
    
    public var isDetermined: Bool {
        return grid.values.forAll{ $0 != nil }
    }
    
    public func named(_ name: String) -> GridN<n, Object> {
        var base = self
        base.name = name
        return base
    }
    
    public func shifted(_ I: IntList) -> GridN<n, Object> {
        return GridN(name: name, grid: grid.mapKeys{ $0 + I }, default: defaultObject)
    }
    
    public func describe(_ I: IntList) {
        print(description(I))
    }
    
    public func describeAll() {
        print(name)
        for I in mDegrees {
            describe(I)
        }
        print()
    }
    
    internal func description(_ I: IntList) -> String {
        return "\(I) \( self[I].map{ "\($0)" } ?? "?" )"
    }
    
    public var description: String {
        let list = mDegrees.map{ I in description(I) }
        return "\(name) {\n\(list.joined(separator: ",\n"))\n}"
    }
}

public extension GridN where n == _1 {
    public init(name: String? = nil, grid: [Int : Object?], default defaultObject: Object? = nil) {
        self.init(name: name, grid: grid.mapKeys{ i in IntList(i) }, default: defaultObject)
    }
    
    public init<S: Sequence>(name: String? = nil, list: S, default defaultObject: Object? = nil) where S.Element == Object? {
        self.init(name: name, list: list.enumerated().map{ (i, o) in (i, o) }, default: defaultObject)
    }
    
    public init<S: Sequence>(name: String? = nil, list: S, default defaultObject: Object? = nil) where S.Element == (Int, Object?) {
        self.init(name: name, list: list.map{ (i, o) in (IntList(i), o) }, default: defaultObject)
    }
    
    public subscript(i: Int) -> Object? {
        get {
            return self[IntList(i)]
        } set {
            self[IntList(i)] = newValue
        }
    }
    
    public var degrees: [Int] {
        return mDegrees.map{ I in I[0] }
    }
    
    public var bottomDegree: Int {
        return degrees.min() ?? 0
    }
    
    public var topDegree: Int {
        return degrees.max() ?? 0
    }
    
    public func shifted(_ i: Int) -> Grid1<Object> {
        return shifted(IntList(i))
    }
    
    public func describe(_ i: Int) {
        describe(IntList(i))
    }
}

extension GridN: Sequence where n == _1 {
    public typealias Element = Object?
    public typealias Iterator = AnyIterator<Object?>
    
    public func makeIterator() -> AnyIterator<Object?> {
        let itr = (isEmpty ? (bottomDegree ... topDegree).map{ self[$0] } : []).makeIterator()
        return AnyIterator(itr)
    }
}

public extension GridN where n == _2 {
    public init<S: Sequence>(name: String? = nil, list: S, default defaultObject: Object? = nil) where S.Element == (Int, Int, Object?) {
        self.init(name: name, list: list.map{ (i, j, o) in (IntList(i, j), o) }, default: defaultObject)
    }
    
    public subscript(i: Int, j: Int) -> Object? {
        get {
            return self[IntList(i, j)]
        } set {
            self[IntList(i, j)] = newValue
        }
    }
    
    public var bidegrees: [(Int, Int)] {
        return mDegrees.map{ I in (I[0], I[1]) }
    }
    
    public func shifted(_ i: Int, _ j: Int) -> Grid2<Object> {
        return shifted(IntList(i, j))
    }
    
    public func describe(_ i: Int, _ j: Int) {
        describe(IntList(i, j))
    }
    
    public func printTable(skipDefault: Bool = true) {
        if grid.isEmpty {
            return
        }
        
        let keys = grid.keys
        let (iList, jList) = ( keys.map{$0[0]}.unique(), keys.map{$0[1]}.unique() )
        let (i0, i1) = (iList.min()!, iList.max()!)
        let (j0, j1) = (jList.min()!, jList.max()!)
        
        let jEvenOnly = jList.forAll{ j in (j - j0).isEven }
        
        let colList = (i0 ... i1).toArray()
        let rowList = (j0 ... j1).reversed().filter{ j in jEvenOnly ? (j - j0).isEven : true }.toArray()

        let table = Format.table("j\\i", rows: rowList, cols: colList) { (j, i) -> String in
            if skipDefault && !grid.contains(key: IntList(i, j)) {
                return ""
            }
            return self[i, j].map{ "\($0)" } ?? "?"
        }
        
        print(name)
        print(table)
        print()
    }
}

extension GridN: Codable where Object: Codable {
    enum CodingKeys: String, CodingKey {
        case name, defaultObject, grid
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let name = try c.decode(String.self, forKey: .name)
        let grid = try c.decode([IntList : Object?].self, forKey: .grid)
        let defaultObject = try c.decode(Object?.self, forKey: .defaultObject)
        self.init(name: name, grid: grid, default: defaultObject)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(grid, forKey: .grid)
        try c.encode(defaultObject, forKey: .defaultObject)
    }
}
