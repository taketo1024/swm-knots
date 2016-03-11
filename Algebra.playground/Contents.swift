//: Playground - noun: a place where people can play

import Foundation

/* frequently used types */

typealias _1 = TPInt_1
typealias _2 = TPInt_2
typealias _3 = TPInt_3
typealias _4 = TPInt_4

typealias N = UInt
typealias Z = Integer
typealias Q = RationalNumber
typealias R = RealNumber

typealias Qx = Polynominal<Q>
typealias Rx = Polynominal<R>

typealias M2_Z = Matrix<Z,_2,_2>
typealias M3_Z = Matrix<Z,_3,_3>
typealias M4_Z = Matrix<Z,_4,_4>

typealias M2_Q = Matrix<Q,_2,_2>
typealias M3_Q = Matrix<Q,_3,_3>
typealias M4_Q = Matrix<Q,_4,_4>

typealias M2_R = Matrix<R,_2,_2>
typealias M3_R = Matrix<R,_3,_3>
typealias M4_R = Matrix<R,_4,_4>

typealias S_2 = Permutation<_2>
typealias S_3 = Permutation<_3>
typealias S_4 = Permutation<_4>

/* sample */

let a: Matrix<Z,_3,_2> = Matrix(2, 3, 1, 4, 2, 1)
let b: Matrix<Z,_2,_3> = Matrix(3, 1, 2, 2, 4, 2)
let c: Matrix<Z,_3,_3> = a * b

typealias M = Matrix<Qx, _2, _2>

let x = M(Qx(3, 2, 3), Qx(2, 1),
          Qx(-1, 3)  , Qx(3, 2))

det(x)
