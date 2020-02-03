//
//  GridComplexGenerator.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/09/10.
//

import SwiftyMath
import Dispatch

extension GridComplex {
    public struct Generator: FreeModuleGenerator {
        internal let code: Int
        internal let size: Int
        public let MaslovDegree: Int
        public let AlexanderDegree: Int
        
        public init(sequence: [Int], MaslovDegree: Int, AlexanderDegree: Int) {
            let n = sequence.count
            self.code = Self.encode(sequence)
            self.size = n
            self.MaslovDegree = MaslovDegree
            self.AlexanderDegree = AlexanderDegree
        }
        
        public var sequence: [Int] {
            Self.decode(code, size)
        }
        
        public var points: [GridDiagram.Point] {
            sequence.enumerated().map { (i, j) in .init(2 * i, 2 * j) }
        }
        
        public var degree: Int {
            MaslovDegree
        }
        
        public func isAdjacent(to y: Self) -> Bool {
            Set(sequence).subtracting(y.sequence).count == 2
        }
        
        public static func == (x: Self, y: Self) -> Bool {
            (x.code, x.size) == (y.code, y.size)
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(code)
        }
        
        public static func < (x: Self, y: Self) -> Bool {
            x.code < y.code
        }
        
        // See: Knuth, Volume 2, Section 3.3.2, Algorithm P
        fileprivate static func encode(_ _seq: [Int]) -> Int {
            var (seq, r) = (_seq, _seq.count)
            var code = 0
            
            while r > 0 {
                let m = (0 ..< r).first { m in
                    r - seq[m] == 1
                }!
                code = code * r + m
                r -= 1
                seq.swapAt(r, m)
            }
            
            return code
        }
        
        fileprivate static func decode(_ _code: Int, _ size: Int) -> [Int] {
            var (code, r) = (_code, 1)
            var seq = Array(0 ..< size)
            
            while r < size {
                let m = code % (r + 1)
                code = code / (r + 1)
                seq.swapAt(r, m)
                r += 1
            }
            
            return seq
        }
        
        public var description: String {
            "\(sequence)"
        }
    }
    
    public struct GeneratorSet: Sequence {
        private let data: [Int : Generator]
        public let degreeRange: ClosedRange<Int>
        
        public init(for G: GridDiagram) {
            self.init(for: G, filter: { _ in true })
        }
        
        public init(for G: GridDiagram, filter: @escaping (Generator) -> Bool) {
            let data = Builder(G, filter: filter).build()
            self.init(data: data)
        }
        
        public init(data: Set<Generator>) {
            self.init(data: Dictionary(pairs: data.map { x in (x.code, x) }))
        }
        
        private init(data: [Int : Generator]) {
            self.data = data
            self.degreeRange = data.values.map{ $0.degree }.range ?? (0 ... 0)
        }
        
        public func generator(forSequence seq: [Int]) -> Generator? {
            let code = Generator.encode(seq)
            return data[code]
        }
        
        public func adjacents(of x: Generator) -> [Generator] {
            let xSeq = x.sequence
            let n = xSeq.count
            let trans = (0 ..< n).choose(2)
            return trans.compactMap { t in
                let ySeq = xSeq.with{ $0.swapAt(t[0], t[1]) }
                let yCode = Generator.encode(ySeq)
                return data[yCode]
            }
        }
        
        public func filter(_ predicate: (Generator) -> Bool) -> Self {
            .init(data: data.filter{ (_, x) in
                predicate(x)
            })
        }
        
        public func makeIterator() -> AnySequence<Generator>.Iterator {
            AnySequence(data.values).makeIterator()
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
    }
    
    private final class Builder {
        typealias Point = GridDiagram.Point
        typealias Rect  = GridDiagram.Rect

        let G: GridDiagram
        let filter: (Generator) -> Bool
        let rects: [Rect : (Int, Int)]
        let trans: [(Int, Int)]
        
        init(_ G: GridDiagram, filter: @escaping (Generator) -> Bool) {
            self.G = G
            self.filter = filter
            
            let n = G.gridNumber
            self.rects = Self.buildRects(G)
            self.trans = Self.heapTranspositions(length: n - 1)
        }
        
        func build() -> Set<Generator> {
            let n = G.gridNumber
            
            var data: Set<Generator> = []
            data.reserveCapacity(n.factorial)
            
            let queue = DispatchQueue(label: "", qos: .userInteractive)
            
            Array(0 ..< n).parallelForEach { i in
                let data_i = self.build(step: i)
                queue.sync {
                    data.formUnion(data_i)
                }
            }
            
            return data
        }
        
