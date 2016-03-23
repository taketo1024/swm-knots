# Protocol-Oriented Algebra

Sample project to explain concepts of [Abstract Algebra](https://en.wikipedia.org/wiki/Abstract_algebra) by implementing in Swift.

## Sample

### Rational Number

```swift
let a = ℚ(4, 5)  // 4/5
let b = ℚ(3, 2)  // 3/2

a + b  // 23/10
a * b  // 6/5
b / a  // 15/8
```

### Matrix (type safe)

```swift
typealias n = TPInt_2
typealias M = Matrix<ℤ, n, n>

let a = M(1, 2, 3, 4)  // [1, 2; 3, 4]
let b = M(2, 1, 1, 2)  // [2, 1; 1, 2]

a + b  // [3, 3; 4, 6]
a * b  // [4, 5; 10, 11]

a + b == b + a  // true: addition is commutative
a * b == b * a  // false: multiplication is noncommutative
```

### Permutation (Symmetric Group)

```swift
typealias 𝔖_5 = Permutation<TPInt_5>

let σ = 𝔖_5(0, 1, 2) // cyclic notation
let τ = 𝔖_5([0: 2, 1: 3, 2: 4, 3: 0, 4: 1]) // two-line notation

σ[1]  // 2
τ[2]  // 4

(σ * τ)[3]  // 3 -> 0 -> 1 
(τ * σ)[3]  // 3 -> 3 -> 0

σ * τ == τ * σ   // false: noncommutative
```

### Integer Quotient (Finite Field)

```swift
struct I: IntIdeal { static let generator = 5 }
typealias ℤ_5 = IntQuotient<I>

let a: ℤ_5 = 2  // 2 mod 5
let b: ℤ_5 = 4  // 4 mod 5
let c: ℤ_5 = 8  // 3 mod 5
    
a + b  // 1 mod 5
a * b  // 3 mod 5
    
typealias 𝔽_5 = IntQuotientField<I>

let x: 𝔽_5 = 2  // 2 mod 5
let y = 1 / x   // 3 mod 5
x * y == 1      // true
```

### Polynominal Quotient (Field Extension)

```swift
struct g: PolynominalIdeal {
    typealias R = Polynominal<ℚ>
    static let generator = Polynominal<ℚ>(-2, 0, 1)
}
typealias L = PolynominalQuotientField<ℚ, g>  // L = ℚ[x]/(g)

let a = L(0, 1) // a = √2 in L
a * a == 2      // true

(1 + a) * (1 + a) == 3 + 2 * a  // true: (1 + √2)^2   = 3 + 2√2
1 / (1 + a)       == -1 + a     // true: 1 / (1 + √2) = -1 + √2

struct h: PolynominalIdeal {
    typealias R = Polynominal<L>
    static let generator = R(-3, 0, 1)
}
typealias M = PolynominalQuotientField<L, h>  // M = L[x]/(h)

let b = M(a)      // b = √2 in M
let c = M(0, 1)   // c = √3 in M
let d = b * c     // d = √6 in M

b * b == 2        // true
c * c == 3        // true
d * d == 6        // true

(b + c) ** 2 == 5 + 2 * d // true: (√2 + √3)^2 = 5 + 2√6
}
```

## Project Structure
* Abstract
  * [Monoid](Algebra.playground/Sources/Abstract/Monoid.swift)
  * [Group](Algebra.playground/Sources/Abstract/Group.swift)
  * [AdditiveGroup](Algebra.playground/Sources/Abstract/AdditiveGroup.swift)
  * [Ring](Algebra.playground/Sources/Abstract/Ring.swift)
  * [EuclideanRing](Algebra.playground/Sources/Abstract/EuclideanRing.swift)
  * [Field](Algebra.playground/Sources/Abstract/Field.swift)
* Concrete
  * Numbers
    * [Integer](Algebra.playground/Sources/Concrete/Numbers/Integer.swift)
    * [Rational](Algebra.playground/Sources/Concrete/Numbers/Rational.swift)
    * [Real](Algebra.playground/Sources/Concrete/Numbers/Real.swift)
  * [Permutation](Algebra.playground/Sources/Concrete/Permutation.swift)
  * [Matrix](Algebra.playground/Sources/Concrete/Matrix.swift)
  * [Polynominal](Algebra.playground/Sources/Concrete/Polynominal.swift)
* Quotient
  * [QuotientRing](Algebra.playground/Sources/Quotient/QuotientRing.swift)
  * [IntQuotientRing](Algebra.playground/Sources/Quotient/IntQuotientRing.swift)
  * [PolynominalQuotientRing](Algebra.playground/Sources/Quotient/PolynominalQuotientRing.swift)

## Guide to Abstract Algebra

1. [数とは何か？](http://qiita.com/taketo1024/items/bd356c59dc0559ee9a0b) 
2. [群・環・体の定義](http://qiita.com/taketo1024/items/733e0ecf12da359db729)
3. [有理数を作ってみよう](http://qiita.com/taketo1024/items/222a6a418fb29a0684f8)
4. [時計の世界の「環」](http://qiita.com/taketo1024/items/91fbc70136b0e5706c09)
5. [小さな「体」を作ろう](http://qiita.com/taketo1024/items/f5cd40bf669fa8511f9b)
6. [多項式は整数によく似てる](http://qiita.com/taketo1024/items/83be0ad7d2f2e4f3f44d)
7. [代数拡大で数を作ろう！](http://qiita.com/taketo1024/items/ccf7ece3dfeb98b38946)

## License
ProtocolOrientedAlgebra is licensed under [CC0 1.0](LICENSE).
