//
//  GridComplexGeneratorBuilder.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2020/02/06.
//

import SwiftyMath
import Dispatch

extension GridComplex.Generator {
    internal static func produce(_ G: GridDiagram, _ rects: GridComplex.GeneratorSet.Rects, _ filter: @escaping (Self) -> Bool) -> Set<Self> {
        Producer(G, rects, filter).produce()
    }
    
    private final class Producer {
        typealias Generator = GridComplex.Generator
        typealias Point = GridDiagram.Point
        typealias Rect  = GridDiagram.Rect

        let G: GridDiagram
        let rects: GridComplex.GeneratorSet.Rects
        let filter: (Generator) -> Bool
        let trans: [(Int, Int)]
        
        init(_ G: GridDiagram, _ rects: GridComplex.GeneratorSet.Rects, _ filter: @escaping (Generator) -> Bool) {
            self.G = G
            self.rects = rects
            self.filter = filter
            
            let n = G.gridNumber
            self.trans = Self.heapTranspositions(length: n - 1)
        }
        
        func produce() -> Set<Generator> {
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
                let nO = rects.countIntersections(r, .O)
                let nX = rects.countIntersections(r, .X)
                
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
