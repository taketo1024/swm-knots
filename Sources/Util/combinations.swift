//
//  combinations.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/18.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public func combi(_ n: Int, _ k: Int) -> [[Int]] {
    switch (n, k) {
    case _ where n < k:
        return []
    case (_, 0):
        return [[]]
    default:
        return combi(n - 1, k) + combi(n - 1, k - 1).map{ $0 + [n - 1] }
    }
}

public func multicombi(_ n: Int, _ k: Int) -> [[Int]] {
    switch (n, k) {
    case (0, _), (_, 0):
        return []
    default:
        let m = (0 ..< k).flatMap { i in
            multicombi(n - 1, k - i).map{ $0 + Array(repeating: n - 1, count: i) }
        }
        return m + [Array(repeating: n - 1, count: k)]
    }
}
