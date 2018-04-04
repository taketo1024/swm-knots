//
//  Letters.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/03/10.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

// see: https://en.wikipedia.org/wiki/Unicode_subscripts_and_superscripts

public struct Format {
    public static func sup(_ i: Int) -> String {
        return sup(String(i))
    }
    
    public static func sup(_ s: String) -> String {
        return String( s.map { c in
            switch c {
            case "0": return "⁰"
            case "1": return "¹"
            case "2": return "²"
            case "3": return "³"
            case "4": return "⁴"
            case "5": return "⁵"
            case "6": return "⁶"
            case "7": return "⁷"
            case "8": return "⁸"
            case "9": return "⁹"
            case "-": return "⁻"
            default: return c
            }
        } )
    }
    
    public static func sub(_ i: Int) -> String {
        return sub(String(i))
    }
    
    public static func sub(_ s: String) -> String {
        return String( s.map { c in
            switch c {
            case "0": return "₀"
            case "1": return "₁"
            case "2": return "₂"
            case "3": return "₃"
            case "4": return "₄"
            case "5": return "₅"
            case "6": return "₆"
            case "7": return "₇"
            case "8": return "₈"
            case "9": return "₉"
            default: return c
            }
        } )
    }
    
    public static func symbol(_ x: String, _ i: Int) -> String {
        return "\(x)\(sub(i))"
    }
    
    public static func term<R: Ring>(_ a: R, _ x: String, _ n: Int = 1, skipZero: Bool = false) -> String {
        let (o, e) = (R.zero, R.identity)
        switch (a, n) {
        case ( o, _): return skipZero ? "" : "0"
        case ( _, 0): return "\(a)"
        case ( e, 1): return "\(x)"
        case (-e, 1): return "-\(x)"
        case ( _, 1): return "\(a)\(x)"
        case ( e, _): return "\(x)\(sup(n))"
        case (-e, _): return "-\(x)\(sup(n))"
        default:      return "\(a)\(x)\(sup(n))"
        }
    }
    
    public static func terms<R: Ring>(_ op: String, _ terms: [(R, String, Int)], skipZero: Bool = false) -> String {
        let ts = terms.compactMap{ (a, x, n) -> String? in
            let t = term(a, x, n, skipZero: skipZero)
            return (skipZero && t.isEmpty) ? nil : t
        }.joined(separator: " \(op) ")
        return ts.isEmpty ? "0" : ts
    }
}
