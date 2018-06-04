//
//  ModuleObject.swift
//  Sample
//
//  Created by Taketo Sano on 2018/06/02.
//

import Foundation
import SwiftyMath

// A decomposed form of a freely & finitely presented module,
// i.e. a module with finite generators and a finite & free presentation.
//
//   M = (R/d_0 ⊕ ... ⊕ R/d_k) ⊕ R^r  ( d_i: torsion-coeffs, r: rank )
//
// See: https://en.wikipedia.org/wiki/Free_presentation
//      https://en.wikipedia.org/wiki/Structure_theorem_for_finitely_generated_modules_over_a_principal_ideal_domain#Invariant_factor_decomposition

// MEMO waiting for parametrized extension.
// public extension<A: BasisElementType, R: EuclideanRing> ObjectGrid where Object == ModuleObject<A, R> {

public protocol ModuleObjectType: Equatable {
    associatedtype A: BasisElementType
    associatedtype R: EuclideanRing
    
    init(generators: [A])
    static var zeroModule: Self { get }
    var entity: ModuleObject<A, R> { get }
    var isZero: Bool { get }
    var rank: Int { get }
    var freePart: Self { get }
    var torsionPart: Self { get }
    func describe()
}

public struct ModuleObject<A: BasisElementType, R: EuclideanRing>: ModuleObjectType, CustomStringConvertible {
    public let summands: [Summand]
    
    // MEMO values used for factorization where R: EuclideanRing
    internal let basis: [A]
    internal let transform: Matrix<R>
    
    // root initializer
    internal init(_ summands: [Summand], _ basis: [A], _ transform: Matrix<R>) {
        self.summands = summands
        self.basis = basis
        self.transform = transform
    }
    
    public init(generators: [A]) {
        self.init(generators: generators, relationMatrix: nil)
    }
    
    public init(generators: [A], relationMatrix B: Matrix<R>?) {
        let I = Matrix<R>.identity(size: generators.count)
        self.init(basis: generators, generatingMatrix: I, transitionMatrix: I, relationMatrix: B)
    }
    
    // TODO must consider when `generators` does not form a subbasis of R^n
    // e.g) generators = [(2, 0), (0, 2)]
    
