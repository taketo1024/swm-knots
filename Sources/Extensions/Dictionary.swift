//
//  Dictionary.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/03.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

internal extension Dictionary {
    internal init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
    
    internal func mapPairs<OutKey, OutValue>(transform: (Key, Value) -> (OutKey, OutValue)) -> [OutKey: OutValue] {
        return Dictionary<OutKey, OutValue>(map(transform))
    }
    
    internal func mapValues<OutValue>(transform: (Value) -> OutValue) -> [Key: OutValue] {
        return Dictionary<Key, OutValue>( map{($0, transform($1))} )
    }
    
    internal static func generateBy<S: Sequence>(keys: S, generator: (Key) -> Value) -> Dictionary<Key, Value> where S.Iterator.Element == Key {
        return Dictionary(keys.map{($0, generator($0))})
    }
}
