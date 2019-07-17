//
//  GridDiagram.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/07/01.
//

import Foundation
import SwiftyMath
import SwiftyHomology

public struct GridDiagram {
    // Memo:  Os and Xs are placed on  odd points,
    //       generators are placed on even points.
    public let Os: [Point]
    public let Xs: [Point]
    public let generators: [Generator]
    
    public init(arcPresentation code: [Int]) {
        assert(code.count.isEven)
        
        let n = code.count / 2
        let (Os, Xs) = (0 ..< n).reduce(into: ([], [])) { (res: inout (Os: [Point], Xs: [Point]), i: Int) in
            let O = 2 * code[2 * i] - 1
            let X = 2 * code[2 * i + 1] - 1
            let y = 2 * i + 1
            res.Os.append(Point(O, y))
            res.Xs.append(Point(X, y))
        }
        
        assert(Os.map{ p in p.x }.isUnique)
        assert(Os.map{ p in p.y }.isUnique)
        assert(Xs.map{ p in p.x }.isUnique)
        assert(Xs.map{ p in p.y }.isUnique)
        
        assert(Os.allSatisfy{ p in (0 ..< 2 * n).contains(p.x) })
        assert(Os.allSatisfy{ p in (0 ..< 2 * n).contains(p.y) })
        assert(Xs.allSatisfy{ p in (0 ..< 2 * n).contains(p.x) })
        assert(Xs.allSatisfy{ p in (0 ..< 2 * n).contains(p.y) })
        
        self.init(Os, Xs)
    }
    
    public init(arcPresentation code: Int...) {
        self.init(arcPresentation: code)
    }
    
    internal init(_ Os: [Point], _ Xs: [Point]) {
        let n = Os.count
        
        self.Os = Os
        self.Xs = Xs
        
        let x0 = Os.map{ p in Point(p.x - 1, p.y - 1) }.sorted(by: { p in p.x })
        let M = { (x: [Point]) -> Int in
            let curve = ClosedCurve(from: x, to: x0)
            let w = { p in curve.windingNumber(around: p) }
            let a = (x + x0).sum { p in p.corners.sum{ q in w(q) } }
            let b = Os.sum { p in w(p) }
            return a / 4 - 2 * b - (n - 1)
        }

        let A = { () -> (([Point]) -> Int) in
            let curve = ClosedCurve(from: Os, to: Xs)
            let w = { p in curve.windingNumber(around: p) }
            let b = (Os + Xs).sum { p in p.corners.sum{ q in w(q) } }
            return { (x: [Point]) -> Int in
                let a = x.sum { p in w(p) }
                return -a + ( b / 4 - (n - 1) ) / 2
            }
        }()
        
        self.generators = DPermutation.rawPermutations(length: n)
            .enumerated()
            .map{ (id, s) in
                let x = (0 ..< n).map{ i in Point(2 * i, 2 * s[i]) }
                return Generator(id: id, points: x, MaslovDegree: M(x), AlexanderDegree: A(x))
        }
    }
    
    public var gridNumber: Int {
        return Os.count
    }
    
    public var gridSize: Int {
        return 2 * gridNumber
    }
    
    public var rotate90: GridDiagram {
        let n = gridSize
        let t = { (p: Point) -> Point in
            Point(n - p.y, p.x)
        }
        return GridDiagram(Os.map(t), Xs.map(t))
    }
    
    public func isAdjacent(_ x: Generator, _ y: Generator) -> Bool {
        let (ps, qs) = (x.points, y.points)
        return Set(ps).subtracting(qs).count == 2
    }
    
    // TODO: consider generating elements directly.
    public func adjacents(_ x: Generator) -> [Generator] {
        return generators.filter { y in isAdjacent(x, y) }
    }
    
    public func rectangles(from x: Generator, to y: Generator) -> [Rect] {
        let (ps, qs) = (x.points, y.points)
        let diff = Set(ps).subtracting(qs)
        
        guard diff.count == 2 else {
            return []
        }
        
        let pq = diff.toArray()
        let (p, q) = (pq[0], pq[1])
        
        func rect(_ p: Point, _ q: Point) -> Rect {
            let l = gridSize
            let size = Point((q.x - p.x + l) % l, (q.y - p.y + l) % l)
            return Rect(point: p, size: size, gridSize: gridSize)
        }
        
        return [rect(p, q), rect(q, p)]
    }
    
    public func emptyRectangles(from x: Generator, to y: Generator) -> [Rect] {
        // Note: Int(r) ∩ x = Int(r) ∩ y .
        return rectangles(from: x, to: y).filter{ r in
            !r.intersects(x.points)
        }
    }
    
    public func printDiagram() {
        let range = (0 ..< gridSize / 2).toArray()
        
        let OX = Dictionary(pairs: (Os.map{ p in (p, "O") } + Xs.map{ p in (p, "X") }).map { (p, s) in
            ([(p.x - 1)/2, (p.y - 1)/2], s)
        })
        print( Format.table(rows: range.reversed(), cols: range, symbol: "j\\i") { (j, i) -> String in
            OX[ [i, j] ] ?? ""
        } )
    }
    
    public var MaslovDegreeRange: ClosedRange<Int> {
        return range { $0.MaslovDegree }
    }
    
