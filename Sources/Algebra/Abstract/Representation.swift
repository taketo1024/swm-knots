//
//  Representation.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/23.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol Representation: Map {}

public protocol GroupRepresentation: Representation, _GroupHom where Codomain == LinearAut<V> {
    associatedtype V
}

public protocol LieAlgebraRepresentation: Representation, _LieAlgebraHom where Codomain == LinearEnd<V> {
    associatedtype V
}
