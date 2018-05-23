//
//  GradedChainComplex.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/21.
//

import Foundation
import SwiftyMath

// TODO substitute for old ChainComplex.

public typealias ChainComplex<A: BasisElementType, R: EuclideanRing> = MultigradedChainComplex<_1, A, R>
public typealias BigradedChainComplex<A: BasisElementType, R: EuclideanRing> = MultigradedChainComplex<_2, A, R>

public struct MultigradedChainComplex<Dim: _Int, A: BasisElementType, R: EuclideanRing> {
    public typealias Base = MultigradedModuleStructure<Dim, A, R>
    public var base: Base
    
    public let d: MultigradedModuleHom<Dim, A, A, R>
    internal let dMatrices: [IntList : Cache<Matrix<R>>]
    
    public init(base: MultigradedModuleStructure<Dim, A, R>, degree: IntList, differential d: @escaping (IntList, A) -> FreeModule<A, R>) {
        self.base = base
        self.d = MultigradedModuleHom(degree: degree, func: d)
        
        let degs = base.nonZeroMultiDegrees.flatMap{ I in [I, I - degree] }.unique()
        self.dMatrices = Dictionary(pairs: degs.map{ I in (I, .empty) })
    }
    
    public subscript(I: IntList) -> Base.Object? {
        get {
            return base[I]
        } set {
            base[I] = newValue
        }
    }
    
    internal func dMatrix(_ I: IntList) -> Matrix<R>? {
        if let c = dMatrices[I], let A = c.value {
            return A // cached.
        }

        let A = d.matrix(from: self, to: self, at: I)
        dMatrices[I]?.value = A
        return A
    }
    
    internal func kernel(_ I: IntList) -> Matrix<R>? {
        guard let from = base[I], from.isFree,
            let to = base[I + d.degree], to.isFree,
            let A = dMatrix(I) else {
                return nil // indeterminable.
        }
        
        let E = A.elimination(form: .Diagonal)
        return E.kernelMatrix
    }
    
    internal func kernelTransition(_ I: IntList) -> Matrix<R>? {
        guard let from = base[I], from.isFree,
            let to = base[I + d.degree], to.isFree,
            let A = dMatrix(I) else {
                return nil // indeterminable.
        }
        
        let E = A.elimination(form: .Diagonal)
        return E.kernelTransitionMatrix
    }
    
    internal func image(_ I: IntList) -> Matrix<R>? {
        guard let from = base[I], from.isFree,
            let to = base[I + d.degree], to.isFree,
            let A = dMatrix(I) else {
                return nil // indeterminable.
        }
        
        let E = A.elimination(form: .Diagonal)
        return E.imageMatrix
    }
    
    internal func homology(_ I: IntList) -> SimpleModuleStructure<A, R>? {
        guard let basis = base[I]?.generators,
              let Z = kernel(I),
              let T = kernelTransition(I),
              let B = image(I - d.degree)
            else {
            return nil // indeterminable.
        }
        
        return SimpleModuleStructure(
            basis: basis,
            generatingMatrix: Z,
            transitionMatrix: T,
            relationMatrix: T * B
        )
    }
    
    public func homology(name: String? = nil) -> MultigradedModuleStructure<Dim, A, R> {
        return MultigradedModuleStructure(
            name: name ?? "H(\(base.name))",
            list: base.nonZeroMultiDegrees.map{ I in (I, homology(I)) }
        )
    }
    
    public var isExact: Bool {
        return homology().isTrivial
    }
    
    // MEMO works only when each generator is a single basis-element.
    
    public func dual(name: String? = nil) -> MultigradedChainComplex<Dim, Dual<A>, R> {
        let dName = name ?? "\(base.name)^*"
        let dList: [(IntList, [Dual<A>]?)] = base.nonZeroMultiDegrees.map { I -> (IntList, [Dual<A>]?) in
            guard let o = self[I] else {
                return (I, nil)
            }
            guard o.isFree, o.generators.forAll({ $0.basis.count == 1 }) else {
                fatalError("inavailable")
            }
            return (I, o.generators.map{ $0.basis.first!.dual })
        }
        
        let dBase = MultigradedModuleStructure<Dim, Dual<A>, R>(name: dName, list: dList)
        return dBase.asChainComplex(degree: -d.degree) { (I0, x) in
            let I1 = I0 - self.d.degree
            guard let current = dBase[I0],
                let target = dBase[I1],
                let matrix = self.dMatrix(I1)?.transposed else {
                    return .zero
            }
            
            guard let j = current.generators.index(where: { $0 == FreeModule(x) }) else {
                fatalError()
            }
            
            return matrix.nonZeroComponents(ofCol: j).sum { (c: MatrixComponent<R>) in
                let (i, r) = (c.row, c.value)
                return r * target.generator(i)
            }
        }
    }
    
