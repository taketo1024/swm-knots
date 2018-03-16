//
//  Quaternion
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/16.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//
//  see: https://en.wikipedia.org/wiki/Quaternion

import Foundation

public struct Quaternion: Field, ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = RealNumber
    
    private let x: RealNumber
    private let y: RealNumber
    private let z: RealNumber
    private let w: RealNumber

    public init(intValue x: Int) {
        self.init(RealNumber(x))
    }
    
    public init(floatLiteral x: RealNumber) {
        self.init(x)
    }
    
    public init(_ x: RealNumber) {
        self.init(x, 0, 0, 0)
    }
    
    public init(_ z: ComplexNumber) {
        self.init(z.real, z.imaginary, 0, 0)
    }
    
    public init(_ z: ComplexNumber, _ w: ComplexNumber) {
        self.init(z.real, z.imaginary, w.real, w.imaginary)
    }
    
    public init(_ x: RealNumber, _ y: RealNumber, _ z: RealNumber, _ w: RealNumber) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    public static var i: Quaternion {
        return Quaternion(0, 1, 0, 0)
    }
    
    public static var j: Quaternion {
        return Quaternion(0, 0, 1, 0)
    }
    
    public static var k: Quaternion {
        return Quaternion(0, 0, 0, 1)
    }
    
    public var realPart: RealNumber {
        return x
    }
    
    public var imaginaryPart: Quaternion {
        return Quaternion(0, y, z, w)
    }
    
    public var abs: RealNumber {
        return sqrt(x * x + y * y + z * z + w * w)
    }
    
    public var conjugate: Quaternion {
        return Quaternion(x, -y, -z, -w)
    }

    public var inverse: Quaternion? {
        let r2 = x * x + y * y + z * z + w * w
        return r2 == 0 ? .zero : Quaternion(x / r2, -y / r2, -z / r2, -w / r2)
    }
    
    public static func ==(lhs: Quaternion, rhs: Quaternion) -> Bool {
        return (lhs.x == rhs.x) && (lhs.y == rhs.y)
    }
    
    public static func +(a: Quaternion, b: Quaternion) -> Quaternion {
        return Quaternion(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w)
    }
    
    public static prefix func -(a: Quaternion) -> Quaternion {
        return Quaternion(-a.x, -a.y, -a.z, -a.w)
    }
    
    public static func *(a: Quaternion, b: Quaternion) -> Quaternion {
        return Quaternion(
            a.x * b.x - a.y * b.y - a.z * b.z - a.w * b.w,
            a.x * b.y + a.y * b.x + a.z * b.w - a.w * b.z,
            a.x * b.z - a.y * b.w + a.z * b.x + a.w * b.y,
            a.x * b.w + a.y * b.z - a.z * b.y - a.w * b.x
        )
    }
    
    public var hashValue: Int {
        let p = 31
        return [x, y, z, w].reduce(0) { (res, r) in
            res &* p &+ (r.hashValue % p)
        }
    }
    
    public var description: String {
        if self == .zero {
            return "0"
        } else {
            return [(x, ""), (y, "i"), (z, "j"), (w, "k")]
                .filter{ $0.0 != .zero }
                .map{ "\($0.0)\($0.1)" }
                .joined(separator: " + ")
        }
    }
    
    public static var symbol: String {
        return "H"
    }
}
