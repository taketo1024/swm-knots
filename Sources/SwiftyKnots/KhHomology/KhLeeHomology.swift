//
//  KhLeeHomology.swift
//  SwiftyKnotsTests
//
//  Created by Taketo Sano on 2018/05/08.
//

import Foundation
import SwiftyMath

public final class KhLeeHomology<R: EuclideanRing> {
    
    private let Kh: KhHomology<R>
    private var matrices: [IntList: Matrix<R>] = [:]
    
    public init(_ Kh: KhHomology<R>) {
        self.Kh = Kh
    }
    
    public subscript(i: Int, j: Int) -> AbstractSimpleModuleStructure<R> {
        // MEMO currently supports only free cases.
        assert(Kh.validDegrees.forAll{ (i, j) in Kh[i, j].isFree })
        
        var (Ain, Aout) = (matrix(i - 1, j - 4), matrix(i, j))
        let (Ein, Eout) = (Ain.eliminate(form: .Smith), Aout.eliminate(form: .Smith))
        return SimpleModuleStructure(
            basis: Kh[i, j].generators.enumerated().map{ AbstractBasisElement($0.0) },
            generatingMatrix: Eout.kernelMatrix,
            transitionMatrix: Eout.kernelTransitionMatrix,
            relationMatrix:   Eout.kernelTransitionMatrix * Ein.imageMatrix
        )
    }
    
    private func matrix(_ i: Int, _ j: Int) -> Matrix<R> {
        if let A = matrices[IntList(i, j)] {
            return A
        }
        
        let (from, to) = (Kh[i, j], Kh[i + 1, j + 4])
        let grid = from.generators.flatMap { x -> [R] in
            let cube = Kh.link.KhCube
            let y = cube.map(x, KhBasisElement.μ_Lee, KhBasisElement.Δ_Lee)
            return to.factorize(y)
        }
        
        let A = Matrix(rows: from.generators.count, cols: to.generators.count, grid: grid).transposed
        matrices[IntList(i, j)] = A
        return A
    }
    
    public var validDegrees: [(Int, Int)] {
        return Kh.validDegrees
    }
    
    public var splits: Bool {
        return validDegrees.forAll { (i, j) -> Bool in
            let (from, to) = (Kh[i, j].freePart, Kh[i + 1, j + 4].torsionPart)
            if from.isTrivial || to.isTrivial {
                return true
            }
            
            let res = from.generators.forAll{ x in
                let cube = Kh.link.KhCube
                let y = cube.map(x, KhBasisElement.μ_Lee, KhBasisElement.Δ_Lee)
                return to.factorize(y).forAll{ $0 == .zero }
            }
            
            // MEMO for experiments
            if res {
                print(Kh.link, (i, j), from, " -> ", to, ": zero")
            } else {
                print(Kh.link, (i, j), from, " -> ", to, ": non-zero")
            }
            
            return res
        }
    }
    
    public var table: KhHomology<R>.Table<AbstractSimpleModuleStructure<R>> {
        return KhHomology.Table(components: validDegrees.map{ (i, j) in (i, j, self[i, j]) })
    }
    
    public var structureCode: String {
        return validDegrees.map{ (i, j) in
            let s = self[i, j]
            let f = (s.rank > 0) ? "0\(Format.sup(s.rank))₍\(Format.sub(i)),\(Format.sub(j))₎" : ""
            let t = s.torsionCoeffs.countMultiplicities().map{ (d, r) in
                "\(d)\(Format.sup(r))₍\(Format.sub(i)),\(Format.sub(j))₎"
                }.joined()
            return f + t
            }.joined()
    }
}
