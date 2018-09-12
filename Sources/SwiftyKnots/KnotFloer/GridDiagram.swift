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
        
        assert(Os.forAll{ p in (0 ..< 2 * n).contains(p.x) })
        assert(Os.forAll{ p in (0 ..< 2 * n).contains(p.y) })
        assert(Xs.forAll{ p in (0 ..< 2 * n).contains(p.x) })
        assert(Xs.forAll{ p in (0 ..< 2 * n).contains(p.y) })
        
        self.Os = Os
        self.Xs = Xs
        
        self.generators = Permutation.allPermutations(ofLength: n)
            .enumerated()
            .map{ (i, p) in
                let points = (0 ..< n).map{ i in Point(2 * i, 2 * p[i]) }
                return Generator(id: i, points: points)
            }
    }
    
    public var size: Int {
        return Os.count
    }
    
    public func I(_ A: [Point], _ B: [Point]) -> Int {
        return A.allCombinations(with: B).count{ (a, b) in a < b }
    }
    
    public func J(_ A: [Point], _ B: [Point]) -> Int {
        return (I(A, B) + I(B, A)) / 2
    }

    // the Maslov grading:
    // M (x) = J (x, x) − 2J (x, O) + J (O, O) + 1.
    
    public func M(_ x: [Point]) -> Int {
        return J(x, x) - 2 * J(x, Os) + J(Os, Os) + 1
    }
    
    // the Alexander grading (currently supports only when l = 1):
    // Ai(x) = J(x − 1/2(X + O), Xi − Oi) − (ni − 1)/2.
    
    public func A(_ x: [Point]) -> Int {
        let n = size
        return J(x, Xs) - J(x, Os) - ( J(Xs, Xs) - J(Xs, Os) + J(Os, Xs) - J(Os, Os) - (n - 1) ) / 2
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
        
        public static func + (p: Point, q: Point) -> Point {
            return Point(p.x + q.x, p.y + q.y)
        }
        
        public static func % (p: Point, n: Int) -> Point {
            return Point(p.x % n, p.y % n)
        }
        
        public var description: String {
            return "(\(x), \(y))"
        }
    }
    
    public struct Rect: CustomStringConvertible {
        public let point: Point
        public let size: Point
        public let mod: Int
        
        public init(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int, mod: Int) {
            self.init(Point(x1, y1), Point(x2, y2), mod: mod)
        }
        
        public init(_ point1: Point, _ point2: Point, mod: Int) {
            self.point = Point(min(point1.x, point2.x), min(point1.y, point2.y))
            self.size  = Point(abs(point1.x - point2.x), abs(point1.y - point2.y))
            self.mod   = mod
        }
        
        public func connects(_ x: [Point], to y: [Point]) -> Bool {
            let x_y = Set(x).subtracting(y)
            let y_x = Set(y).subtracting(x)
            
            guard x_y.count == 2 else {
                return false
            }
            
            let p1 = point
            let p2 = (point + Point(size.x, 0)) % mod
            let p3 = (point + Point(0, size.y)) % mod
            let p4 = (point + size) % mod
            
            return x_y.contains(p1) && x_y.contains(p4)
                && y_x.contains(p2) && y_x.contains(p3)
        }
        
        public func contains(_ x: [Point]) -> Bool {
            return countContaining(x) > 0
        }
        
        public func countContaining(_ x: [Point]) -> Int {
            let xRange = (point.x + 1 ..< point.x + size.x)
            let yRange = (point.y + 1 ..< point.y + size.y)
            
            return x.count { p in
                (xRange.contains(p.x) || xRange.contains(p.x + mod)) &&
                (yRange.contains(p.y) || yRange.contains(p.y + mod))
            }
        }
        
        public var description: String {
            return "[\(point), \(point + size)]"
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
            return "(\(id))"
        }

        public var hashValue: Int {
            return id
        }

        public static func < (g1: Generator, g2: Generator) -> Bool {
            return g1.id < g2.id
        }
    }
}