    public var AlexanderDegreeRange: ClosedRange<Int> {
        return range { $0.AlexanderDegree }
    }
    
    private func range(_ d: (Generator) -> Int) -> ClosedRange<Int> {
        return d(generators.min{ d($0) < d($1) }!) ... d(generators.max{ d($0) < d($1) }!)
    }
    
    public var knotGenus: Int {
        let H = GridComplex.tilde(self).asBigraded { x in x.AlexanderDegree }.homology
        let iRange = MaslovDegreeRange
        let (jMax, jMin) = (generators.map{ $0.AlexanderDegree }.max()!, generators.map{ $0.AlexanderDegree }.min()!)
        
        for j in (jMin ... jMax).reversed() {
            for i in iRange.reversed() {
                print((i, j), H[i, j])
                if !H[i, j].isZero {
                    return j
                }
            }
        }
        fatalError()
    }
    
    public struct Point: Equatable, Hashable, Comparable, CustomStringConvertible {
        public let x: Int
        public let y: Int
        
        public init(_ x: Int, _ y: Int) {
            self.x = x
            self.y = y
        }
        
        public static func < (p: Point, q: Point) -> Bool {
            return p.x < q.x && p.y < q.y
        }
        
        public var corners: [Point] {
            let p = self
            return [Point(p.x + 1, p.y + 1), Point(p.x - 1, p.y + 1), Point(p.x - 1, p.y - 1), Point(p.x + 1, p.y - 1)]
        }
        
        public var description: String {
            return "(\(x), \(y))"
        }
    }
    
    public struct Rect: CustomStringConvertible {
        public let origin: Point // Left-Bottom point
        public let size: Point
        public let gridSize: Int
        
        public init(point: Point, size: Point, gridSize: Int) {
            self.origin = point
            self.size  = size
            self.gridSize = gridSize
        }
        
        public func contains(_ p: Point) -> Bool {
            let xRange = (origin.x + 1 ..< origin.x + size.x)
            let yRange = (origin.y + 1 ..< origin.y + size.y)
            
            return (xRange.contains(p.x) || xRange.contains(p.x + gridSize)) &&
                   (yRange.contains(p.y) || yRange.contains(p.y + gridSize))
        }
        
        public func intersects(_ points: [Point]) -> Bool {
            return points.contains{ p in self.contains(p) }
        }
        
        public var description: String {
            return "[point: \(origin), size: \(size)]"
        }
    }
    
    public struct Generator: FreeModuleGenerator {
        public let id: Int
        public let points: [Point]
        
        private let MaslovFunc: () -> Int
        private let AlexanderFunc: () -> Int
        private let degreeCache: CacheDictionary<String, Int> = .empty

        fileprivate init(id: Int, points: [Point], MaslovDegree: @autoclosure @escaping () -> Int, AlexanderDegree: @autoclosure @escaping () -> Int) {
            assert(points.enumerated().allSatisfy{ (i, p) in p.x == 2 * i })
            self.id = id
            self.points = points
            self.MaslovFunc = MaslovDegree
            self.AlexanderFunc = AlexanderDegree
        }
        
        public var degree: Int {
            return MaslovDegree
        }
        
        public var MaslovDegree: Int {
            return degreeCache.useCacheOrSet(key: "Maslov") {
                MaslovFunc()
            }
        }
        
        public var AlexanderDegree: Int {
            return degreeCache.useCacheOrSet(key: "Alexander") {
                AlexanderFunc()
            }
        }
        
        public static func == (a: GridDiagram.Generator, b: GridDiagram.Generator) -> Bool {
            return a.id == b.id
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        public static func < (g1: Generator, g2: Generator) -> Bool {
            return g1.id < g2.id
        }
        
        public var description: String {
            return "(\(id): \(points)"
        }
    }
    
    public struct ClosedCurve {
        internal typealias Arc = (Point, Point)  // horizontal arcs 0 -> 1
        internal let arcs: [Arc]
        internal init(arcs: [Arc]) {
            assert(arcs.allSatisfy{ arc in arc.0.y == arc.1.y })
            self.arcs = arcs
        }
        
        public init(from ps: [Point], to qs: [Point]) {
            var pairs = zip(ps, qs).exclude{ (p, q) in p.y == q.y }.reversed().toArray()
            var arcs: [Arc] = []
            
            while !pairs.isEmpty {
                //  curr
                //  ○ --->--- × next.1
                //            |
                //            |
                //            ○ next.0
                //
                //            i
                
                let start = pairs.popLast()!
                var curr = start.0
                while let (i, next) = pairs.enumerated().first(where: { (_, next) in curr.y == next.1.y}) {
                    pairs.remove(at: i)
                    arcs.append( (curr, next.1) )
                    curr = next.0
                }
                assert(curr.y == start.1.y)
                arcs.append( (curr, start.1) ) // curve is closed.
            }
            
            self.init(arcs: arcs)
        }
        
        public func windingNumber(around p: Point) -> Int {
            return arcs.sum { arc in
                if p.y < arc.0.y {
                    let (x0, x1) = (arc.0.x, arc.1.x)
                    if (x0 < x1) && (x0 + 1 ..< x1).contains(p.x) {
                        return -1
                    } else if (x1 < x0) && (x1 + 1 ..< x0).contains(p.x) {
                        return 1
                    }
                }
                return 0
            }
        }
    }
}
