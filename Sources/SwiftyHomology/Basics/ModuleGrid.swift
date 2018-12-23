//
//  GradedModuleStructure.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/18.
//

import Foundation
import SwiftyMath

public typealias ModuleGrid1<A: BasisElementType, R: Ring> = ModuleGridN<_1, A, R>
public typealias ModuleGrid2<A: BasisElementType, R: Ring> = ModuleGridN<_2, A, R>

public struct ModuleGridN<n: _Int, A: BasisElementType, R: Ring>: Sequence {
    public typealias Object = ModuleObject<A, R>
    internal var grid: GridN<n, Object>
    
    internal init(_ grid: GridN<n, Object>) {
        self.grid = grid
    }
    
    public init(name: String? = nil, data: [IntList : Object?]) {
        let grid = GridN<n, Object>(name: name, data: data, default: .zeroModule)
        self.init(grid)
    }
    
    public init(name: String? = nil, generators: [IntList : [A]]) {
        self.init(name: name, data: generators.mapValues{ Object(basis: $0) })
    }
    
    public subscript(I: IntList) -> Object? {
        get {
            return grid[I]
        } set {
            grid[I] = newValue
        }
    }
    
    public var gridDim: Int {
        return n.intValue
    }
    
    public var indices: [IntList] {
        return grid.indices
    }
    
    public var isEmpty: Bool {
        return grid.isEmpty
    }
    
    public var isDetermined: Bool {
        return grid.isDetermined
    }
    
    public var isZero: Bool {
        return grid.allSatisfy { (_, o) in o?.isZero ?? false }
    }
    
    public var name: String {
        return grid.name
    }
    
    public func named(_ name: String) -> ModuleGridN<n, A, R> {
        return ModuleGridN(grid.named(name))
    }
    
    public func shifted(_ I: IntList) -> ModuleGridN<n, A, R> {
        return ModuleGridN(grid.shifted(I))
    }
    
    public var freePart: ModuleGridN<n, A, R> {
        return ModuleGridN( grid.map{ $0.freePart } )
               .named("\(grid.name)_free")
    }
    
    public var torsionPart: ModuleGridN<n, A, R> {
        return ModuleGridN( grid.map{ $0.torsionPart } )
               .named("\(grid.name)_tor")
    }
    
    public func describe(_ I: IntList, detail: Bool = false) {
        if let s = self[I] {
            print("\(I) ", terminator: "")
            s.describe(detail: detail)
        } else {
            print("\(I) ?")
        }
    }
    
    public func describeAll(detail: Bool = false) {
        print(grid.name)
        for I in indices {
            describe(I, detail: detail)
        }
        print()
    }

    public var description: String {
        return grid.description
    }
    
    public func makeIterator() -> AnyIterator<(IntList, Object?)> {
        return grid.makeIterator()
    }

    internal func _fold<m>(_ i: Int) -> ModuleGridN<m, A, R> {
        assert(m.intValue == n.intValue - 1)
        assert(0 <= i && i < gridDim)
        
        typealias Object = ModuleObject<A, R>
        
        let data = Dictionary(pairs: self.grid.group { (I, _) in I.drop(i) }
            .map{ (J, list) -> (IntList, Object?) in
                let sum = list.reduce(.zeroModule) { (res, next) -> Object? in
                    if let res = res, let next = next.1 {
                        return res ⊕ next
                    } else {
                        return nil
                    }
                }
                return (J, sum)
        })
        
        return ModuleGridN<m, A, R>(data: data)
    }
    
}

public extension ModuleGridN where n == _1 {
    public init(name: String? = nil, data: [Int: Object?]) {
        let grid = GridN<n, Object>(name: name, data: data, default: .zeroModule)
        self.init(grid)
    }
    
    public init(name: String? = nil, generators: [Int: [A]]) {
        let data = generators.mapValues{ Object(basis: $0) }
        self.init(name: name, data: data)
    }
    
    public subscript(i: Int) -> Object? {
        get {
            return self[IntList(i)]
        } set {
            self[IntList(i)] = newValue
        }
    }
    
    public var bottomDegree: Int {
        return grid.bottomIndex
    }
    
    public var topDegree: Int {
        return grid.topIndex
    }
    
    public func shifted(_ i: Int) -> ModuleGrid1<A, R> {
        return shifted(IntList(i))
    }
    
    public func EulerCharacteristic<R: Ring>(_ ringType: R.Type) -> R {
        return self.sum { (I, V) -> R in
            let i = I[0]
            return R(from: (-1).pow(i) * V!.rank)
        }
    }
    
    public func describe(_ i: Int) {
        describe(IntList(i))
    }
}

public extension ModuleGridN where n == _2 {
    public subscript(i: Int, j: Int) -> Object? {
        get {
            return self[IntList(i, j)]
        } set {
            self[IntList(i, j)] = newValue
        }
    }
    
    public func shifted(_ i: Int, _ j: Int) -> ModuleGrid2<A, R> {
        return shifted(IntList(i, j))
    }
    
    public func describe(_ i: Int, _ j: Int) {
        describe(IntList(i, j))
    }
    
    public func fold(_ i: Int) -> ModuleGrid1<A, R> {
        return _fold(i)
    }

    public func gradedEulerCharacteristic<R: Ring, t: Indeterminate>(_ ringType: R.Type, _ tType: t.Type) -> LaurentPolynomial<R, t> {
        typealias P = LaurentPolynomial<R, t>
        let t = P.indeterminate
        
        return self.sum { (I, V) -> P in
            let (i, j) = (I[0], I[1])
            return P(from: (-1).pow(i) * V!.rank) * t.pow(j)
        }
    }
    
    public func printTable(separator s: String = "\t", printHeaders: Bool = true, format: (Object) -> String = { "\($0)" }) {
        grid.printTable(separator: s, printHeaders: printHeaders, format: format)
    }
}

public extension ModuleGridN where R == 𝐙 {
    public var structureCode: String {
        return indices.map{ I in
            if let s = self[I] {
                return "\(I): \(s.structureCode)"
            } else {
                return "\(I): ?"
            }
        }.joined(separator: ", ")
    }
    
    public func torsionPart<t: _Int>(order: t.Type) -> ModuleGridN<n, A, IntegerQuotientRing<t>> {
        return ModuleGridN<n, A, IntegerQuotientRing<t>>(
            grid.map{ $0.torsionPart(order: order) }
        ).named("\(grid.name)_\(t.intValue)")
    }
    
    public var order2torsionPart: ModuleGridN<n, A, 𝐙₂> {
        return torsionPart(order: _2.self)
    }
}
