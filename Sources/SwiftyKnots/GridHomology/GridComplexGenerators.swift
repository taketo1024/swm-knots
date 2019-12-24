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
        public let id: Int
        
        public let sequence: [Int8]
        public let MaslovDegree: Int
        public let AlexanderDegree: Int
        
        public init(id: Int, sequence: [Int8], MaslovDegree: Int, AlexanderDegree: Int) {
            self.id = id
            self.sequence = sequence
            self.MaslovDegree = MaslovDegree
            self.AlexanderDegree = AlexanderDegree
        }
        
        public var points: [GridDiagram.Point] {
            sequence.enumerated().map { (i, j) in .init(2 * i, 2 * Int(j)) }
        }
        
        public var degree: Int {
            MaslovDegree
        }
        
        public func isAdjacent(to y: Self) -> Bool {
            let x = self
            let (ps, qs) = (x.points, y.points)
            return Set(ps).subtracting(qs).count == 2
        }
        
        public static func == (a: Self, b: Self) -> Bool {
            a.id == b.id
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        public static func < (g1: Self, g2: Self) -> Bool {
            g1.id < g2.id
        }
        
        public var description: String {
            "\(sequence)"
        }
    }
    
    public struct GeneratorSet: Sequence {
        private let data: [[Int8] : Generator]
        public let degreeRange: ClosedRange<Int>
        
        public init(for G: GridDiagram) {
            self.init(for: G, filter: { _ in true })
        }
        
        public init(for G: GridDiagram, filter: @escaping (Generator) -> Bool) {
            typealias Point = GridDiagram.Point
            let (Os, Xs) = (G.Os, G.Xs)
            
            func points(_ seq: [Int8]) -> [Point] {
                seq.enumerated().map { (i, j) in Point(2 * i, 2 * Int(j)) }
            }
            
            func degrees(_ x: [Point]) -> (Int, Int) {
                func I(_ x: [Point], _ y: [Point]) -> Int {
                    return (x * y).count{ (p, q) in p < q }
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
            
            // see Heap's algorithm: https://en.wikipedia.org/wiki/Heap%27s_algorithm
            func heapTranspositions(length n: Int) -> [(Int, Int)] {
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
            
            let n = G.Os.count
            let trans = heapTranspositions(length: n - 1)
            
            var data: [[Int8] : Generator] = [:]
            let queue = DispatchQueue(label: "", qos: .userInteractive)
            
            Array(0 ..< n).parallelForEach { i in
                let offset = i * (n - 1).factorial
                
                var seq = (0 ..< n).map{ Int8($0) }
                seq.swapAt(i, n - 1)
                
                var x = { () -> Generator in
                    let pts = points(seq)
                    let (M, A) = degrees(pts)
                    return Generator(
                        id: offset,
                        sequence: seq,
                        MaslovDegree: M,
                        AlexanderDegree: A
                    )
                }()
                
                var result: [[Int8] : Generator] = [:]
                result.reserveCapacity((n - 1).factorial)
                
                if filter(x) {
                    result[seq] = x
                }
                
                for (i, j) in trans {
                    seq.swapAt(i, j)
                    
                    let points = x.points
                    let rect = GridDiagram.Rect(from: points[i], to: points[j], gridSize: 2 * n)
                    
                    // M(y) - M(x) = 2 #(r ∩ Os) - 2 #(x ∩ Int(r)) - 1
                    let m = 2 * Os.count{ O in rect.contains(O) } - 2 * x.points.count{ p in rect.contains(p, interior: true) } - 1
                    
                    // A(y) - A(x) = #(r ∩ Os) - #(r ∩ Xs)
                    let a = Os.count{ O in rect.contains(O) } - Xs.count{ X in rect.contains(X) }
                    
                    let y = Generator(
                        id: x.id + 1,
                        sequence: seq,
                        MaslovDegree: x.MaslovDegree + m,
                        AlexanderDegree: x.AlexanderDegree + a
                    )
                    
                    if filter(y) {
                        result[seq] = y
                    }
                    
                    x = y
                }
                
                queue.sync {
                    data.merge(result)
                }
            }
            
            self.init(data: data)
        }
        
        private init(data: [[Int8] : Generator]) {
            self.data = data
            self.degreeRange = data.values.map{ $0.degree }.range ?? (0 ... 0)
        }
        
        public var generators: Set<Generator> {
            Set(data.values)
        }
        
        public func generator(forSequence seq: [Int8]) -> Generator? {
            data[seq]
        }
        
        public func adjacents(of x: Generator) -> [Generator] {
            let xSeq = x.sequence
            let trans = (0 ..< xSeq.count).choose(2)
            return trans.compactMap { t in
                let ySeq = xSeq.with{ $0.swapAt(t[0], t[1]) }
                return generator(forSequence: ySeq)
            }
        }
        
        public func filter(_ predicate: (Generator) -> Bool) -> Self {
            .init(data: data.filter{ (_, x) in predicate(x) })
        }
        
        public func makeIterator() -> Set<Generator>.Iterator {
            generators.makeIterator()
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
