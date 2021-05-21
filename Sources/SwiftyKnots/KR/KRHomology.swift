//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/10.
//

import SwiftyMath
import SwiftyHomology

public struct KR {
    public struct _x: PolynomialIndeterminate {
        public static let degree = 2
        public static var symbol = "x"
    }
    public typealias _xn = EnumeratedPolynomialIndeterminates<_x, DynamicSize>
    
    public typealias Grading = MultiIndex<_3>
    public typealias EdgeRing<R: Ring> = MultivariatePolynomial<R, _xn>
    public typealias BaseModule<R: Ring> = LinearCombination<R, MonomialAsGenerator<_xn>>
    public typealias HorizontalModule<R: Ring> = IndexedModule<Cube.Coords, BaseModule<R>>
    public typealias TotalModule<R: Ring> = IndexedModule<Cube.Coords, HorizontalModule<R>>

    static func baseGrading(link L: Link, hCoords: Cube.Coords, vCoords: Cube.Coords) -> KR.Grading {
        (0 ..< L.crossingNumber).sum { i -> KR.Grading in
            switch (L.crossings[i].crossingSign, hCoords[i], vCoords[i]) {
            case (+1, 0, 0):
                return [2, -2, -2]
            case (+1, 1, 0):
                return [0, 0, -2]
            case (+1, 0, 1):
                return [0, -2, 0]
            case (+1, 1, 1):
                return [0, 0, 0]
                
            case (-1, 0, 0):
                return [0, -2, 0]
            case (-1, 1, 0):
                return [0, 0, 0]
            case (-1, 0, 1):
                return [0, -2, 2]
            case (-1, 1, 1):
                return [-2, 0, 2]
                
            default:
                fatalError("impossible")
            }
        }
    }

    struct EdgeConnection<R: Ring>: CustomStringConvertible {
        let ik: EdgeRing<R>
        let il: EdgeRing<R>
        
        var description: String {
            "\((ik: ik, il: il))"
        }
    }
}

public struct KRHomology<R: EuclideanRing> {
    public let L: Link
    public let normalized: Bool
    
    private let gradingShift: KR.Grading
    private var connection: [Int : KR.EdgeConnection<R>]
    private let hHomologyCache: CacheDictionary<hKey, ModuleGrid1<KR.HorizontalModule<R>>> = .empty

    public init(_ L: Link, normalized: Bool = true) {
        let w = L.writhe
        let b = L.resolved(by: L.orientationPreservingState).components.count
        
        self.L = L
        self.normalized = normalized
        self.gradingShift = normalized ? [-w + b - 1, w + b - 1, w - b + 1] : .zero
        self.connection = KREdgeConnection(L).compute()
    }
    
    public subscript(i: Int, j: Int, k: Int) -> ModuleObject<KR.TotalModule<R>> {
        guard let (h, v, s) = ijk2hvs(i, j, k) else {
            return .zeroModule
        }
        let C = totalComplex(hDegree: h, slice: s)
        let H = C.homology()
        return H[v]
    }
    
    public var minSlice: Int {
        -2 * L.crossingNumber
    }
    
    public var baseGrading: KR.Grading {
        let n = L.crossingNumber
        let v0 = Cube.Coords.zeros(length: n)
        return KR.baseGrading(link: L, hCoords: v0, vCoords: v0) + gradingShift
    }
    
    public func grading(of z: KR.TotalModule<R>) -> KR.Grading {
        if z.isZero {
            return .zero
        }
        
        let (v, x) = z.elements.anyElement!
        let (h, y) = x.elements.anyElement!
        let q = y.degree
        
        let g = KR.baseGrading(link: L, hCoords: h, vCoords: v)
        return g + [2 * q, 0, 0] + gradingShift
    }
    
    public func horizontalComplex(at vCoords: Cube.Coords, slice: Int) -> ChainComplex1<KR.HorizontalModule<R>> {
        let cube = KRHorizontalCube(link: L, vCoords: vCoords, slice: slice, connection: connection)
        return cube.asChainComplex()
    }
    
    public func totalComplex(hDegree h: Int, slice: Int) -> ChainComplex1<KR.TotalModule<R>> {
        let cube = KRTotalCube<R>(link: L, connection: connection) { vCoords -> KRTotalCube<R>.Vertex in
            let H = hHomologyCache.useCacheOrSet(key: hKey(vCoords: vCoords, slice: slice)) {
                let C = self.horizontalComplex(at: vCoords, slice: slice)
                let H = C.homology(options: [.withGenerators, .withVectorizer])
                return H
            }
            return H[h]
        }
        return cube.asChainComplex()
    }
    
    public func structure() -> [KR.Grading : ModuleObject<KR.TotalModule<R>>] {
        var res: [KR.Grading : ModuleObject<KR.TotalModule<R>>] = [:]
        
        let n = L.crossingNumber
        for s in minSlice ... 0 {
            for h in 0 ... n {
                let Cv = totalComplex(hDegree: h, slice: s)
                let H = Cv.homology()
                
                for v in 0 ... n where !H[v].isZero {
                    let (i, j, k) = hvs2ijk(h, v, s)
                    res[[i, j, k]] = H[v]
                }
            }
        }
        return res
    }
    
    public func gradedEulerCharacteristic() -> String {
        structure().map { (g, obj) -> String in
            let (i, j, k) = (g[0], g[1], g[2])
            return Format.linearCombination( [ ("a\(Format.sup(j))q\(Format.sup(i))", (-1).pow( (k - j) / 2)) ] )
        }.joined(separator: " + ")
    }
    
    private func ijk2hvs(_ i: Int, _ j: Int, _ k: Int) -> (Int, Int, Int)? {
        let g = baseGrading
        let (a, b, c) = (g[0], g[1], g[2])

        if (i - a).isEven && (j - b).isEven && (k - c).isEven {
            return ((j - b)/2, (k - c)/2, (i - a)/2 - (j - b)/2)
        } else {
            return nil
        }
    }
    
    private func hvs2ijk(_ h: Int, _ v: Int, _ s: Int) -> (Int, Int, Int) {
        let g = baseGrading
        let (a, b, c) = (g[0], g[1], g[2])
        return (a + 2 * h + 2 * s, b + 2 * h, c + 2 * v)
    }
    
    private struct hKey: Hashable {
        let vCoords: Cube.Coords
        let slice: Int
    }
}
