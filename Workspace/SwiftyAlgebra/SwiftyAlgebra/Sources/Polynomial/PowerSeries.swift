//
//  PowerSeries.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/12.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public struct PowerSeries<K: Field>: Ring, Module {
    public typealias CoeffRing = K
    public let coeffs: (Int) -> K
    
    public init(intValue n: Int) {
        self.init() { i in
            (i == 0) ? K(intValue: n) : .zero
        }
    }
    
    public init(_ coeffs: @escaping ((Int) -> K)) {
        self.coeffs = coeffs
    }
    
    public var inverse: PowerSeries<K>? {
        guard let b0 = constantTerm.inverse else {
            return nil
        }
        
        var list = [b0]
        func invCoeff(_ i: Int) -> K {
            if i < list.count { return list[i] }
            let b_i = -b0 * (1 ... i).sum{ j in coeff(j) * invCoeff(i - j) }
            list.append(b_i)
            return b_i
        }
        return PowerSeries<K> { i in invCoeff(i) }
    }
    
    public func coeff(_ i: Int) -> K {
        assert(i >= 0)
        return coeffs(i)
    }
    
    public var constantTerm: K {
        return self.coeff(0)
    }
    
    public func map(_ f: @escaping (K) -> K ) -> PowerSeries<K> {
        return PowerSeries<K>.init() { i in
            f( self.coeffs(i) )
        }
    }
    
    public static func == (f: PowerSeries<K>, g: PowerSeries<K>) -> Bool {
        fatalError("== not available for PowerSeries.")
    }
    
    public static func + (f: PowerSeries<K>, g: PowerSeries<K>) -> PowerSeries<K> {
        return PowerSeries<K>() { i in
            f.coeff(i) + g.coeff(i)
        }
    }
    
    public static prefix func - (f: PowerSeries<K>) -> PowerSeries<K> {
        return f.map { -$0 }
    }
    
    public static func * (f: PowerSeries<K>, g: PowerSeries<K>) -> PowerSeries<K> {
        return PowerSeries<K> { i in
            (0 ... i).sum { j in
                f.coeff(j) * g.coeff(i - j)
            }
        }
    }
    
    public static func * (r: K, f: PowerSeries<K>) -> PowerSeries<K> {
        return f.map { r * $0 }
    }
    
    public static func * (f: PowerSeries<K>, r: K) -> PowerSeries<K> {
        return f.map { $0 * r }
    }
    
    public var description: String {
        return Expression.terms("+", (0 ..< 5).map{ n in (coeff(n), "x", n) }) + " ..."
    }
    
    public static var symbol: String {
        return "\(K.symbol)[[x]]"
    }
    
    public var hashValue: Int {
        let p = 31
        return (0 ..< 3).reduce(0){ (res, i) in res &* p &+ (coeff(i).hashValue % p) }
    }
}

public extension PowerSeries where K == RationalNumber {
    public static var exp: PowerSeries<RationalNumber> {
        return PowerSeries<RationalNumber>() { n in
            RationalNumber(1, n.factorial)
        }
    }
}
