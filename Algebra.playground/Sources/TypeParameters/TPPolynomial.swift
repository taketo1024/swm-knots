import Foundation

public protocol _Polynomial {
    associatedtype K: Field
    static var value: Polynomial<K> { get }
}