    public init(generators: [FreeModule<A, R>], relationMatrix B: Matrix<R>? = nil) {
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
    public init(basis: [A], generatingMatrix A: Matrix<R>, transitionMatrix T:Matrix<R>, relationMatrix _B: Matrix<R>?) {
        
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
    
    public init(basis: [FreeModule<A, R>], generatingMatrix A: Matrix<R>, transitionMatrix T: Matrix<R>, relationMatrix B: Matrix<R>?) {
        
        let oBasis = basis.flatMap{ $0.basis }.unique().sorted()
        let A0 = Matrix(rows: oBasis.count, cols: basis.count) { (i, j) in basis[j][oBasis[i]] }
        let T0 = A0.elimination(form: .RowHermite).left.submatrix(rowRange: 0 ..< basis.count)
        
        assert(T0 * A0 == Matrix.identity(size: basis.count))
        
        self.init(basis: oBasis, generatingMatrix: A0 * A, transitionMatrix: T * T0, relationMatrix: B)
    }
    
    public subscript(i: Int) -> Summand {
        return summands[i]
    }
    
    public var entity: ModuleObject<A, R> {
        return self
    }
    
    public static var zeroModule: ModuleObject<A, R> {
        return ModuleObject([], [], Matrix.zero(rows: 0, cols: 0))
    }
    
    public var isZero: Bool {
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
    
    public var freePart: ModuleObject<A, R> {
        let indices = (0 ..< summands.count).filter{ i in self[i].isFree }
        return subSummands(indices: indices)
    }
    
    public var torsionPart: ModuleObject<A, R> {
        let indices = (0 ..< summands.count).filter{ i in !self[i].isFree }
        return subSummands(indices: indices)
    }
    
    public func subSummands(_ indices: Int ...) -> ModuleObject<A, R> {
        return subSummands(indices: indices)
    }
    
    public func subSummands(indices: [Int]) -> ModuleObject<A, R> {
        let sub = indices.map{ summands[$0] }
        let T = transform.submatrix(rowsMatching: { i in indices.contains(i)}, colsMatching: { _ in true })
        return ModuleObject(sub, basis, T)
    }
    
    public static func ⊕(M1: ModuleObject<A, R>, M2: ModuleObject<A, R>) -> ModuleObject<A, R> {
        if M1.basis == M2.basis {
            let basis = M1.basis
            let summands = M1.summands + M2.summands
            let T = M1.transform.concatRows(with: M2.transform)
            return ModuleObject(summands, basis, T)

        } else if M1.basis.isDisjoint(with: M2.basis) {
            let basis = M1.basis + M2.basis
            let summands = M1.summands + M2.summands
            let T = M1.transform ⊕ M2.transform
            return ModuleObject(summands, basis, T)
        }
        
        fatalError()
    }
    
    public func factorize(_ z: FreeModule<A, R>) -> [R] {
        let v = transform * Vector(z.factorize(by: basis))
        
        return summands.enumerated().map { (i, s) in
            return s.isFree ? v[i] : v[i] % s.divisor
        }
    }
    
    public func contains(_ z: FreeModule<A, R>) -> Bool {
        let w = factorize(z).enumerated().sum { (i, r) in
            r * generator(i)
        }
        return z == w
    }
    
    public func elementIsZero(_ z: FreeModule<A, R>) -> Bool {
        return factorize(z).forAll{ $0 == .zero }
    }
    
    public func elementsAreEqual(_ z1: FreeModule<A, R>, _ z2: FreeModule<A, R>) -> Bool {
        return elementIsZero(z1 - z2)
    }
    
    public static func ==(a: ModuleObject<A, R>, b: ModuleObject<A, R>) -> Bool {
        return a.summands == b.summands
    }
    
    public func describe() {
        if !isZero {
            print("\(self) {")
            for (i, x) in generators.enumerated() {
                print("\t(\(i)) ", x)
            }
            print("}")
        } else {
            print("\(self)")
        }
    }
    
    public var description: String {
        if summands.isEmpty {
            return "0"
        }
        
        return summands
            .group{ $0.divisor }
            .map{ (r, list) in
                list.first!.description + (list.count > 1 ? Format.sup(list.count) : "")
            }
            .joined(separator: "⊕")
    }
    
    public struct Summand: AlgebraicStructure {
        public let generator: FreeModule<A, R>
        public let divisor: R
        
        public init(_ generator: FreeModule<A, R>, _ divisor: R = .zero) {
            self.generator = generator
            self.divisor = divisor
        }
        
        public init(_ a: A, _ divisor: R = .zero) {
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
            switch (isFree, R.self == 𝐙.self) {
            case (true, _)    : return R.symbol
            case (false, true): return "𝐙\(Format.sub("\(divisor)"))"
            default           : return "\(R.symbol)/\(divisor)"
            }
        }
    }
}

public protocol IntModuleObjectType: ModuleObjectType {
    var structureCode: String { get }
    func torsionPart<t: _Int>(order: t.Type) -> ModuleObject<A, IntegerQuotientRing<t>>
}

extension ModuleObject: IntModuleObjectType where R == 𝐙 {}

public extension ModuleObject where R == 𝐙 {
    public var structure: [Int : Int] {
        return summands.group{ $0.divisor }.mapValues{ $0.count }
    }
    
    public var structureCode: String {
        return structure.sorted{ $0.key }.map { (d, r) in
            "\(r)\(d == 0 ? "" : Format.sub(d))"
            }.joined()
    }
    
    public func torsionPart<t: _Int>(order: t.Type) -> ModuleObject<A, IntegerQuotientRing<t>> {
        typealias Q = IntegerQuotientRing<t>
        typealias Summand = ModuleObject<A, Q>.Summand
        
        let n = t.intValue
        let indices = (0 ..< self.summands.count).filter{ i in self[i].divisor == n }
        let sub = subSummands(indices: indices)
        
        let summands = sub.summands.map { s -> Summand in
            Summand(s.generator.mapValues{ Q($0) }, .zero)
        }
        let transform = sub.transform.mapValues { Q($0) }
        
        return ModuleObject<A, Q>(summands, basis, transform)
    }
    
    public var order2torsionPart: ModuleObject<A, 𝐙₂> {
        return torsionPart(order: _2.self)
    }
}

public extension ModuleObject where R == 𝐙₂ {
    public var asIntegerQuotients: ModuleObject<A, 𝐙> {
        typealias Summand = ModuleObject<A, 𝐙>.Summand
        let summands = self.summands.map { s -> Summand in
            Summand(s.generator.mapValues{ $0.representative }, 2)
        }
        let T = self.transform.mapValues{ a in a.representative }
        return ModuleObject<A, 𝐙>(summands, basis, T)
    }
}

public extension ModuleObject where A == AbstractBasisElement, R: EuclideanRing {
    public init(rank r: Int, torsions: [R] = []) {
        let t = torsions.count
        let basis = (0 ..< r + t).map{ i in A(i) }
        let summands = (0 ..< r).map{ i in Summand(basis[i], .zero) }
            + torsions.enumerated().map{ (i, d) in Summand(basis[i + r], d) }
        let I = Matrix<R>.identity(size: r + t)
        self.init(summands, basis, I)
    }
}

public extension ModuleObject where R: EuclideanRing {
    public func asAbstract() -> ModuleObject<AbstractBasisElement, R> {
        typealias Summand = ModuleObject<AbstractBasisElement, R>.Summand
        
        let basis = self.basis.enumerated().map{ (i, a) in
            AbstractBasisElement(i, label: a.description)
        }
        let summands = self.summands.map { s in
            Summand(s.generator.mapKeys { a in basis[self.basis.index(of: a)!] }, s.divisor)
        }
        
        return ModuleObject<AbstractBasisElement, R>(summands, basis, transform)
    }
}

extension ModuleObject: Codable where A: Codable, R: Codable {
    enum CodingKeys: String, CodingKey {
        case summands, basis, transform
    }
    
    public init(from decoder: Decoder) throws {
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

extension ModuleObject.Summand: Codable where A: Codable, R: Codable {
    enum CodingKeys: String, CodingKey {
        case generator, divisor
    }
    
    public init(from decoder: Decoder) throws {
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
