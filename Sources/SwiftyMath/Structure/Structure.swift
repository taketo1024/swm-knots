//
//  Structure.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/05/24.
//

import Foundation

// A `Structure` instance expresses a mathematical structure that is determined dynamically.
// Used when we want a 'dynamic-type', where Swift-types are strictly static.
//
// * All finite subgroups of a finite (static) group.
// * The invariant factor decomposition of a given f.g. module.
// * The Homology group of a given SimplicialComplex.

public protocol Structure: Equatable, CustomStringConvertible { }
