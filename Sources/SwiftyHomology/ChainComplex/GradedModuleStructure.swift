//
//  GradedModuleStructure.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/18.
//

import Foundation
import SwiftyMath

public typealias GradedModuleStructure<A: BasisElementType, R: EuclideanRing> = MultigradedModuleStructure<_1, A, R>
public typealias BigradedModuleStructure<A: BasisElementType, R: EuclideanRing> = MultigradedModuleStructure<_2, A, R>

public struct MultigradedModuleStructure<Dim: _Int, A: BasisElementType, R: EuclideanRing>: CustomStringConvertible {
    public typealias Object = SimpleModuleStructure<A, R>
    
    public let name: String
    internal var grid: [IntList : Object?]
    
    public init(name: String? = nil, grid: [IntList : Object?]) {
        self.name = name ?? ""
        self.grid = grid.exclude{ $0.value?.isTrivial ?? false }
    }
    
    public init<S: Sequence>(name: String? = nil, list: S) where S.Element == (IntList, Object?) {
        self.init(name: name, grid: Dictionary(pairs: list))
    }
    
    public init<S: Sequence>(name: String? = nil, list: S) where S.Element == (IntList, [A]?) {
        self.init(name: name, grid: Dictionary(pairs: list.map{ (I, basis) in
            (I, basis.map{ Object(generators: $0) })
        }))
    }
    
    public subscript(I: IntList) -> Object? {
        get {
            return grid[I] ?? .zeroModule
        } set {
            grid[I] = newValue
        }
    }
    
    public var gradingDim: Int {
        return Dim.intValue
    }
    
    public var nonZeroMultiDegrees: [IntList] {
        return grid.keys.sorted()
    }
    
    public var isDetermined: Bool {
        return grid.values.forAll{ $0 != nil }
    }
    
    public func shifted(_ I: IntList) -> MultigradedModuleStructure<Dim, A, R> {
        return MultigradedModuleStructure(name: name, grid: grid.mapKeys{ $0 + I} )
    }
    
    public func asChainComplex(degree: IntList, d: @escaping (IntList, A) -> FreeModule<A, R>) -> MultigradedChainComplex<Dim, A, R> {
        return MultigradedChainComplex(base: self, degree: degree, map: d)
    }
    
    public func describe(_ I: IntList) {
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
        for I in nonZeroMultiDegrees {
            describe(I)
        }
    }
    
    public var description: String {
        return "\(name) {\n\( nonZeroMultiDegrees.map{ I in "\t\(I) " + (self[I]?.description ?? "?") }.joined(separator: ",\n"))\n}"
    }
}

public extension MultigradedModuleStructure where Dim == _1 {
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
        return nonZeroMultiDegrees.map{ I in I[0] }
    }
    
    public var bottomDegree: Int {
        return nonZeroDegrees.min() ?? 0
    }
    
    public var topDegree: Int {
        return nonZeroDegrees.max() ?? 0
    }
    
    public func bettiNumer(_ i: Int) -> Int? {
        return self[i]?.rank
    }
    
    public var eulerCharacteristic: Int {
        return nonZeroDegrees.sum{ i in (-1).pow(i) * bettiNumer(i)! }
    }
    
    public func shifted(_ i: Int) -> GradedModuleStructure<A, R> {
        return shifted(IntList(i))
    }
    
    public func asChainComplex(degree: Int, d: @escaping (Int, A) -> FreeModule<A, R>) -> ChainComplex<A, R> {
        return asChainComplex(degree: IntList(degree), d: {(I, a) in d(I[0], a)})
    }
    
    public func describe(_ i: Int) {
        describe(IntList(i))
    }
}

public extension MultigradedModuleStructure where Dim == _2 {
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
        return nonZeroMultiDegrees.map{ I in (I[0], I[1]) }
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
    
    public func printTable() {
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
            if let o = self[i, j] {
                return !o.isTrivial ? o.description : ""
            } else {
                return "?"
            }
        }
        
        print(table)
    }
}

public extension MultigradedModuleStructure where R == 𝐙 {
    public var structureCode: String {
        return nonZeroMultiDegrees.map{ I in
            if let s = self[I] {
                return "\(I): \(s.structureCode)"
            } else {
                return "\(I): ?"
            }
        }.joined(separator: ", ")
    }
}
