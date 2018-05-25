//
//  DynamicType.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/06/04.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol AlgebraicStructure: Structure {}

public protocol GroupStructure: AlgebraicStructure {}

public protocol SubgroupStructure: GroupStructure {
    associatedtype Base: Group
    func contains(_ g: Base) -> Bool
}

public protocol ModuleStructure: AlgebraicStructure {
    associatedtype R: Ring
}
