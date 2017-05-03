//
//  IntegerFactorization.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/03.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

private var primes: [IntegerNumber] = []

public func divisors(of n: IntegerNumber) -> [IntegerNumber] {
    if n == 0 {
        return []
    }
    
    var result: [IntegerNumber] = []
    
    let a = abs(n)
    let m = Int(sqrt(Double(a)))
    
    for d in 1...m {
        if a % d == 0 {
            result.append(d)
            result.append(a/d)
        }
    }
    
    return result.sorted()
}

public func primeFactors(of n: IntegerNumber) -> [IntegerNumber] {
    var result: [IntegerNumber] = []
    var q = n
    
    let ps = primes(upTo: n)
    for p in ps {
        while q % p == 0 {
            q /= p
            result.append(p)
        }
    }
    
    return result
}

public func primes(upTo n: IntegerNumber) -> [IntegerNumber] {
    if let last = primes.last, n <= last {
        return primes.filter{ $0 <= n }
    }
    
    var result: [IntegerNumber] = []
    var seive = primes + Array( (primes.last ?? 1) + 1 ... abs(n) )
    
    while let a = seive.first {
        seive = seive.filter{ $0 % a > 0 }
        result.append(a)
    }
    
    primes = result
    return result
}
