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
        assert(Kh.validDegrees.forAll{ (i, j) in Kh[i, j].isFree })
        self.Kh = Kh
    }
    
    public subscript(i: Int, j: Int) -> AbstractSimpleModuleStructure<R> {
        var (Ain, Aout) = (matrix(i - 1, j - 4), matrix(i, j))
        let (Ein, Eout) = (Ain.eliminate(form: .Smith), Aout.eliminate(form: .Smith))
        return SimpleModuleStructure(
            basis:            Kh[i, j].generators.enumerated().map{ AbstractBasisElement($0.0) },
            generatingMatrix: Eout.kernelMatrix,
            relationMatrix:    Ein.imageMatrix,
            transitionMatrix: Eout.kernelTransitionMatrix
        )
    }
    
    private func matrix(_ i: Int, _ j: Int) -> Matrix<R> {
        if let A = matrices[IntList(i, j)] {
            return A
        }
        
        let (from, to) = (Kh[i, j], Kh[i + 1, j + 4])
        let (μL, ΔL) = (KhBasisElement.μL, KhBasisElement.ΔL)
        let grid = from.generators.flatMap { x -> [R] in
            let y = Kh.cube.map(x, μL, ΔL)
            return to.factorize(y)
        }
        
        let A = Matrix(rows: from.generators.count, cols: to.generators.count, grid: grid).transposed
        matrices[IntList(i, j)] = A
        return A
    }
    
    public var table: KhHomology<R>.Table<AbstractSimpleModuleStructure<R>> {
        return KhHomology.Table(components: Kh.validDegrees.map{ (i, j) in (i, j, self[i, j]) })
    }
    
    public var structureCode: String {
        return Kh.validDegrees.map{ (i, j) in
            let s = self[i, j]
            let f = (s.rank > 0) ? "0\(Format.sup(s.rank))₍\(Format.sub(i)),\(Format.sub(j))₎" : ""
            let t = s.torsionCoeffs.countMultiplicities().map{ (d, r) in
                "\(d)\(Format.sup(r))₍\(Format.sub(i)),\(Format.sub(j))₎"
                }.joined()
            return f + t
            }.joined()
    }
}
