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
        public  let gridNumber: Int
        private let generators: [Int : Generator]
        private let transpositions: [(Int, Int)]
        
        public init(for G: GridDiagram) {
            self.init(for: G, filter: { _ in true })
        }
        
        public init(for G: GridDiagram, filter: @escaping (Generator) -> Bool) {
            let generators = Generator.produce(G, filter: filter)
            self.init(gridNumber: G.gridNumber, generators: generators)
        }
        
        public init(gridNumber: Int, generators: Set<Generator>) {
            self.init(gridNumber: gridNumber, generators: Dictionary(pairs: generators.map { x in (x.code, x) }))
        }
        
        private init(gridNumber: Int, generators: [Int : Generator]) {
            self.gridNumber = gridNumber
            self.generators = generators
            self.transpositions = (0 ..< gridNumber).choose(2).map{ t in (t[0], t[1]) }
        }
        
        public var degreeRange: ClosedRange<Int> {
            generators.values.map{ $0.degree }.range ?? (0 ... 0)
        }
        
        public func generator(forSequence seq: [Int]) -> Generator? {
            let code = Generator.encode(seq)
            return generators[code]
        }
        
        public func adjacents(of x: Generator) -> [(Generator, GridDiagram.Rect)] {
            typealias Point = GridDiagram.Point
            typealias Rect  = GridDiagram.Rect
            
            let n = gridNumber
            let seq = x.sequence
            let pts = x.points
            
            return transpositions.flatMap { (i, j) -> [(Generator, GridDiagram.Rect)] in
                let ySeq = seq.with{ $0.swapAt(i, j) }
                let yCode = Generator.encode(ySeq)
                
                guard let y = generators[yCode] else {
                    return []
                }
                
                let p = Point(2 * i, 2 * seq[i])
                let q = Point(2 * j, 2 * seq[j])
                let rs = [
                    Rect(from: p, to: q, gridSize: 2 * n),
                    Rect(from: q, to: p, gridSize: 2 * n)
                ]
                
                return rs.compactMap { r -> (Generator, GridDiagram.Rect)? in
                    r.intersects(pts, interior: true) ? nil : (y, r)
                }
            }
        }
        
        public func filter(_ predicate: (Generator) -> Bool) -> Self {
            GeneratorSet(
                gridNumber: gridNumber,
                generators: generators.filter{ (_, x) in predicate(x) }
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
    }
}
