//
//  Complex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/16.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public struct ComplexNumber: Field, ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = RealNumber
    
    private let x: RealNumber
    private let y: RealNumber
    
    public init(intValue x: Int) {
        self.init(RealNumber(x), 0)
    }
    
    public init(floatLiteral x: RealNumber) {
        self.init(x, 0)
    }
    
    public init(rationalValue r: RationalNumber) {
        self.init(RealNumber(rationalValue: r), 0)
    }
    
    public init(_ x: RealNumber) {
        self.init(x, 0)
    }
    
    public init(_ x: RealNumber, _ y: RealNumber) {
        self.x = x
        self.y = y
    }
    
    public init(r: Double, θ: Double) {
        self.init(r * cos(θ), r * sin(θ))
    }
    
    public static var imaginaryUnit: ComplexNumber {
        return ComplexNumber(0, 1)
    }
    
    public var real: RealNumber {
        return x
    }
    
    public var imaginary: RealNumber {
        return y
    }
    
    public var abs: RealNumber {
        return sqrt(x * x + y * y)
    }
    
    public var arg: RealNumber {
        let r = self.abs
        if(r == 0) {
            return 0
        }
        
        let t = acos(x / r)
        return (y >= 0) ? t : 2 * π - t
    }
    
    public var conjugate: ComplexNumber {
        return ComplexNumber(x, -y)
    }

    public var inverse: ComplexNumber? {
        let r2 = x * x + y * y
        return r2 == 0 ? nil : ComplexNumber(x / r2, -y / r2)
    }
    
    public static func ==(lhs: ComplexNumber, rhs: ComplexNumber) -> Bool {
        return (lhs.x == rhs.x) && (lhs.y == rhs.y)
    }
    
    public static func +(a: ComplexNumber, b: ComplexNumber) -> ComplexNumber {
        return ComplexNumber(a.x + b.x, a.y + b.y)
    }
    
    public static prefix func -(a: ComplexNumber) -> ComplexNumber {
        return ComplexNumber(-a.x, -a.y)
    }
    
    public static func *(a: ComplexNumber, b: ComplexNumber) -> ComplexNumber {
        return ComplexNumber(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x)
    }
    
    public var hashValue: Int {
        let p = 104743
        return (x.hashValue % p) &+ (y.hashValue % p) * p
    }
    
    public var description: String {
        return (x != 0 && y != 0) ? "\(x) + \(y)i" :
                         (y != 0) ? "\(y)i"
                                  : "\(x)"
    }
    
    public static var symbol: String {
        return "C"
    }
}
