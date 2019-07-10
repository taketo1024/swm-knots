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
    
    private var _generators: [Generator]
    private var _generatorsDict: [Int : [Generator]]
    
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
        self.init(Os, Xs)
    }
    
    public init(arcPresentation code: Int...) {
        self.init(arcPresentation: code)
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
        
        self._generators = Permutation.allPermutations(ofLength: n)
            .enumerated()
            .map{ (i, p) in
                let points = (0 ..< n).map{ i in Point(2 * i, 2 * p[i]) }
                let degrees = GridDiagram.computeDegrees(points, Os, Xs)
                return Generator(id: i, points: points, degrees: degrees)
        }
        self._generatorsDict = _generators.group{ $0.degree }
    }
    
    private static func computeDegrees(_ x: [Point], _ Os: [Point], _ Xs: [Point]) -> (Int, Int) {
        func I(_ x: [Point], _ y: [Point]) -> Int {
            return x.allCombinations(with: y).count{ (p, q) in p < q }
        }
        
        func J(_ x: [Point], _ y: [Point]) -> Int {
            return I(x, y) + I(y, x)
        }
        
        func M(_ ref: [Point], _ x: [Point]) -> Int {
            return ( J(x, x) - 2 * J(x, ref) + J(ref, ref) ) / 2 + 1
        }
        
        func A(_ x: [Point]) -> Int {
            return ( M(Os, x) - M(Xs, x) - Os.count + 1 ) / 2
        }
        
        return (M(Os, x), A(x))
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
    
    public func generators(ofDegree i: Int) -> [Generator] {
        return _generatorsDict[i] ?? []
    }
    
    public var degreeRange: ClosedRange<Int> {
        let degs = _generatorsDict.keys
        return degs.min()! ... degs.max()!
    }
    
    public func isAdjacent(_ x: Generator, _ y: Generator) -> Bool {
        let (ps, qs) = (x.points, y.points)
        return Set(ps).subtracting(qs).count == 2
    }
    
    // TODO: consider generating elements directly.
    public func adjacents(_ x: Generator) -> [Generator] {
        return _generators.filter { y in isAdjacent(x, y) }
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
        private let degrees: (Int, Int)
        
        fileprivate init(id: Int, points: [Point], degrees: (Int, Int)) {
            self.id = id
            self.points = points
            self.degrees = degrees
        }
        
        public var degree: Int {
            return MaslovDegree
        }
        
        public var MaslovDegree: Int {
            return degrees.0
        }
        
        public var AlexanderDegree: Int {
            return degrees.1
        }
        
        public var description: String {
            return "(\(id): \(points))"
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
    }
}
