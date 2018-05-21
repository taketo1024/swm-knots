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
    
    // MEMO values used for factorization.
    private let basis: [A]
    private let transform: Matrix<R>
    
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
    
    public var asAbstract: AbstractSimpleModuleStructure<R> {
        let torsions = summands.filter{!$0.isFree}.map{$0.divisor}
        return AbstractSimpleModuleStructure(rank: rank, torsions: torsions)
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

public extension SimpleModuleStructure where R: EuclideanRing {
    public convenience init(generators: [A], relationMatrix B: Matrix<R>? = nil) {
        let I = Matrix<R>.identity(size: generators.count)
        self.init(basis: generators, generatingMatrix: I, transitionMatrix: I, relationMatrix: B)
    }
    
    // TODO must consider when `generators` does not form a subbasis of R^n
    // e.g) generators = [(2, 0), (0, 2)]
    
    public convenience init(generators: [FreeModule<A, R>], relationMatrix B: Matrix<R>? = nil) {
        let basis = generators.flatMap{ $0.basis }.unique().sorted()
        let A = Matrix(rows: basis.count, cols: generators.count) { (i, j) in generators[j][basis[i]] }
        let T = A.elimination(form: .RowEchelon).left.submatrix(rowRange: 0 ..< generators.count)
        self.init(basis: basis, generatingMatrix: A, transitionMatrix: T, relationMatrix: B)
    }
    
    /*
     *                 R^n
     *                 ^|
     *                A||T
     *             B   |v
     *  0 -> R^l >---> R^k --->> M -> 0
     *        ^        ^|
     *        |       P||
     *        |    D   |v
     *  0 -> R^l >---> R^k --->> M' -> 0
     *
     */
    public convenience init(basis: [A], generatingMatrix A: Matrix<R>, transitionMatrix T:Matrix<R>, relationMatrix _B: Matrix<R>?) {
        
        let B = _B ?? Matrix.zero(rows: A.cols, cols: 0)
        
        let (n, k, l) = (A.rows, A.cols, B.cols)
        
        assert(n == basis.count)
        assert(k == B.rows)
        assert(n >= k)
        assert(k >= l)
        
        let elim = B.elimination(form: .Smith)
        
        let D = elim.diagonal + [.zero].repeated(k - l)
        let s = D.count{ $0 != .identity }
        
        let A2 = A * elim.leftInverse.submatrix(colRange: (k - s) ..< k)
        let T2 = (elim.left * T).submatrix(rowRange: (k - s) ..< k)
        
        // MEMO see TODO above.
        assert(T2 * A2 == Matrix<R>.identity(size: s))
        
        let summands = (0 ..< s)
            .map { j -> Summand in
                let d = D[k - s + j]
                let g = A2.nonZeroComponents(ofCol: j).sum { c in
                    FreeModule(basis[c.row], c.value)
                }
                return Summand(g, d)
            }
        
        
        self.init(summands, basis, T2)
    }
    
    public func factorize(_ z: FreeModule<A, R>) -> [R] {
        let v = transform * Vector(z.factorize(by: basis))
        
        return summands.enumerated().map { (i, s) in
            return s.isFree ? v[i] : v[i] % s.divisor
        }
    }
    
    public func elementIsZero(_ z: FreeModule<A, R>) -> Bool {
        return factorize(z).forAll{ $0 == .zero }
    }
    
    public func elementsAreEqual(_ z1: FreeModule<A, R>, _ z2: FreeModule<A, R>) -> Bool {
        return elementIsZero(z1 - z2)
    }
}

public extension SimpleModuleStructure where R == 𝐙 {
    public func subSummands<n: _Int>(torsion: Int) -> SimpleModuleStructure<A, IntegerQuotientRing<n>> {
        assert(n.intValue == torsion)
        
        typealias Q = IntegerQuotientRing<n>
        typealias T = SimpleModuleStructure<A, Q>
        
        let indices = (0 ..< self.summands.count).filter{ i in self[i].divisor == torsion }
        let sub = subSummands(indices: indices)
        
        let summands = sub.summands.map { s -> T.Summand in
            T.Summand(s.generator.mapValues{ Q($0) }, .zero)
        }
        let transform = sub.transform.mapValues { Q($0) }
        
        return T(summands, basis, transform)
    }
}

public typealias AbstractSimpleModuleStructure<R: Ring> = SimpleModuleStructure<AbstractBasisElement, R>

public extension AbstractSimpleModuleStructure where A == AbstractBasisElement {
    public convenience init(rank r: Int, torsions: [R] = []) {
        let t = torsions.count
        let basis = (0 ..< r + t).map{ i in A(i) }
        let summands = (0 ..< r).map{ i in Summand(basis[i], .zero) }
            + torsions.enumerated().map{ (i, d) in Summand(basis[i + r], d) }
        let I = Matrix<R>.identity(size: r + t)
        self.init(summands, basis, I)
    }
    
    public static func ⊕(a: AbstractSimpleModuleStructure<R>, b: AbstractSimpleModuleStructure<R>) -> AbstractSimpleModuleStructure<R> {
        return AbstractSimpleModuleStructure(
            rank: a.rank + b.rank,
            torsions: a.torsionCoeffs + b.torsionCoeffs
        )
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
