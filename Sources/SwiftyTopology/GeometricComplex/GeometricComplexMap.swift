//
//  GeometricComplexMap.swift
//  SwiftyTopology
//
//  Created by Taketo Sano on 2018/03/10.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation
import SwiftyAlgebra

public protocol GeometricComplexMap: Map where Domain == ComplexType.Cell, Codomain == ComplexType.Cell {
    associatedtype ComplexType: GeometricComplex
}
