//
//  SquareMatrix.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/17.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias SquareMatrix<n: _Int, R: Ring> = Matrix<n, n, R>

// TODO: conform to Ring after conditional conformance is supported.
public extension SquareMatrix where n == m {
    public static var identity: Matrix<n, n, R> {
        return Matrix<n, n, R> { $0 == $1 ? 1 : 0 }
    }
    
    public var size: Int {
        return rows
    }
    
    public var trace: R {
        return (0 ..< rows).sum { i in self[i, i] }
    }
    
    public var isZero: Bool {
        return self.forAll{ (_, _, r) in r == .zero }
    }
    
    public var isDiagonal: Bool {
        return self.forAll{ (i, j, r) in (i == j) || r == .zero }
    }
    
    public var isSymmetric: Bool {
        if size <= 1 {
            return true
        }
        return (0 ..< rows - 1).forAll { i in
            (i + 1 ..< cols).forAll { j in
                self[i, j] == self[j, i]
            }
        }
    }
    
    public var isSkewSymmetric: Bool {
        if size <= 1 {
            return isZero
        }
        return (0 ..< rows - 1).forAll { i in
            (i + 1 ..< cols).forAll { j in
                self[i, j] == -self[j, i]
            }
        }
    }
    
    public var isOrthogonal: Bool {
        return self.transposed * self == .identity
    }

    public static func ** (a: Matrix<n, n, R>, k: Int) -> Matrix<n, n, R> {
        return k == 0 ? .identity : a * (a ** (k - 1))
    }
}

public extension SquareMatrix where n == m, R: EuclideanRing {
    public var determinant: R {
        return eliminate().determinant
    }
    
    public var isInvertible: Bool {
        return determinant.isInvertible
    }
    
    public var inverse: Matrix<n, n, R>? {
        return eliminate().inverse
    }
}

public extension SquareMatrix where n == m, R == ComplexNumber {
    public var isHermitian: Bool {
        if size <= 1 {
            return true
        }
        return (0 ..< rows - 1).forAll { i in
            (i + 1 ..< cols).forAll { j in
                self[i, j] == self[j, i].conjugate
            }
        }
    }
    
    public var isSkewHermitian: Bool {
        if size <= 1 {
            return isZero
        }
        return (0 ..< rows - 1).forAll { i in
            (i + 1 ..< cols).forAll { j in
                self[i, j] == -self[j, i].conjugate
            }
        }
    }
    
    public var isUnitary: Bool {
        return self.adjoint * self == .identity
    }
}