        private func build(step i: Int) -> Set<Generator> {
            let n = G.gridNumber
            let (Os, Xs) = (G.Os, G.Xs)
            
            var data: Set<Generator> = []
            data.reserveCapacity((n - 1).factorial)
            
            func add(_ seq: [Int], _ M: Int, _ A: Int) {
                let x = Generator(
                    sequence: seq,
                    MaslovDegree: M,
                    AlexanderDegree: A
                )
                
                if filter(x) {
                    data.insert(x)
                }
            }
            
            var seq = Array(0 ..< n)
            seq.swapAt(i, n - 1)
            
            var pts = points(seq)
            var (m, a) = (M(pts), A(pts))

            add(seq, m, a)
            
            for (i, j) in trans {
                // M(y) - M(x) = 2 #(r ∩ Os) - 2 #(x ∩ Int(r)) - 1
                // A(y) - A(x) = #(r ∩ Os) - #(r ∩ Xs)

                let r = GridDiagram.Rect(from: pts[i], to: pts[j], gridSize: G.gridSize)
                let (nO, nX) = rects[r]!
                let c = (i + 1 ..< j).count { i in
                    r.contains(pts[i], interior: true)
                }

                let dm = 2 * (nO - c) - 1
                let da = nO - nX

                seq.swapAt(i, j)

                pts[i] = Point(2 * i, 2 * seq[i])
                pts[j] = Point(2 * j, 2 * seq[j])
                
                m += dm
                a += da

                add(seq, m, a)
            }
            
            return data
        }
        
        private func points(_ seq: [Int]) -> [Point] {
            seq.enumerated().map { (i, j) in Point(2 * i, 2 * j) }
        }
        
        private func I(_ x: [Point], _ y: [Point]) -> Int {
            (x * y).count{ (p, q) in p < q }
        }
        
        private func J(_ x: [Point], _ y: [Point]) -> Int {
            I(x, y) + I(y, x)
        }
        
        private func M(_ ref: [Point], _ x: [Point]) -> Int {
            ( J(x, x) - 2 * J(x, ref) + J(ref, ref) ) / 2 + 1
        }
        
        private func M(_ x: [Point]) -> Int {
            M(G.Os, x)
        }
        
        private func A(_ x: [Point]) -> Int {
            ( M(G.Os, x) - M(G.Xs, x) - G.gridNumber + 1 ) / 2
        }
        
        private static func buildRects(_ G: GridDiagram) -> [Rect : (Int, Int)] {
            let n = G.gridNumber
            let (Os, Xs) = (G.Os, G.Xs)

            let rects = ((0 ..< n) * (0 ..< n)).flatMap { (x, y) -> [Rect] in
                return ((0 ..< n) * (0 ..< n)).map { (w, h) -> Rect in
                    return Rect(
                        origin: Point(2 * x, 2 * y),
                        size: Point(2 * w, 2 * h),
                        gridSize: G.gridSize
                    )
                }
            }
            
            return Dictionary(keys: rects) { r in
                let nO = Os.count { O in r.contains(O) }
                let nX = Xs.count { X in r.contains(X) }
                return (nO, nX)
            }
        }
        
        // see Heap's algorithm: https://en.wikipedia.org/wiki/Heap%27s_algorithm
        private static func heapTranspositions(length n: Int) -> [(Int, Int)] {
            var result: [(Int, Int)] = []
            result.reserveCapacity(n.factorial)
            
            func generate(_ k: Int) {
                if k <= 1 {
                    return
                }
                
                generate(k - 1)
                
                for l in 0 ..< k - 1 {
                    let (i, j) = (k % 2 == 0) ? (l, k - 1) : (0, k - 1)
                    result.append( (i, j) )
                    
                    generate(k - 1)
                }
            }
            
            generate(n)
            
            return result
        }
    }
}

extension GridDiagram {
    public func rectangles(from x: GridComplex.Generator, to y: GridComplex.Generator) -> [Rect] {
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
    
    public func emptyRectangles(from x: GridComplex.Generator, to y: GridComplex.Generator) -> [Rect] {
        // Note: Int(r) ∩ x = Int(r) ∩ y .
        rectangles(from: x, to: y).filter{ r in
            !r.intersects(x.points, interior: true)
        }
    }
}
