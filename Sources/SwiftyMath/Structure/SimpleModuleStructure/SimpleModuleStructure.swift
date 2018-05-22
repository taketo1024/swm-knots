//
//  ModuleDecomposition.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/11/06.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// A decomposed form of a freely & finitely presented module,
// i.e. a module with finite generators and a finite & free presentation.
//
//   M = (R/d_0 ⊕ ... ⊕ R/d_k) ⊕ R^r  ( d_i: torsion-coeffs, r: rank )
//
// See: https://en.wikipedia.org/wiki/Free_presentation
//      https://en.wikipedia.org/wiki/Structure_theorem_for_finitely_generated_modules_over_a_principal_ideal_domain#Invariant_factor_decomposition

public final class SimpleModuleStructure<A: BasisElementType, R: Ring>: ModuleStructure<R> {
    public let summands: [Summand]
    
    // MEMO values used for factorization where R: EuclideanRing
    internal let basis: [A]
    internal let transform: Matrix<R>
    
    // root initializer
    internal init(_ summands: [Summand], _ basis: [A], _ transform: Matrix<R>) {
        self.summands = summands
        self.basis = basis
        self.transform = transform
        
        super.init()
    }
    
    public subscript(i: Int) -> Summand {
        return summands[i]
    }
    
    public static var zeroModule: SimpleModuleStructure<A, R> {
        return SimpleModuleStructure([], [], Matrix.zero(rows: 0, cols: 0))
    }
    
    public var isTrivial: Bool {
        return summands.isEmpty
    }
    
    public var isFree: Bool {
        return summands.forAll { $0.isFree }
    }
    
    public var rank: Int {
        return summands.filter{ $0.isFree }.count
    }
    
    public var torsionCoeffs: [R] {
        return summands.filter{ !$0.isFree }.map{ $0.divisor }
    }
    
    public var generators: [FreeModule<A, R>] {
        return summands.map{ $0.generator }
    }
    
    public func generator(_ i: Int) -> FreeModule<A, R> {
        return summands[i].generator
    }
    
    public var freePart: SimpleModuleStructure<A, R> {
        let indices = (0 ..< summands.count).filter{ i in self[i].isFree }
        return subSummands(indices: indices)
    }
    
    public var torsionPart: SimpleModuleStructure<A, R> {
        let indices = (0 ..< summands.count).filter{ i in !self[i].isFree }
        return subSummands(indices: indices)
    }
    
    public func subSummands(_ indices: Int ...) -> SimpleModuleStructure<A, R> {
        return subSummands(indices: indices)
    }
    
    public func subSummands(indices: [Int]) -> SimpleModuleStructure<A, R> {
        let sub = indices.map{ summands[$0] }
        let T = transform.submatrix({ i in indices.contains(i)}, { _ in true })
        return SimpleModuleStructure(sub, basis, T)
    }
    
    public static func ==(a: SimpleModuleStructure<A, R>, b: SimpleModuleStructure<A, R>) -> Bool {
        return a.summands == b.summands
    }
    
    public override var description: String {
        if summands.isEmpty {
            return "0"
        }
        
        let f = (rank > 0) ? ["\(R.symbol)\(rank > 1 ? Format.sup(rank) : "")"] : []
        let t = torsionCoeffs.countMultiplicities().map{ (d, r) in
            "\(R.symbol)/\(d)\(r > 1 ? Format.sup(r) : "")"
        }
        return (t + f).joined(separator: "⊕")
    }
    
    public var detailDescription: String {
        return "\(self),\t\(generators)"
    }
    
    public final class Summand: AlgebraicStructure {
        public let generator: FreeModule<A, R>
        public let divisor: R
        
        internal init(_ generator: FreeModule<A, R>, _ divisor: R) {
            self.generator = generator
            self.divisor = divisor
        }
        
        internal convenience init(_ a: A, _ divisor: R) {
            self.init(FreeModule(a), divisor)
        }
        
        public var isFree: Bool {
            return divisor == .zero
        }
        
        public var degree: Int {
            return generator.degree
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

extension SimpleModuleStructure: Codable where A: Codable, R: Codable {
    enum CodingKeys: String, CodingKey {
        case summands, basis, transform
    }
    
    public convenience init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let summands = try c.decode([Summand].self, forKey: .summands)
        let basis = try c.decode([A].self, forKey: .basis)
        let trans = try c.decode(Matrix<R>.self, forKey: .transform)
        self.init(summands, basis, trans)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(summands, forKey: .summands)
        try c.encode(basis, forKey: .basis)
        try c.encode(transform, forKey: .transform)
    }
}

extension SimpleModuleStructure.Summand: Codable where A: Codable, R: Codable {
    enum CodingKeys: String, CodingKey {
        case generator, divisor
    }
    
    public convenience init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let g = try c.decode(FreeModule<A, R>.self, forKey: .generator)
        let d = try c.decode(R.self, forKey: .divisor)
        self.init(g, d)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(generator, forKey: .generator)
        try c.encode(divisor, forKey: .divisor)
    }
}
