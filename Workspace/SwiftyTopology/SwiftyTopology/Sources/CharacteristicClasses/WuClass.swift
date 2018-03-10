//
//  WuClass.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/02/12.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation
import SwiftyAlgebra

public extension SimplicialComplex {
    public func WuClass(_ p: Int) -> CohomologyClass<Dual<Simplex>, Z_2>? {
        guard let μ = orientationClass(Z_2.self) else {
            return nil
        }
        
        // Let H^p =: <a_1, ..., a_k>,
        //     v_p =: Σ x_i a_i ∈ H^p
        //
        // Aim: compute (x_i)'s.
        //
        // Let p + q = n,
        //     H^q =: <b_1, ..., b_k> ( H^q ~= (H^q)^* ~= H^p, since Z_2: field)
        
        let cH = Cohomology(self, Z_2.self)
        let n = cH.topDegree
        let q = n - p
        
        let a = cH[p].generators
        let b = cH[q].generators
        let k = a.count
        
        // F: H^p --> (H^q)^*  lin. isom. is defined as:
        //     x  --> (y -> <x ∪ y, μ>)
        //
        // Let F(a_j) =: Σ F_ij b_i^* then
        //
        //   F_ij = F(a_j)(b_i) = <a_j ∪ b_i, μ>
        //
        // G := F^-1
        
        let F = DynamicMatrix(rows: k, cols: k) { (i, j) in
            pair(a[j] ∪ b[i], μ)
        }
        
        let G = F.inverse!
        
        // v_p ∈ H^p is the unique class s.t.
        //
        //   <v_p ∪ y, μ> = <Sq^p(y), μ> (y ∈ H^q)
        //
        // Let f_p := <Sq^p(-), μ> ∈ (H^q)^*, then
        //
        //   F(v_p) = f_p  <==>  v_p = G(f_p)
        //
        // Let f_p =: Σ y_i b_i^* , then
        //
        //   y_i = f_p(b_i) = <Sq^p(b_i), μ>
        //
        // Thus we have (x) = G(y).
        
        let y = DynamicColVector(rows: k) { (i, _) in
            pair(b[i].Sq(p), μ)
        }
        
        let x = G * y
        return x.sum { (i, _, x_i) in x_i * a[i] }
    }
    
    public var WuClasses: [CohomologyClass<Dual<Simplex>, Z_2>] {
        return validDims.flatMap { i in WuClass(i) }
    }
    
    public var totalWuClass: CohomologyClass<Dual<Simplex>, Z_2> {
        return WuClasses.sumAll()
    }
}
