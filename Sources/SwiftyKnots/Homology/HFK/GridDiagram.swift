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
    private let generatorsDict: [[Int] : Generator]
    
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
        
        self.init(Os.sorted(by: { p in p.x }), Xs.sorted(by: { p in p.x }))
    }
    
    public init(arcPresentation code: Int...) {
        self.init(arcPresentation: code)
    }
    
    internal init(_ Os: [Point], _ Xs: [Point]) {
        let n = Os.count
        
        self.Os = Os
        self.Xs = Xs
        
        let x_TL: Generator = {
            let seq = Os.map{ p in ((p.y + 1) / 2) % n }
            let points = seq.enumerated().map { (i, j) in Point(2 * i, 2 * j) }
            
            let curve = ClosedCurve(from: Os, to: Xs)
            let w = { p in curve.windingNumber(around: p) }
            
            let a = points.sum { p in w(p) }
            let b = (Os + Xs).sum { p in p.corners.sum{ q in w(q) } }
            let A = -a + ( b / 4 - (n - 1) ) / 2
            
            return Generator(id: 0, sequence: seq, MaslovDegree: 0, AlexanderDegree: A)
        }()
        
        func next(to x: Generator, swap: (Int, Int)) -> Generator {
            let seq = x.sequence
            let (i, j) = swap
            let (p, q) = (Point(2 * i, 2 * seq[i]),
                          Point(2 * j, 2 * seq[j]))
            let rect = Rect(from: p, to: q, gridSize: 2 * n)
            
            // M(y) - M(x) = 2 #(r ∩ Os) - 2 #(x ∩ Int(r)) - 1
            let m = 2 * rect.countIntersections(with: Os) - 2 * rect.countIntersections(with: x.points) - 1
            
            // A(y) - A(x) = #(r ∩ Os) - #(r ∩ Xs)
            let a = rect.countIntersections(with: Os) - rect.countIntersections(with: Xs)
            
            return Generator(id: x.id + 1,
                             sequence: seq.swappedAt(i, j),
                             MaslovDegree: x.MaslovDegree + m,
                             AlexanderDegree: x.AlexanderDegree + a)
        }
        
        // see Heap's algorithm: https://en.wikipedia.org/wiki/Heap%27s_algorithm
        
        var generators: [Generator] = []
        generators.reserveCapacity(n.factorial)
        generators.append(x_TL)
        
        func generate(_ k: Int) {
            if k <= 1 {
                return
            }
            generate(k - 1)
            for l in 0 ..< k - 1 {
                let (i, j) = k.isEven ? (l, k - 1) : (0, k - 1)
                let x = generators.last!
                let y = next(to: x, swap: (i, j))
                generators.append(y)
                generate(k - 1)
            }
        }
        generate(n)
        
        self.generators = generators
        self.generatorsDict = Dictionary(pairs: generators.map{ x in (x.sequence, x) })
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
        return GridDiagram(Os.map(t).sorted(by: { p in p.x }),
                           Xs.map(t).sorted(by: { p in p.x }))
    }
    
    public func generator(forSequence seq: [Int]) -> Generator {
        return generatorsDict[seq]!
    }
    
    public enum NamedGenerator: Int {
        case OTL, OTR, OBL, OBR, XTL, XTR, XBL, XBR
    }
    
    public func generator(named name: NamedGenerator) -> Generator {
        let target = (name.rawValue < 4) ? Os : Xs
        let diff = { () -> (Int, Int) in
            switch name {
            case .OTL, .XTL: return (-1, +1)
            case .OTR, .XTR: return (+1, +1)
            case .OBL, .XBL: return (-1, -1)
            case .OBR, .XBR: return (+1, -1)
            }
        }()
        let seq = target
            .map{ p in (x: (p.x + diff.0) % gridSize, y: (p.y + diff.1) % gridSize) }
            .sorted{ $0.x }
            .map{ $0.y / 2 }
        return generator(forSequence: seq)
    }
    
    public func isAdjacent(_ x: Generator, _ y: Generator) -> Bool {
        let (ps, qs) = (x.points, y.points)
        return Set(ps).subtracting(qs).count == 2
    }
    
    public func adjacents(_ x: Generator) -> [Generator] {
        let xSeq = x.sequence
        return DPermutation.rawTranspositions(within: gridNumber).map { t in
            let ySeq = xSeq.swappedAt(t.0, t.1)
            return generator(forSequence: ySeq)
        }
    }
    
    public func rectangles(from x: Generator, to y: Generator) -> [Rect] {
        let (ps, qs) = (x.points, y.points)
        let diff = Set(ps).subtracting(qs)
        
        guard diff.count == 2 else {
            return []
        }
        
        let pq = diff.toArray()
        let (p, q) = (pq[0], pq[1])
        
        return [Rect(from: p, to: q, gridSize: gridSize),
                Rect(from: q, to: p, gridSize: gridSize)]
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
        
        public init(origin: Point, size: Point, gridSize: Int) {
            self.origin = origin
            self.size  = size
            self.gridSize = gridSize
        }
        
        public init(from p: Point, to q: Point, gridSize: Int) {
            let l = gridSize
            let size = Point((q.x - p.x + l) % l, (q.y - p.y + l) % l)
            self.init(origin: p, size: size, gridSize: gridSize)
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
        
        public func countIntersections(with points: [Point]) -> Int {
            return points.count{ p in self.contains(p) }
        }
        
        public var description: String {
            return "[point: \(origin), size: \(size)]"
        }
    }
    
    public struct Generator: FreeModuleGenerator {
        public let id: Int
        internal let sequence: [Int]
        
        public let MaslovDegree: Int
        public let AlexanderDegree: Int
        
        fileprivate init(id: Int, sequence: [Int], MaslovDegree: Int, AlexanderDegree: Int) {
            self.id = id
            self.sequence = sequence
            self.MaslovDegree = MaslovDegree
            self.AlexanderDegree = AlexanderDegree
        }
        
        public var points: [Point] {
            return sequence.enumerated().map { (i, j) in Point(2 * i, 2 * j) }
        }
        
        public var degree: Int {
            return MaslovDegree
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
            return "(\(id): \(sequence) )"
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
