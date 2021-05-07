//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/07.
//

import Foundation

internal class Util {
    static func generateBinarySequences<T>(with choice: (T, T), length n: Int) -> [[T]] {
        assert(n <= 64)
        return (0 ..< 2.pow(n)).map { (b0: Int) -> [T] in
            var b = b0
            return (0 ..< n).reduce(into: []) { (result, _) in
                result.append( (b & 1 == 0) ? choice.0 : choice.1 )
                b >>= 1
            }
        }
    }
}
