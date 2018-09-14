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

public struct GridN<n: _Int, Object: Equatable>: Sequence, CustomStringConvertible {
    public var name: String
    internal var data: [IntList : Object?]
    internal let defaultObject: Object?

    public init(name: String? = nil, data: [IntList : Object?], default defaultObject: Object? = nil) {
        self.name = name ?? ""
        self.data = data.exclude{ $0.value == defaultObject }
        self.defaultObject = defaultObject
    }
    
    public subscript(I: IntList) -> Object? {
        get {
            return data[I] ?? defaultObject
        } set {
            data[I] = newValue
        }
    }
    
    public static var empty: GridN<n, Object> {
        return GridN(data: [:])
    }
    
    public var gridDim: Int {
        return n.intValue
    }
    
    public var indices: [IntList] {
        return data.keys.sorted()
    }
    
    public var isEmpty: Bool {
        return data.isEmpty
    }
    
    public var isDetermined: Bool {
        return data.values.forAll{ $0 != nil }
    }
    
    public func named(_ name: String) -> GridN<n, Object> {
        var base = self
        base.name = name
        return base
    }
    
    public func shifted(_ I: IntList) -> GridN<n, Object> {
        return GridN(name: name, data: data.mapKeys{ $0 + I }, default: defaultObject)
    }
    
    public func map<Object2: Equatable>(_ transform: (Object) -> Object2) -> GridN<n, Object2> {
        return GridN<n, Object2>(name: name, data: data.mapValues{ $0.map(transform) }, default: defaultObject.map(transform))
    }
    
    public func makeIterator() -> AnyIterator<(IntList, Object?)> {
        return AnyIterator(indices.lazy.map{ I in (I, self[I]) }.makeIterator())
    }
    
    public func describe(_ I: IntList) {
        print(description(I))
    }
    
    public func describeAll() {
        print(name)
        for I in indices {
            describe(I)
        }
        print()
    }
    
    internal func description(_ I: IntList) -> String {
        return "\(I) \( self[I].map{ "\($0)" } ?? "?" )"
    }
    
    public var description: String {
        let list = indices.map{ I in description(I) }
        return "\(name) {\n\(list.joined(separator: ",\n"))\n}"
    }
}

public extension GridN where n == _1 {
    public init(name: String? = nil, data: [Int: Object?], default defaultObject: Object? = nil) {
        self.init(name: name, data: data.mapKeys{ i in IntList(i) }, default: defaultObject)
    }
    
    public init(name: String? = nil, data: [Object?], default defaultObject: Object? = nil) {
        let dict = Dictionary(pairs: data.enumerated().map{ (i, o) in (IntList(i), o) })
        self.init(name: name, data: dict, default: defaultObject)
    }
    
    public subscript(i: Int) -> Object? {
        get {
            return self[IntList(i)]
        } set {
            self[IntList(i)] = newValue
        }
    }
    
    public var bottomIndex: Int {
        return indices.min()?[0] ?? 0
    }
    
    public var topIndex: Int {
        return indices.max()?[0] ?? 0
    }
    
    public func shifted(_ i: Int) -> Grid1<Object> {
        return shifted(IntList(i))
    }
    
    public func describe(_ i: Int) {
        describe(IntList(i))
    }
}

public extension GridN where n == _2 {
    public subscript(i: Int, j: Int) -> Object? {
        get {
            return self[IntList(i, j)]
        } set {
            self[IntList(i, j)] = newValue
        }
    }
    
    public func shifted(_ i: Int, _ j: Int) -> Grid2<Object> {
        return shifted(IntList(i, j))
    }
    
    public func describe(_ i: Int, _ j: Int) {
        describe(IntList(i, j))
    }
    
    public func printTable(skipDefault: Bool = true) {
        if data.isEmpty {
            return
        }
        
        let keys = data.keys
        let (iList, jList) = ( keys.map{$0[0]}.unique(), keys.map{$0[1]}.unique() )
        let (i0, i1) = (iList.min()!, iList.max()!)
        let (j0, j1) = (jList.min()!, jList.max()!)
        
        let jEvenOnly = jList.forAll{ j in (j - j0).isEven }
        
        let colList = (i0 ... i1).toArray()
        let rowList = (j0 ... j1).reversed().filter{ j in jEvenOnly ? (j - j0).isEven : true }.toArray()

        let table = Format.table("j\\i", rows: rowList, cols: colList) { (j, i) -> String in
            if skipDefault && !data.contains(key: IntList(i, j)) {
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
        case name, defaultObject, data
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let name = try c.decode(String.self, forKey: .name)
        let data = try c.decode([IntList : Object?].self, forKey: .data)
        let defaultObject = try c.decode(Object?.self, forKey: .defaultObject)
        self.init(name: name, data: data, default: defaultObject)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(data, forKey: .data)
        try c.encode(defaultObject, forKey: .defaultObject)
    }
}