    public func assertChainComplex(debug: Bool = false) {
        func print(_ msg: @autoclosure () -> String) {
            Swift.print(msg())
        }
        
        for I0 in base.nonZeroMultiDegrees {
            let I1 = I0 + d.degree
            let I2 = I1 + d.degree
            
            guard let A0 = dMatrix(I0),
                  let A1 = dMatrix(I1) else {
                    print("\(I0): undeterminable.")
                    continue
            }
            
            if debug {
                let (s0, s1, s2) = (self[I0]!, self[I1]!, self[I2]!)
                
                print("\(I0): \(s0) -> \(s1) -> \(s2)")
                
                for x in s0.generators {
                    let y = d[I0](x)
                    let z = d[I1](y)
                    print("\t\(x) ->\t\(y) ->\t\(z)")
                }
                print("")
            }
            
            assert((A1 * A0).isZero)
        }
    }
    
    public func assertChainMap<B>(_ f: MultigradedModuleHom<Dim, A, B, R>, to: MultigradedChainComplex<Dim, B, R>, debug: Bool = false) {
        //          d0
        //   C[I0] -----> C[I1]
        //     |          |
        //   f |          | f
        //     v          v
        //  C'[I2] ---> C'[I3]
        //          d1
        
        func print(_ msg: @autoclosure () -> String) {
            Swift.print(msg())
        }
        
        assert(self.d.degree == to.d.degree)
        
        for I0 in base.nonZeroMultiDegrees {
            let (I1, I2, I3) = (I0 + d.degree, I0 + f.degree, I0 + d.degree + f.degree)
            
            guard let D0 = dMatrix(I0),
                  let D1 = to.dMatrix(I2),
                  let F0 = f.matrix(from: self, to: to, at: I0),
                  let F1 = f.matrix(from: self, to: to, at: I1) else {
                    print("\(I0): undeterminable.")
                    continue
            }
            
            if debug {
                let (s0, s1, s2, s3) = (self[I0]!, self[I1]!, to[I2]!, to[I3]!)
                print("\(I0): \(s0) -> \(s1) -> \(s3)")

                for x in s0.generators {
                    let y = d[I0](x)
                    let z = f[I1](y)
                    print("\t\(x) ->\t\(y) ->\t\(z)")
                }

                print("\(I0): \(s0) -> \(s2) -> \(s3)")
                
                for x in s0.generators {
                    let y = f[I0](x)
                    let z = to.d[I2](y)
                    print("\t\(x) ->\t\(y) ->\t\(z)")
                }
                
                print("")
            }
            
            assert(F1 * D0 == D1 * F0)
        }
    }
    
    public func describe(_ I: IntList) {
        base.describe(I)
    }
    
    public func describeMap(_ I: IntList) {
        print("\(I) \(self[I]?.description ?? "?") -> \(self[I + d.degree]?.description ?? "?")")
        if let A = dMatrix(I) {
            print("\n", A.detailDescription)
        }
    }
}

public extension MultigradedChainComplex where Dim == _1 {
    public func homology(_ i: Int) -> SimpleModuleStructure<A, R>? {
        return homology(IntList(i))
    }
    
    public func describe(_ i: Int) {
        describe(IntList(i))
    }
    
    public func describeMap(_ i: Int) {
        describeMap(IntList(i))
    }
}

public extension MultigradedChainComplex where Dim == _2 {
    public func homology(_ i: Int, _ j: Int) -> SimpleModuleStructure<A, R>? {
        return homology(IntList(i, j))
    }
    
    public func describe(_ i: Int, _ j: Int) {
        describe(IntList(i, j))
    }
    
    public func describeMap(_ i: Int, _ j: Int) {
        describeMap(IntList(i, j))
    }
    
    public func printTable() {
        base.printTable()
    }
}
