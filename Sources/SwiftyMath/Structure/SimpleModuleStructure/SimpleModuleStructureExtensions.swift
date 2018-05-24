//
//  SimpleModuleStructureExtensions.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/05/22.
//

import Foundation

// EuclideanRing extensions

public extension SimpleModuleStructure where R: EuclideanRing {
    public init(generators: [A], relationMatrix B: Matrix<R>? = nil) {
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

// Int Extensions

public extension SimpleModuleStructure where R == 𝐙 {
    public var structure: [Int : Int] {
        return summands.group{ $0.divisor }.mapValues{ $0.count }
    }
    
    public var structureCode: String {
        return structure.sorted{ $0.key }.map { (d, r) in
            "\(r)\(d == 0 ? "" : Format.sub(d))"
        }.joined()
    }
    
    public func orderNtorsionPart<n: _Int>(_ type: n.Type) -> SimpleModuleStructure<A, IntegerQuotientRing<n>> {
        typealias Q = IntegerQuotientRing<n>
        typealias Summand = SimpleModuleStructure<A, Q>.Summand
        
        let n = n.intValue
        let indices = (0 ..< self.summands.count).filter{ i in self[i].divisor == n }
        let sub = subSummands(indices: indices)
        
        let summands = sub.summands.map { s -> Summand in
            Summand(s.generator.mapValues{ Q($0) }, .zero)
        }
        let transform = sub.transform.mapValues { Q($0) }
        
        return SimpleModuleStructure<A, Q>(summands, basis, transform)
    }
    
    public var order2torsionPart: SimpleModuleStructure<A, 𝐙₂> {
        return orderNtorsionPart(_2.self)
    }
}
