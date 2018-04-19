//
//  KhHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public extension Link {
    public func KhHomology<R: EuclideanRing>(_ type: R.Type) -> Cohomology<KhTensorElement, R> {
        let name = "Kh(\(self.name); \(R.symbol))"
        let C = self.KhChainComplex(R.self)
        return Cohomology(name: name, chainComplex: C)
    }
}

public typealias KhHomology<R: EuclideanRing> = Cohomology<KhTensorElement, R>
public extension KhHomology where T == Ascending, A == KhTensorElement, R: EuclideanRing {
    public subscript(i: Int, j: Int) -> Summand {
        let filtered = self[i].summands.enumerated().compactMap{ (k, s) in
            (s.degree == j) ? (k, s) : nil
        }
        
        let indices  = filtered.map{ $0.0 }
        let summands = filtered.map{ $0.1 }
        
        let f = { (x: FreeModule<A, R>) -> [R] in
            let y = self[i].factorize(x)
            return indices.map{ k in y[k] }
        }
        
        let str = SimpleModuleStructure(summands, f)
        return Summand(self, str)
    }
    
    public var validDegrees: [(Int, Int)] {
        return (offset ... topDegree).flatMap { i in
            self[i].summands.map{ $0.generator.degree }.unique().sorted().map{ j in (i, j) }
        }
    }
    
    public var isHThin: Bool {
        let degs = validDegrees
        if degs.isEmpty { return true }
        
        let (i0, j0) = (degs.map{ $0.0 }.min()!, degs.map{ $0.1 }.min()!)
        return degs.forAll { (i, j) -> Bool in
            (j == 2 * (i - i0) + j0) || (j == 2 * (i - i0 + 1) + j0)
        }
    }
    
    public func printTable(detail: Bool = false) {
        let cols = (offset ... topDegree).toArray()
        let degs = cols.flatMap{ i in self[i].summands.map{ $0.degree} }.unique()
        
        guard let j0 = degs.min(), let j1 = degs.max() else {
            return
        }
        
        let rows = (j0 ... j1).filter{ ($0 - j0).isEven }.reversed().toArray()
        Format.printTable("j\\i", rows: rows, cols: cols) { (j, i) -> String in
            let s = self[i, j]
            return s.isTrivial ? "" : "\(s)"
        }
        
        if detail {
            for (i, j) in validDegrees {
                print((i, j))
                for s in self[i, j].summands {
                    print("\t", s, "\t", s.generator)
                }
                print()
            }
        }
    }

    public func KhLee(_ i: Int, _ j: Int) -> (AbstractSimpleModuleStructure<R>, AbstractSimpleModuleStructure<𝐙₂>)? {
        let (prev, this, next) = (self[i - 1, j - 4], self[i, j], self[i + 1, j + 4])
        
//        print((i, j))
//        print(prev, "\t->\t[", this, "]\t->\t", next, "\n")
        
        func matrix(from: Summand, to: Summand) -> ComputationalMatrix<R> {
            let (μL, ΔL) = (KhBasisElement.μL, KhBasisElement.ΔL)
            let grid = from.generators.flatMap { g -> [R] in
                let x = g.representative
                let y = x.sum { (e, r) in
                    r * e.transit(μL, ΔL)
                }
                return to.factorize(y)
            }
            return ComputationalMatrix(rows: from.generators.count, cols: to.generators.count, grid: grid).transpose()
        }
        
        func eliminate(from: Summand, to: Summand, matrix A: ComputationalMatrix<R>) -> (MatrixEliminationResult<R>, MatrixEliminationResult<𝐙₂>)? {
            let a1 = from.torsionCoeffs.count
            let a2 = to.torsionCoeffs.count
            
            guard A.submatrix(a2 ..< A.rows, 0 ..< a1).isZero else {
                print((i, j), ": undecidable")
                return nil
            }
            
            let B = A.submatrix(a2 ..< A.rows, a1 ..< A.cols) // freePart
            let C = A.submatrix(0 ..< a2, 0 ..< a1)           // torsionPart
            
            guard C.isZero || (R.self == 𝐙.self && (from.torsionCoeffs + to.torsionCoeffs).forAll{ $0 == R(from: 2) }) else {
                print((i, j), ": only 𝐙 with order-2 torsions are computable.", A.detailDescription)
                return nil
            }
            
            let X = B.eliminate(form: .Smith)
            let Y = C.mapValues{ 𝐙₂(from: $0 as! 𝐙)}.eliminate(form: .Smith)

            return (X, Y)
        }
        
        let Ain  = matrix(from: prev, to: this)
        let Aout = matrix(from: this, to: next)
        
//        print("In: \n",  Ain.asDynamicMatrix().detailDescription, "\n")
//        print("Out:\n", Aout.asDynamicMatrix().detailDescription, "\n")
        
        guard let Ein  = eliminate(from: prev, to: this, matrix: Ain),
              let Eout = eliminate(from: this, to: next, matrix: Aout) else {
                return nil
        }
        
        let S1 = SimpleModuleStructure.invariantFactorDecomposition(
            generators:       this.summands.enumerated().filter{ $0.1.isFree }.map{ AbstractBasisElement($0.0) },
            generatingMatrix: Eout.0.kernelMatrix,
            relationMatrix:    Ein.0.imageMatrix,
            transitionMatrix: Eout.0.kernelTransitionMatrix
        )
        
        let S2 = SimpleModuleStructure.invariantFactorDecomposition(
            generators:       this.summands.enumerated().filter{ !$0.1.isFree }.map{ AbstractBasisElement($0.0) },
            generatingMatrix: Eout.1.kernelMatrix,
            relationMatrix:    Ein.1.imageMatrix,
            transitionMatrix: Eout.1.kernelTransitionMatrix
        )
        
        return (S1, S2)
    }
    
    public func printKhLeeTable() {
        let cols = (offset ... topDegree).toArray()
        let degs = cols.flatMap{ i in self[i].summands.map{ $0.degree } }.unique()
        
        guard let j0 = degs.min(), let j1 = degs.max() else {
            return
        }
        
        let rows = (j0 ... j1).filter{ ($0 - j0).isEven }.reversed().toArray()
        Format.printTable("j\\i", rows: rows, cols: cols) { (j, i) -> String in
            let s = self.KhLee(i, j)
            return s.flatMap{ (s1, s2) in
                switch (s1.isTrivial, s2.isTrivial) {
                case (true , true ): return ""
                case (false, true ): return s1.description
                case (true , false): return s2.description
                default            : return s1.description + "⊕" + s2.description
                }
            } ?? "?"
        }
    }
}
