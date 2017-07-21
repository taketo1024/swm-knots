//
//  Dictionary.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/03.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

internal extension Dictionary {
    internal init<S: Sequence>(pairs: S) where S.Iterator.Element == (Key, Value) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
    
    internal init<S: Sequence>(keys: S, generator: (Key) -> Value) where S.Iterator.Element == Key {
        self.init(pairs: keys.map{ ($0, generator($0))} )
    }
    
    internal func mapPairs<OutKey, OutValue>(transform: (Key, Value) -> (OutKey, OutValue)) -> [OutKey: OutValue] {
        return Dictionary<OutKey, OutValue>(pairs: map(transform))
    }
    
    internal func mapValues<OutValue>(transform: (Value) -> OutValue) -> [Key: OutValue] {
        return Dictionary<Key, OutValue>(pairs: map{($0, transform($1))} )
    }
}
