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
    
    internal func _asChainComplex(degree: IntList, d: @escaping (IntList, A) -> FreeModule<A, R>) -> _GradedChainComplex<Dim, A, R> {
        return _GradedChainComplex(base: self, degree: degree, map: d)
    }
    
    internal func _describe(_ I: IntList) {
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
    
    public var description: String {
        return "\(name) {\n\( _nonZeroDegrees.map{ I in "\t\(I) " + (self[I]?.description ?? "?") }.joined(separator: ",\n"))\n}"
    }
}

public extension _GradedModuleStructure where Dim == _1 {
    public init<S: Sequence>(name: String? = nil, list: S) where S.Element == [A] {
        let pairs = list.enumerated().map{ (i, basis) in
            (IntList(i), Object(generators: basis))
        }
        self.init(name: name, grid: Dictionary(pairs: pairs))
    }
    
    public init<S: Sequence>(name: String? = nil, list: S) where S.Element == Object {
        let pairs = list.enumerated().map{ (i, o) in (IntList(i), o) }
        self.init(name: name, grid: Dictionary(pairs: pairs))
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
    
    public func asChainComplex(degree: Int, d: @escaping (Int, A) -> FreeModule<A, R>) -> GradedChainComplex<A, R> {
        return _asChainComplex(degree: IntList(degree), d: {(I, a) in d(I[0], a)})
    }
    
    public func describe(_ i: Int) {
        _describe(IntList(i))
    }
}

public extension _GradedModuleStructure where Dim == _2 {
    public init<S: Sequence>(name: String? = nil, list: S) where S.Element == (Int, Int, Object) {
        self.init(name: name, grid: Dictionary(pairs: list.map{ (i, j, o) in (IntList(i, j), o) }))
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
    
    public func asChainComplex(degree: (Int, Int), d: @escaping (Int, Int, A) -> FreeModule<A, R>) -> BigradedChainComplex<A, R> {
        return _asChainComplex(degree: IntList(degree.0, degree.1), d: {(I, a) in d(I[0], I[1], a)})
    }

    public func describe(_ i: Int, _ j: Int) {
        _describe(IntList(i, j))
    }
}
