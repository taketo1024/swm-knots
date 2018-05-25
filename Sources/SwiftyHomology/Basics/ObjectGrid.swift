//
//  GradedModuleStructure.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/18.
//

import Foundation
import SwiftyMath

public typealias ObjectSequence<Object> = ObjectGrid<_1, Object>
public typealias ObjectGrid2<Object>    = ObjectGrid<_2, Object>

public protocol ObjectGridType: CustomStringConvertible {
    associatedtype Object
}

public struct ObjectGrid<Dim: _Int, Object>: ObjectGridType {
    public let name: String
    internal let defaultObject: Object?
    internal var grid: [IntList : Object?]
    
    public init(name: String? = nil, default defaultObject: Object? = nil, grid: [IntList : Object?] = [:]) {
        self.name = name ?? ""
        self.defaultObject = defaultObject
        self.grid = grid
    }
    
    public init<S: Sequence>(name: String? = nil, default defaultObject: Object? = nil, list: S) where S.Element == (IntList, Object?) {
        self.init(name: name, default: defaultObject, grid: Dictionary(pairs: list))
    }
    
    public subscript(I: IntList) -> Object? {
        get {
            return grid[I] ?? defaultObject
        } set {
            grid[I] = newValue
        }
    }
    
    public var gradingDim: Int {
        return Dim.intValue
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
    
    public func shifted(_ I: IntList) -> ObjectGrid<Dim, Object> {
        return ObjectGrid(name: name, default: defaultObject, grid: grid.mapKeys{ $0 + I })
    }
    
    public func describe(_ I: IntList) {
        print(description(I))
    }
    
    public func describeAll() {
        for I in mDegrees {
            describe(I)
        }
    }
    
    internal func description(_ I: IntList) -> String {
        return "\(I) \( self[I].map{ "\($0)" } ?? "?" )"
    }
    
    public var description: String {
        let list = mDegrees.map{ I in description(I) }
        return "\(name) {\n\(list.joined(separator: ",\n"))\n}"
    }
}

public extension ObjectGrid where Dim == _1 {
    public init(name: String? = nil, default defaultObject: Object? = nil, grid: [Int : Object?]) {
        self.init(name: name, default: defaultObject, grid: grid.mapKeys{ i in IntList(i) })
    }
    
    public init<S: Sequence>(name: String? = nil, default defaultObject: Object? = nil, list: S) where S.Element == Object? {
        self.init(name: name, default: defaultObject, list: list.enumerated().map{ (i, o) in (i, o) })
    }
    
    public init<S: Sequence>(name: String? = nil, default defaultObject: Object? = nil, list: S) where S.Element == (Int, Object?) {
        self.init(name: name, default: defaultObject, list: list.map{ (i, o) in (IntList(i), o) })
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
    
    public func shifted(_ i: Int) -> ObjectSequence<Object> {
        return shifted(IntList(i))
    }
    
    public func describe(_ i: Int) {
        describe(IntList(i))
    }
}

extension ObjectGrid: Sequence where Dim == _1 {
    public typealias Element = Object?
    public typealias Iterator = AnyIterator<Object?>
    
    public func makeIterator() -> AnyIterator<Object?> {
        let itr = (isEmpty ? (bottomDegree ... topDegree).map{ self[$0] } : []).makeIterator()
        return AnyIterator(itr)
    }
}

public extension ObjectGrid where Dim == _2 {
    public init<S: Sequence>(name: String? = nil, default defaultObject: Object? = nil, list: S) where S.Element == (Int, Int, Object?) {
        self.init(name: name, default: defaultObject, list: list.map{ (i, j, o) in (IntList(i, j), o) })
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
    
    public func shifted(_ i: Int, _ j: Int) -> ObjectGrid2<Object> {
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
        
        print(table)
    }
}

extension ObjectGrid: Codable where Object: Codable {
    enum CodingKeys: String, CodingKey {
        case name, defaultObject, grid
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let name = try c.decode(String.self, forKey: .name)
        let defaultObject = try c.decode(Object?.self, forKey: .defaultObject)
        let grid = try c.decode([IntList : Object?].self, forKey: .grid)
        self.init(name: name, default: defaultObject, grid: grid)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(defaultObject, forKey: .defaultObject)
        try c.encode(grid, forKey: .grid)
    }
}
