import Foundation

extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
    
    func mapPairs<OutKey, OutValue>(transform: (Key, Value) -> (OutKey, OutValue)) -> [OutKey: OutValue] {
        return Dictionary<OutKey, OutValue>(map(transform))
    }
    
    func mapValues<OutValue>(transform: (Value) -> OutValue) -> [Key: OutValue] {
        return Dictionary<Key, OutValue>( map{($0, transform($1))} )
    }
    
    static func generateBy<S: Sequence>(keys: S, generator: (Key) -> Value) -> Dictionary<Key, Value> where S.Iterator.Element == Key {
        return Dictionary(keys.map{($0, generator($0))})
    }
}
