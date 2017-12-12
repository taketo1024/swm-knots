//
//  ModuleDecomposition.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/11/06.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// A decomposed form of a freely & finitely presented module over a PID,
// i.e. a module with finite generators and a finite & free presentation.
//
// See: https://en.wikipedia.org/wiki/Free_presentation
//      https://en.wikipedia.org/wiki/Structure_theorem_for_finitely_generated_modules_over_a_principal_ideal_domain#Invariant_factor_decomposition

public final class DecomposedModuleStructure<A: FreeModuleBase, R: EuclideanRing>: ModuleStructure<R>, Sequence {
    private let generators: [A]
    public let summands: [Summand]
    public let transitionMatrix: ComputationalMatrix<R> // oldBasis -> newBasis
    
    public init(generators: [A], summands: [Summand], transitionMatrix: ComputationalMatrix<R>) {
        self.generators = generators
        self.summands = summands
        self.transitionMatrix = transitionMatrix
        super.init()
    }
    
    public subscript(i: Int) -> Summand {
        return summands[i]
    }
    
    public var isTrivial: Bool {
        return summands.isEmpty
    }
    
    public var isFree: Bool {
        return summands.forAll { $0.isFree } 
    }
    
    public var rank: Int {
        return self.filter{ $0.isFree }.count
    }
    
    public func generator(_ i: Int) -> FreeModule<A, R> {
        return summands[i].generator
    }
    
    public func torsion(_ i: Int) -> R {
        return summands[i].divisor
    }
    
    public func factorize(_ z: FreeModule<A, R>) -> [R] {
        let n = generators.count
        let v = transitionMatrix * ComputationalMatrix(rows: n, cols: 1, grid: z.factorize(by: generators))

        return summands.enumerated().map { (i, s) in
            return s.isFree ? v[i, 0] : v[i, 0] % s.divisor
        }
    }
    
    public func elementIsZero(_ z: FreeModule<A, R>) -> Bool {
        return factorize(z).forAll{ $0 == 0 }
    }
    
    public func elementsAreEqual(_ z1: FreeModule<A, R>, _ z2: FreeModule<A, R>) -> Bool {
        return elementIsZero(z1 - z2)
    }
    
    public func makeIterator() -> IndexingIterator<[Summand]> {
        return summands.makeIterator()
    }
    
    public static func ==(a: DecomposedModuleStructure<A, R>, b: DecomposedModuleStructure<A, R>) -> Bool {
        return a.summands == b.summands
    }
    
    public override var description: String {
        return summands.isEmpty ? "0" : summands.map{$0.description}.joined(separator: "⊕")
    }
    
    public var detailDescription: String {
        return "\(self),\t\(self.map{ $0.generator })"
    }
    
    public final class Summand: AlgebraicStructure {
        public let generator: FreeModule<A, R>
        public let divisor: R
        
        internal init(_ generator: FreeModule<A, R>, _ divisor: R) {
            self.generator = generator
            self.divisor = divisor
        }
        
        public var isFree: Bool {
            return divisor == R.zero
        }
        
        public static func ==(a: Summand, b: Summand) -> Bool {
            return (a.generator, a.divisor) == (b.generator, b.divisor)
        }
        
        public var description: String {
            switch isFree {
            case true : return R.symbol
            case false: return "\(R.symbol)/\(divisor)"
            }
        }
    }
}
