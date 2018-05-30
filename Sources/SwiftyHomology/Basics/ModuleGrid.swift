//
//  GradedModuleStructure.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/18.
//

import Foundation
import SwiftyMath

public typealias ModuleGrid<Dim: _Int, A: BasisElementType, R: EuclideanRing> = ObjectGrid<Dim, SimpleModuleStructure<A, R>>
public typealias ModuleSequence<A: BasisElementType, R: EuclideanRing> = ModuleGrid<_1, A, R>
public typealias ModuleGrid2<A: BasisElementType, R: EuclideanRing>    = ModuleGrid<_2, A, R>

// MEMO waiting for parametrized extension.
// public extension<A: BasisElementType, R: EuclideanRing> ObjectGrid where Object == SimpleModuleStructure<A, R> {

public protocol SimpleModuleStructureType {
    associatedtype A: BasisElementType
    associatedtype R: EuclideanRing
    
    init(generators: [A])
    
    var isTrivial: Bool { get }
    var rank: Int { get }
    var freePart: Self { get }
    var torsionPart: Self { get }
    func describe()
}

extension SimpleModuleStructure: SimpleModuleStructureType {}

public extension ObjectGrid where Object: SimpleModuleStructureType {
    public typealias A = Object.A
    public typealias R = Object.R
    
    public init<S: Sequence>(name: String? = nil, default defaultObject: Object? = nil, list: S) where S.Element == (IntList, [A]?) {
        let grid = Dictionary(pairs: list.map{ (I, basis) in
            (I, basis.map{ Object(generators: $0) })
        })
        self.init(name: name, default: defaultObject, grid: grid)
    }
    
    public var isTrivial: Bool {
        return grid.values.forAll { $0?.isTrivial ?? false }
    }
    
    public var freePart: ObjectGrid<Dim, Object> {
        let grid: [IntList : Object?] = self.grid.mapValues{ $0?.freePart }
        return ObjectGrid(name: "\(name)_free", default: defaultObject, grid: grid)
    }
    
    public var torsionPart: ObjectGrid<Dim, Object> {
        let grid = self.grid.mapValues{ $0?.torsionPart }
        return ObjectGrid<Dim, Object>(name: "\(name)_tor", default: defaultObject, grid: grid)
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

public extension ObjectGrid where Dim == _1, Object: SimpleModuleStructureType {
    public init<S: Sequence>(name: String? = nil, default defaultObject: Object? = nil, list: S) where S.Element == [A]? {
        self.init(name: name, default: defaultObject, list: list.enumerated().map{ (i, b) in (i, b)})
    }
    
    public init<S: Sequence>(name: String? = nil, default defaultObject: Object? = nil, list: S) where S.Element == (Int, [A]?) {
        self.init(name: name, default: defaultObject, list: list.map{ (i, basis) in (IntList(i), basis) })
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

public extension ObjectGrid where Dim == _2, Object: SimpleModuleStructureType {
    public init<S: Sequence>(name: String? = nil, default defaultObject: Object? = nil, list: S) where S.Element == (Int, Int, [A]?) {
        self.init(name: name, default: defaultObject, list: list.map{ (i, j, basis) in (IntList(i, j), basis) })
    }
    
    public func describe(_ i: Int, _ j: Int) {
        describe(IntList(i, j))
    }
}

public protocol IntSimpleModuleStructureType: SimpleModuleStructureType where R == 𝐙 {
    var structureCode: String { get }
    func orderNtorsionPart<n: _Int>(_ type: n.Type) -> SimpleModuleStructure<A, IntegerQuotientRing<n>>
}

extension SimpleModuleStructure: IntSimpleModuleStructureType where R == 𝐙 {}

public extension ModuleGrid where Object: IntSimpleModuleStructureType {
    public var structureCode: String {
        return mDegrees.map{ I in
            if let s = self[I] {
                return "\(I): \(s.structureCode)"
            } else {
                return "\(I): ?"
            }
        }.joined(separator: ", ")
    }
    
    public func orderNtorsionPart<n: _Int>(_ type: n.Type) -> ModuleGrid<Dim, A, IntegerQuotientRing<n>> {
        return ModuleGrid<Dim, A, IntegerQuotientRing<n>>(
            name: "\(name)_\(n.intValue)",
            default: (defaultObject != nil) ? .zeroModule : nil,
            grid: grid.mapValues{ $0?.orderNtorsionPart(type) }
        )
    }
    
    public var order2torsionPart: ModuleGrid<Dim, A, 𝐙₂> {
        return orderNtorsionPart(_2.self)
    }
}
