//
//  GridComplexGenerator.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/09/10.
//

import SwiftyMath

public struct GridComplexGenerators: Sequence {
    public struct Generator: FreeModuleGenerator {
        public let id: Int
        
        fileprivate let int8sequence: [Int8]
        public let MaslovDegree: Int
        public let AlexanderDegree: Int
        
        fileprivate init(id: Int, sequence: [Int8], MaslovDegree: Int, AlexanderDegree: Int) {
            self.id = id
            self.int8sequence = sequence
            self.MaslovDegree = MaslovDegree
            self.AlexanderDegree = AlexanderDegree
        }
        
        public var sequence: [Int] {
            return int8sequence.map{ Int($0) }
        }
        
        public var points: [GridDiagram.Point] {
            return int8sequence.enumerated().map { (i, j) in .init(2 * i, 2 * Int(j)) }
        }
        
        public var degree: Int {
            return MaslovDegree
        }
        
        public func isAdjacent(to y: Generator) -> Bool {
            let x = self
            let (ps, qs) = (x.points, y.points)
            return Set(ps).subtracting(qs).count == 2
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
            return "\(int8sequence)"
        }
    }
    
    private let data: [[Int8] : Generator]
    public let degreeRange: ClosedRange<Int>
    
    public init(for G: GridDiagram) {
        
        let (Os, Xs) = (G.Os, G.Xs)
        let n = G.Os.count
        
        let x_TL: Generator = {
            let seq = Os.map{ p in Int8( ((p.y + 1) / 2) % n ) }
            let points = seq.enumerated().map { (i, j) in GridDiagram.Point(2 * i, 2 * Int(j)) }
            
            let curve = GridDiagram.ClosedCurve(from: Os, to: Xs)
            let w = { p in curve.windingNumber(around: p) }
            
            let a = points.sum { p in w(p) }
            let b = (Os + Xs).sum { p in p.corners.sum{ q in w(q) } }
            let A = -a + ( b / 4 - (n - 1) ) / 2
            
            return Generator(id: 0, sequence: seq, MaslovDegree: 0, AlexanderDegree: A)
        }()
        
        let generators = GridComplexGenerators
            .generateSequences(ofLength: n)
            .reduce(into: [x_TL]) { (result, next) in
                if result.count == 1 {
                    result.reserveCapacity(n.factorial + 1)
                }
                
                let x = result.last!
                let (i, j) = next
                let rect = GridDiagram.Rect(from: x.points[i], to: x.points[j], gridSize: 2 * n)
                
                // M(y) - M(x) = 2 #(r ∩ Os) - 2 #(x ∩ Int(r)) - 1
                let m = 2 * Os.count{ O in rect.contains(O) } - 2 * x.points.count{ p in rect.contains(p, interior: true) } - 1
                
                // A(y) = A(x) + #(r ∩ Os) - #(r ∩ Xs)
                let a = Os.count{ O in rect.contains(O) } - Xs.count{ X in rect.contains(X) }
                
                let y = Generator(
                    id: x.id + 1,
                    sequence: x.int8sequence.swappedAt(i, j),
                    MaslovDegree: x.MaslovDegree + m,
                    AlexanderDegree: x.AlexanderDegree + a
                )
                
                result.append(y)
        }
        
        self.init(data: Dictionary(pairs: generators.map{ x in (x.int8sequence, x) }))
    }
    
    // see Heap's algorithm: https://en.wikipedia.org/wiki/Heap%27s_algorithm
    private static func generateSequences(ofLength n: Int) -> [(Int, Int)] {
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
    
    private init(data: [[Int8] : Generator]) {
        self.data = data
        self.degreeRange = data.values.map{ $0.degree }.range ?? (0 ... 0)
    }
    
    public var generators: Set<Generator> {
        return Set(data.values)
    }
    
    public func generator(forSequence seq: [Int]) -> Generator? {
        return generator(forSequence: seq.map{ Int8($0) })
    }
    
    private func generator(forSequence seq: [Int8]) -> Generator? {
        return data[seq]
    }
    
    public func adjacents(of x: Generator) -> [Generator] {
        let xSeq = x.int8sequence
        let n = x.sequence.count
        return DPermutation.rawTranspositions(within: n).compactMap { t in
            let ySeq = xSeq.swappedAt(t.0, t.1)
            return generator(forSequence: ySeq)
        }
    }
    
    public func filter(_ predicate: (Generator) -> Bool) -> GridComplexGenerators {
        let data = self.data.filter{ (_, x) in predicate(x) }
        return .init(data: data)
    }
    
    public func makeIterator() -> Set<Generator>.Iterator {
        return generators.makeIterator()
    }
}

extension GridDiagram {
    public typealias Generator = GridComplexGenerators.Generator
    
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
            !r.intersects(x.points, interior: true)
        }
    }
}
