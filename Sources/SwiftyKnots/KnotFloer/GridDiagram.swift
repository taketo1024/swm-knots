//
//  KnotFloearHomology.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/28.
//

import Foundation
import SwiftyMath
import SwiftyHomology

public struct GridDiagram {
    public let Os: [Point]
    public let Xs: [Point]
    public let generators: [Generator]
    
    public init(OX: (Int, Int) ...) {
        let trans = OX.map{ p in Point(2 * p.0 + 1, 2 * p.1 + 1) }
        let Os = trans.takeEven()
        let Xs = trans.takeOdd()
        self.init(Os, Xs)
    }
    
    internal init(_ Os: [Point], _ Xs: [Point]) {
        assert(Os.count == Xs.count)
        assert(Os.map{ p in p.x }.isUnique)
        assert(Os.map{ p in p.y }.isUnique)
        assert(Xs.map{ p in p.x }.isUnique)
        assert(Xs.map{ p in p.y }.isUnique)
        
        let n = Os.count
        
        assert(Os.allSatisfy{ p in (0 ..< 2 * n).contains(p.x) })
        assert(Os.allSatisfy{ p in (0 ..< 2 * n).contains(p.y) })
        assert(Xs.allSatisfy{ p in (0 ..< 2 * n).contains(p.x) })
        assert(Xs.allSatisfy{ p in (0 ..< 2 * n).contains(p.y) })
        
        self.Os = Os
        self.Xs = Xs
        
        self.generators = Permutation.allPermutations(ofLength: n)
            .enumerated()
            .map{ (i, p) in
                let points = (0 ..< n).map{ i in Point(2 * i, 2 * p[i]) }
                return Generator(id: i, points: points)
            }
    }
    
    public var n: Int {
        return Os.count
    }
    
    public var gridSize: Int {
        return 2 * n
    }
    
    private func I(_ ps: [Point], _ qs: [Point]) -> Int {
        return ps.allCombinations(with: qs).count{ (p, q) in p < q }
    }
    
    private func J(_ ps: [Point], _ qs: [Point]) -> Int {
        return (I(ps, qs) + I(qs, ps)) / 2
    }

    // the Maslov grading:
    // M (x) = J (x, x) − 2J (x, O) + J (O, O) + 1.
    
    public func MaslovGrading(_ x: Generator) -> Int {
        let ps = x.points
        return J(ps, ps) - 2 * J(ps, Os) + J(Os, Os) + 1
    }
    
    // the Alexander grading (currently supports only when l = 1):
    // Ai(x) = J(x − 1/2(X + O), Xi − Oi) − (ni − 1)/2.
    
    public func AlexanderGrading(_ x: Generator) -> Int {
        let ps = x.points
        return J(ps, Xs) - J(ps, Os) - ( J(Xs, Xs) - J(Xs, Os) + J(Os, Xs) - J(Os, Os) - (n - 1) ) / 2
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
        let diff = Set(ps).subtracting(qs).toArray()
        
        guard diff.count == 2 else {
            return []
        }
        
        let (p, q) = (diff[0], diff[1])
        
        func rect(_ p: Point, _ q: Point) -> Rect {
            let l = gridSize
            let size = Point((q.x - p.x + l) % l, (q.y - p.y + l) % l)
            return Rect(point: p, size: size)
        }
        
        return [rect(p, q), rect(q, p)]
    }
    
    public func emptyRectangles(from x: Generator, to y: Generator) -> [Rect] {
        return rectangles(from: x, to: y).filter{ r in
            !r.contains(x.points, gridSize: gridSize)
        }
    }
    
    public func printDiagram() {
        let OX = (Os.map{ p in (p, "O") } + Xs.map{ p in (p, "X") }).map { (p, s) in
            (IntList(p.x, p.y), s)
        }
        let grid = Grid2(data: Dictionary(pairs: OX), default: " ")
        grid.printTable(separator: "", printHeaders: false, skipDefault: false)
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
        
        public var description: String {
            return "(\(x), \(y))"
        }
    }
    
    public struct Rect: CustomStringConvertible {
        public let point: Point
        public let size: Point
        
        public init(x: Int, y: Int, w: Int, h: Int) {
            self.init(point: Point(x, y), size: Point(w, h))
        }
        
        public init(point: Point, size: Point) {
            self.point = point
            self.size  = size
        }
        
        public func contains(_ points: [Point], gridSize: Int) -> Bool {
            return countContaining(points, gridSize: gridSize) > 0
        }
        
        public func countContaining(_ points: [Point], gridSize l: Int) -> Int {
            let xRange = (point.x + 1 ..< point.x + size.x)
            let yRange = (point.y + 1 ..< point.y + size.y)
            
            return points.count { p in
                (xRange.contains(p.x) || xRange.contains(p.x + l)) &&
                (yRange.contains(p.y) || yRange.contains(p.y + l))
            }
        }
        
        public var description: String {
            return "[point: \(point), size: \(size)]"
        }
    }
    
    public struct Generator: BasisElementType {
        public let id: Int
        public let points: [Point]
        
        public init(id: Int, points: [Point]) {
            self.id = id
            self.points = points
        }

        public var description: String {
            return "(\(id): \(points))"
        }

        public var hashValue: Int {
            return id
        }

        public static func < (g1: Generator, g2: Generator) -> Bool {
            return g1.id < g2.id
        }
    }
}
