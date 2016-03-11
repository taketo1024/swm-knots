import Foundation

public protocol TPPolynominal {
    typealias K: Field
    static var value: Polynominal<K> { get }
}