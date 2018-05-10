//
//  KhBasisElement.swift
//  Sample
//
//  Created by Taketo Sano on 2018/04/19.
//

import Foundation
import SwiftyMath

public enum KhBasisElement: String, BasisElementType, Comparable, Codable {
    case I
    case X
    
    public typealias Product<R: Ring> = (KhBasisElement, KhBasisElement) -> [(KhBasisElement, R)]
    public typealias Coproduct<R: Ring> = (KhBasisElement) -> [(KhBasisElement, KhBasisElement, R)]
    
    public var degree: Int {
        switch self {
        case .I: return +1
        case .X: return -1
        }
    }
    
    public static func <(e1: KhBasisElement, e2: KhBasisElement) -> Bool {
        return e1.degree < e2.degree
    }
    
    public var description: String {
        return (self == .I) ? "I" : "X"
    }
}

public extension KhBasisElement {
    // Khovanov's map
    public static func μ<R: Ring>(_ e1: KhBasisElement, _ e2: KhBasisElement) -> [(KhBasisElement, R)] {
        switch (e1, e2) {
        case (.I, .I): return [(.I, .identity)]
        case (.I, .X), (.X, .I): return [(.X, .identity)]
        case (.X, .X): return []
        }
    }
    
    public static func Δ<R: Ring>(_ e: KhBasisElement) -> [(KhBasisElement, KhBasisElement, R)] {
        switch e {
        case .I: return [(.I, .X, .identity), (.X, .I, .identity)]
        case .X: return [(.X, .X, .identity)]
        }
    }
    
    // Lee's map
    public static func μ_Lee<R: Ring>(_ e1: KhBasisElement, _ e2: KhBasisElement) -> [(KhBasisElement, R)] {
        switch (e1, e2) {
        case (.X, .X): return [(.I, .identity)]
        default: return []
        }
    }
    
    public static func Δ_Lee<R: Ring>(_ e: KhBasisElement) -> [(KhBasisElement, KhBasisElement, R)] {
        switch e {
        case .X: return [(.I, .I, .identity)]
        default: return []
        }
    }
    
    // Bar-Natan's map
    public static func μ_BN<R: Ring>(_ e1: KhBasisElement, _ e2: KhBasisElement) -> [(KhBasisElement, R)] {
        switch (e1, e2) {
        case (.X, .X): return [(.X, .identity)]
        default: return []
        }
    }
    
    public static func Δ_BN<R: Ring>(_ e: KhBasisElement) -> [(KhBasisElement, KhBasisElement, R)] {
        switch e {
        case .I: return [(.I, .I, -.identity)]
        default: return []
        }
    }
}
