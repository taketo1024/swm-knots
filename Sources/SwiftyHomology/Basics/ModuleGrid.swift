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

// MEMO waiting for parametrized extension.
// extension<A, R> ObjectGrid where Object == ModuleObject<A, R> { ... }

public protocol _ModuleObject: Equatable {
    associatedtype A: BasisElementType
    associatedtype R: EuclideanRing
    
    init(generators: [A])
    var entity: ModuleObject<A, R> { get }
}

extension ModuleObject: _ModuleObject {
    public var entity: ModuleObject<A, R> {
        return self
    }
}

public extension GridN where Object: _ModuleObject {
    public typealias A = Object.A
    public typealias R = Object.R
    
    public init<S: Sequence>(name: String? = nil, list: S, default defaultObject: Object? = nil) where S.Element == (IntList, [A]?) {
        let grid = Dictionary(pairs: list.map{ (I, basis) in
            (I, basis.map{ Object(generators: $0) })
        })
        self.init(name: name, grid: grid, default: defaultObject)
    }
    
    public var isZero: Bool {
        return grid.values.forAll { $0?.entity.isZero ?? false }
    }
    
    public var freePart: ModuleGridN<n, A, R> {
        let grid = self.grid.mapValues{ $0?.entity.freePart }
        return ModuleGridN(name: "\(name)_free", grid: grid, default: defaultObject?.entity)
    }
    
    public var torsionPart: ModuleGridN<n, A, R> {
        let grid = self.grid.mapValues{ $0?.entity.torsionPart }
        return ModuleGridN(name: "\(name)_tor", grid: grid, default: defaultObject?.entity)
    }
    
    internal func _fold<m>(_ i: Int) -> ModuleGridN<m, A, R> {
        assert(m.intValue == n.intValue - 1)
        assert(0 <= i && i < gridDim)
        
        typealias Object = ModuleObject<A, R>
        
        let list = grid.group { (I, _) in I.drop(i) }
            .map{ (J, list) -> (IntList, Object?) in
                let sum = list.reduce(.zeroModule) { (res, next) -> Object? in
                    if let res = res, let next = next.value {
                        return res ⊕ (next as! Object)
                    } else {
                        return nil
                    }
                }
                return (J, sum)
        }
        
        return ModuleGridN<m, A, R>(name: name, list: list, default: defaultObject?.entity)
    }
    
    public func describe(_ I: IntList) {
        if let s = self[I] {
            print("\(I) ", terminator: "")
            s.entity.describe()
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

public extension GridN where n == _1, Object: _ModuleObject {
    public init<S: Sequence>(name: String? = nil, list: S, default defaultObject: Object? = nil) where S.Element == [A]? {
        self.init(name: name, list: list.enumerated().map{ (i, b) in (i, b)}, default: defaultObject)
    }
    
    public init<S: Sequence>(name: String? = nil, list: S, default defaultObject: Object? = nil) where S.Element == (Int, [A]?) {
        self.init(name: name, list: list.map{ (i, basis) in (IntList(i), basis) }, default: defaultObject)
    }
    
    public func describe(_ i: Int) {
        describe(IntList(i))
    }
}

public extension GridN where n == _2, Object: _ModuleObject {
    public init<S: Sequence>(name: String? = nil, list: S, default defaultObject: Object? = nil) where S.Element == (Int, Int, [A]?) {
        self.init(name: name, list: list.map{ (i, j, basis) in (IntList(i, j), basis) }, default: defaultObject)
    }
    
    public func describe(_ i: Int, _ j: Int) {
        describe(IntList(i, j))
    }
}

public extension GridN where Object: _ModuleObject, Object.R == 𝐙 {
    public var structureCode: String {
        return mDegrees.map{ I in
            if let s = self[I] {
                return "\(I): \(s.entity.structureCode)"
            } else {
                return "\(I): ?"
            }
        }.joined(separator: ", ")
    }
    
    public func torsionPart<t: _Int>(order: t.Type) -> ModuleGridN<n, A, IntegerQuotientRing<t>> {
        assert(defaultObject == nil || defaultObject!.entity == .zeroModule)
        return ModuleGridN<n, A, IntegerQuotientRing<t>>(
            name: "\(name)_\(t.intValue)",
            grid: grid.mapValues{ $0?.entity.torsionPart(order: order) },
            default: (defaultObject != nil) ? .zeroModule : nil
        )
    }
    
    public var order2torsionPart: ModuleGridN<n, A, 𝐙₂> {
        return torsionPart(order: _2.self)
    }
}
