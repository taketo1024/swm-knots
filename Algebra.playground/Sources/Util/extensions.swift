import Foundation

internal extension Dictionary {
    func mapValues<OutValue>(transform: (Value) -> OutValue) -> [Key: OutValue] {
        return Dictionary<Key, OutValue>.generateBy(keys: self.keys, generator: {transform(self[$0]!)} )
    }
    
    static func generateBy<S: Sequence>(keys: S, generator: (Key) -> Value) -> Dictionary<Key, Value> where S.Iterator.Element == Key {
        var dic: Dictionary<Key, Value> = [:]
        for key in keys {
            dic[key] = generator(key)
        }
        return dic
    }
}
