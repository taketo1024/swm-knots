//
//  GradedModuleStructure.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/18.
//

import Foundation
import SwiftyMath

public typealias   GradedModuleStructure<A: BasisElementType, R: EuclideanRing> = _GradedModuleStructure<_1, A, R>
public typealias BigradedModuleStructure<A: BasisElementType, R: EuclideanRing> = _GradedModuleStructure<_2, A, R>

public struct _GradedModuleStructure<Dim: _Int, A: BasisElementType, R: EuclideanRing>: CustomStringConvertible {
    public typealias Object = SimpleModuleStructure<A, R>
    
    public let name: String
    internal var grid: [IntList : Object?]
    
    internal init(name: String? = nil, grid: [IntList : Object?]) {
        self.name = name ?? ""
        self.grid = grid.exclude{ $0.value?.isTrivial ?? false }
    }
    
    internal init<S: Sequence>(name: String? = nil, list: S) where S.Element == (IntList, Object?) {
        self.init(name: name, grid: Dictionary(pairs: list))
    }
    
    internal init<S: Sequence>(name: String? = nil, list: S) where S.Element == (IntList, [A]?) {
        self.init(name: name, grid: Dictionary(pairs: list.map{ (I, basis) in
            (I, basis.map{ Object(generators: $0) })
        }))
    }
    
    internal subscript(I: IntList) -> Object? {
        get {
            return grid[I] ?? .zeroModule
        } set {
            grid[I] = newValue
        }
    }
    
    public var dim: Int {
        return Dim.intValue
    }
    
    internal var _nonZeroDegrees: [IntList] {
        return grid.keys.sorted()
    }
    
    internal func shifted(_ I: IntList) -> _GradedModuleStructure<Dim, A, R> {
        return _GradedModuleStructure(name: name, grid: grid.mapKeys{ $0 + I} )
    }
    
    internal func asChainComplex(degree: IntList, d: @escaping (IntList, A) -> FreeModule<A, R>) -> _GradedChainComplex<Dim, A, R> {
        return _GradedChainComplex(base: self, degree: degree, map: d)
    }
    
    internal func describe(_ I: IntList) {
        if let o = self[I] {
            if !o.isTrivial {
                print("\(I) \(o) {")
                for (i, x) in o.generators.enumerated() {
                    print("\t(\(i)) ", x)
                }
                print("}")
            } else {
                print("\(I) 0")
            }
        } else {
            print("\(I) ?")
        }
    }
    
    public func describeAll() {
        for I in _nonZeroDegrees {
            describe(I)
        }
    }
    
    public var description: String {
        return "\(name) {\n\( _nonZeroDegrees.map{ I in "\t\(I) " + (self[I]?.description ?? "?") }.joined(separator: ",\n"))\n}"
    }
}

public extension _GradedModuleStructure where Dim == _1 {
    public init<S: Sequence>(name: String? = nil, list: S) where S.Element == [A]? {
        self.init(name: name, list: list.enumerated().map{ (i, basis) in (IntList(i), basis) })
    }
    
    public init<S: Sequence>(name: String? = nil, list: S) where S.Element == Object? {
        self.init(name: name, list: list.enumerated().map{ (i, o) in (IntList(i), o) })
    }
    
    public subscript(i: Int) -> Object? {
        get {
            return self[IntList(i)]
        } set {
            self[IntList(i)] = newValue
        }
    }
    
    public var nonZeroDegrees: [Int] {
        return _nonZeroDegrees.map{ I in I[0] }
    }
    
    public var bottomDegree: Int {
        return nonZeroDegrees.min() ?? 0
    }
    
    public var topDegree: Int {
        return nonZeroDegrees.max() ?? 0
    }
    
    public func shifted(_ i: Int) -> GradedModuleStructure<A, R> {
        return shifted(IntList(i))
    }
    
    public func asChainComplex(degree: Int, d: @escaping (Int, A) -> FreeModule<A, R>) -> GradedChainComplex<A, R> {
        return asChainComplex(degree: IntList(degree), d: {(I, a) in d(I[0], a)})
    }
    
    public func describe(_ i: Int) {
        describe(IntList(i))
    }
}

public extension _GradedModuleStructure where Dim == _2 {
    public init<S: Sequence>(name: String? = nil, list: S) where S.Element == (Int, Int, [A]?) {
        self.init(name: name, list: list.map{ (i, j, basis) in (IntList(i, j), basis) })
    }
    
    public init<S: Sequence>(name: String? = nil, list: S) where S.Element == (Int, Int, Object?) {
        self.init(name: name, list: list.map{ (i, j, o) in (IntList(i, j), o) })
    }
    
    public subscript(i: Int, j: Int) -> Object? {
        get {
            return self[IntList(i, j)]
        } set {
            self[IntList(i, j)] = newValue
        }
    }
    
    public var nonZeroDegrees: [(Int, Int)] {
        return _nonZeroDegrees.map{ I in (I[0], I[1]) }
    }
    
    public func shifted(_ i: Int, _ j: Int) -> BigradedModuleStructure<A, R> {
        return shifted(IntList(i, j))
    }
    
    public func asChainComplex(degree: (Int, Int), d: @escaping (Int, Int, A) -> FreeModule<A, R>) -> BigradedChainComplex<A, R> {
        return asChainComplex(degree: IntList(degree.0, degree.1), d: {(I, a) in d(I[0], I[1], a)})
    }

    public func describe(_ i: Int, _ j: Int) {
        describe(IntList(i, j))
    }
}
