//
//  GridDiagram.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/07/01.
//

import SwiftyMath
import SwiftyHomology

public struct GridDiagram {
    // Memo:  Os and Xs are placed on  odd points,
    //       generators are placed on even points.
    public let name: String
    public let Os: [Point]
    public let Xs: [Point]
    
    public init(name: String? = nil, arcPresentation code: [Int]) {
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
        
        self.init(name: name, Os: Os.sorted(by: { p in p.x }), Xs: Xs.sorted(by: { p in p.x }))
    }
    
    public init(name: String? = nil, arcPresentation code: Int...) {
        self.init(name: name, arcPresentation: code)
    }
    
    public init(name: String? = nil, Os: [Int], Xs: [Int]) {
        func points(_ seq: [Int]) -> [Point] {
            seq.enumerated().map { (x, y) in
                Point(2 * x + 1, 2 * y + 1)
            }
        }
        self.init(name: name, Os: points(Os), Xs: points(Xs))
    }
    
    internal init(name: String? = nil, Os: [Point], Xs: [Point]) {
        self.name = name ?? "G"
        self.Os = Os
        self.Xs = Xs
    }
    
    public var gridNumber: Int {
        Os.count
    }
    
    public var gridSize: Int {
        2 * gridNumber
    }
    
    public var rotate90: GridDiagram {
        let n = gridSize
        let t = { (p: Point) -> Point in
            Point(n - p.y, p.x)
        }
        return GridDiagram(
            name: name + "m",
            Os: Os.map(t).sorted(by: { p in p.x }),
            Xs: Xs.map(t).sorted(by: { p in p.x })
        )
    }
    
    public var diagramString: String {
        let OXs = Os.map{ p in (p, "O") } + Xs.map{ p in (p, "X") }
        let elems = OXs.map { (p, s) in
            ((p.x - 1)/2, (p.y - 1)/2, s)
        }
        return Format.table(elements: elems)
    }
    
    public func printDiagram() {
        print(diagramString)
    }
    
    public struct Point: Equatable, Hashable, Comparable, CustomStringConvertible {
        public let x: Int
        public let y: Int
        
        public init(_ x: Int, _ y: Int) {
            self.x = x
            self.y = y
        }
        
        public static func < (p: Point, q: Point) -> Bool {
            p.x < q.x && p.y < q.y
        }
        
        public func shift(_ dx: Int, _ dy: Int) -> Point {
            Point(x + dx, y + dy)
        }
        
        public var corners: [Point] {
            [shift(1, 1), shift(-1, 1), shift(-1, -1), shift(1, -1)]
        }
        
        public var description: String {
            "(\(x), \(y))"
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
        
        public func contains(_ p: Point, interior: Bool = false) -> Bool {
            func inRange(_ p: Int, _ a: Int, _ b: Int) -> Bool {
                if interior {
                    return (a < p && p < b)
                        || (a < p + gridSize && p + gridSize < b)
                } else {
                    return (a <= p && p <= b)
                        || (a <= p + gridSize && p + gridSize <= b)
                }
            }
            
            return inRange(p.x, origin.x, origin.x + size.x)
                && inRange(p.y, origin.y, origin.y + size.y)
        }

        public func intersects(_ points: [Point], interior: Bool = false) -> Bool {
            points.contains{ p in self.contains(p, interior: interior) }
        }
        
        public var description: String {
            "[point: \(origin), size: \(size)]"
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
            arcs.sum { arc in
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
