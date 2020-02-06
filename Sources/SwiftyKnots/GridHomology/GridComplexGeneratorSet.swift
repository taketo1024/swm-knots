//
//  GridComplexData.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2020/02/06.
//

import SwiftyMath
import Dispatch

extension GridComplex {
    public struct GeneratorSet: Sequence {
        public let gridNumber: Int
        internal let generators: [Int : Generator]
        internal let rects: Rects
        private let transpositions: [(Int, Int)]
        
        public init(for G: GridDiagram) {
            self.init(for: G, filter: { _ in true })
        }
        
        public init(for G: GridDiagram, filter: @escaping (Generator) -> Bool) {
            let rects = Rects(G)
            let generators = Generator.produce(G, rects, filter)
            self.init(
                gridNumber: G.gridNumber,
                generators: Dictionary(pairs: generators.map { x in (x.code, x) }),
                rects: rects
            )
        }
        
        private init(gridNumber: Int, generators: [Int : Generator], rects: Rects) {
            self.gridNumber = gridNumber
            self.generators = generators
            self.rects = rects
            self.transpositions = (0 ..< gridNumber).choose(2).map{ t in (t[0], t[1]) }
        }
        
        public var degreeRange: ClosedRange<Int> {
            generators.values.map{ $0.degree }.range ?? (0 ... 0)
        }
        
        public func generator(forSequence seq: [Int]) -> Generator? {
            let code = Generator.encode(seq)
            return generators[code]
        }
        
        public func adjacents(of x: Generator, with rectCond: (GridDiagram.Rect) -> Bool) -> [(Generator, GridDiagram.Rect)] {
            typealias Point = GridDiagram.Point
            typealias Rect  = GridDiagram.Rect
            
            let n = gridNumber
            let seq = x.sequence
            let pts = x.points
            
            return transpositions.flatMap { (i, j) -> [(Generator, GridDiagram.Rect)] in
                let p = Point(2 * i, 2 * seq[i])
                let q = Point(2 * j, 2 * seq[j])
                
                let rs = [
                    Rect(from: p, to: q, gridSize: 2 * n),
                    Rect(from: q, to: p, gridSize: 2 * n)
                ].filter { r in
                    rectCond(r) && !r.intersects(pts, interior: true)
                }
                
                if rs.isEmpty {
                    return []
                }
                
                let ySeq = seq.with{ $0.swapAt(i, j) }
                guard let y = generator(forSequence: ySeq) else {
                    return []
                }
                
                return rs.map { r in (y, r) }
            }
        }
        
        public func filter(_ predicate: (Generator) -> Bool) -> Self {
            GeneratorSet(
                gridNumber: gridNumber,
                generators: generators.filter{ (_, x) in predicate(x) },
                rects: rects
            )
        }
        
        public func makeIterator() -> AnySequence<Generator>.Iterator {
            AnySequence(generators.values).makeIterator()
        }
        
        public var distributionTable: String {
            let elements = self
                .group { x in x.degree }
                .mapValues { list in
                    list.group{ x in x.AlexanderDegree }
                        .map{ (j, list) in (j, list.count) }
                }
                .sorted { (i, _) in i }
                .flatMap { (i, list) in list.map{ (j, c) in (i, j, c) }}
            
            return Format.table(elements: elements)
        }
        
        internal struct Rects {
            typealias Point = GridDiagram.Point
            typealias Rect  = GridDiagram.Rect
            
            private let gridNumber: Int
            private let data: [Rect : Info]

            init(_ G: GridDiagram) {
                typealias Point = GridDiagram.Point

                let n = G.gridNumber
                let rects = ((0 ..< n) * (0 ..< n)).flatMap { (x, y) -> [Rect] in
                    return ((0 ..< n) * (0 ..< n)).map { (w, h) -> Rect in
                        return Rect(
                            origin: Point(2 * x, 2 * y),
                            size: Point(2 * w, 2 * h),
                            gridSize: G.gridSize
                        )
                    }
                }
                
                self.gridNumber = n
                self.data = Dictionary(keys: rects) { r in
                    Info(G, r)
                }
            }
            
            subscript(_ r: Rect) -> Info {
                data[r]!
            }
            
            struct Info {
                let gridNumber: Int
                let Ocode : Int
                let Ocount: Int
                let Xcode : Int
                let Xcount: Int
                
                init(_ G: GridDiagram, _ r: Rect) {
                    let (Os, Xs) = (G.Os, G.Xs)
                    self.gridNumber = G.gridNumber
                    (self.Ocode, self.Ocount) = Self.encodeIntersections(Os, r)
                    (self.Xcode, self.Xcount) = Self.encodeIntersections(Xs, r)
                }
                
                private static func encodeIntersections(_ points: [Point], _ rect: Rect) -> (code: Int, count: Int) { // binary flags
                    points.enumerated().reduce(into: (0, 0)) { (res, e) in
                        let (i, p) = e
                        if rect.contains(p) {
                            res.0 |= (1 << i)
                            res.1 += 1
                        }
                    }
                }
                
                enum IntersectionType {
                    case O, X
                }
                
                func intersections(_ type: IntersectionType) -> [Int] {
                    let code = (type == .O) ? Ocode : Xcode
                    return (0 ..< gridNumber).map { i in
                        (code >> i) & 1
                    }
                }
                
                func countIntersections(_ type: IntersectionType) -> Int {
                    (type == .O) ? Ocount : Xcount
                }
                
                func intersects(_ type: IntersectionType) -> Bool {
                    countIntersections(type) > 0
                }
                
                func intersects(_ type: IntersectionType, _ index: Int) -> Bool {
                    let code = (type == .O) ? Ocode : Xcode
                    return (code >> index) & 1 == 1
                }
            }
        }
    }
}
