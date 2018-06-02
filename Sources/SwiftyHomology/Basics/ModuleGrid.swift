//
//  GradedModuleStructure.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/18.
//

import Foundation
import SwiftyMath

public typealias ModuleGridN<n: _Int, A: BasisElementType, R: EuclideanRing> = GridN<n, ModuleObject<A, R>>
public typealias ModuleGrid1<A: BasisElementType, R: EuclideanRing> = ModuleGridN<_1, A, R>
public typealias ModuleGrid2<A: BasisElementType, R: EuclideanRing> = ModuleGridN<_2, A, R>

public extension GridN where Object: ModuleObjectType {
    public typealias A = Object.A
    public typealias R = Object.R
    
    public init<S: Sequence>(name: String? = nil, list: S, default defaultObject: Object? = nil) where S.Element == (IntList, [A]?) {
        let grid = Dictionary(pairs: list.map{ (I, basis) in
            (I, basis.map{ Object(generators: $0) })
        })
        self.init(name: name, grid: grid, default: defaultObject)
    }
    
    public var isTrivial: Bool {
        return grid.values.forAll { $0?.isTrivial ?? false }
    }
    
    public var freePart: GridN<n, Object> {
        let grid: [IntList : Object?] = self.grid.mapValues{ $0?.freePart }
        return GridN(name: "\(name)_free", grid: grid, default: defaultObject)
    }
    
    public var torsionPart: GridN<n, Object> {
        let grid = self.grid.mapValues{ $0?.torsionPart }
        return GridN<n, Object>(name: "\(name)_tor", grid: grid, default: defaultObject)
    }
    
    public func describe(_ I: IntList) {
        if let s = self[I] {
            print("\(I) ", terminator: "")
            s.describe()
        } else {
            print("\(I) ?")
        }
    }
    
    public func describeAll() {
        for I in mDegrees {
            describe(I)
        }
    }
}

public extension GridN where n == _1, Object: ModuleObjectType {
    public init<S: Sequence>(name: String? = nil, list: S, default defaultObject: Object? = nil) where S.Element == [A]? {
        self.init(name: name, list: list.enumerated().map{ (i, b) in (i, b)}, default: defaultObject)
    }
    
    public init<S: Sequence>(name: String? = nil, list: S, default defaultObject: Object? = nil) where S.Element == (Int, [A]?) {
        self.init(name: name, list: list.map{ (i, basis) in (IntList(i), basis) }, default: defaultObject)
    }
    
    /*
    public func bettiNumer(_ i: Int) -> Int? {
        return self[i]?.rank
    }
    
    public var eulerCharacteristic: Int {
        return degrees.sum{ i in (-1).pow(i) * bettiNumer(i)! }
    }
     */
    
    public func describe(_ i: Int) {
        describe(IntList(i))
    }
}

public extension GridN where n == _2, Object: ModuleObjectType {
    public init<S: Sequence>(name: String? = nil, list: S, default defaultObject: Object? = nil) where S.Element == (Int, Int, [A]?) {
        self.init(name: name, list: list.map{ (i, j, basis) in (IntList(i, j), basis) }, default: defaultObject)
    }
    
    public func describe(_ i: Int, _ j: Int) {
        describe(IntList(i, j))
    }
}

public extension GridN where Object: IntModuleObjectType {
    public var structureCode: String {
        return mDegrees.map{ I in
            if let s = self[I] {
                return "\(I): \(s.structureCode)"
            } else {
                return "\(I): ?"
            }
        }.joined(separator: ", ")
    }
    
    public func torsionPart<t: _Int>(order: t.Type) -> ModuleGridN<n, A, IntegerQuotientRing<t>> {
        return ModuleGridN<n, A, IntegerQuotientRing<t>>(
            name: "\(name)_\(t.intValue)",
            grid: grid.mapValues{ $0?.torsionPart(order: order) },
            default: (defaultObject == .zeroModule) ? .zeroModule : nil
        )
    }
    
    public var order2torsionPart: ModuleGridN<n, A, 𝐙₂> {
        return torsionPart(order: _2.self)
    }
}
