import Foundation

public protocol AdditiveGroup: SetType {
    static var zero: Self { get }
    static func + (a: Self, b: Self) -> Self
    prefix static func - (x: Self) -> Self
    static func -(a: Self, b: Self) -> Self
}

public extension AdditiveGroup {
    public static func -(a: Self, b: Self) -> Self {
        return (a + (-b))
    }
}

public protocol AdditiveSubgroup: AdditiveGroup, SubsetType where Super: AdditiveGroup {}

public extension AdditiveSubgroup {
    public static var zero: Self {
        return Self(Super.zero)
    }
    
    public static func + (a: Self, b: Self) -> Self {
        return Self(a.asSuper + b.asSuper)
    }
    
    prefix static func - (a: Self) -> Self {
        return Self(-a.asSuper)
    }
}

public typealias AdditiveProductGroup<X: AdditiveGroup, Y: AdditiveGroup> = ProductSet<X, Y>

extension AdditiveProductGroup: AdditiveGroup where Left: AdditiveGroup, Right: AdditiveGroup {
    public static var zero: AdditiveProductGroup<Left, Right> {
        return AdditiveProductGroup(.zero, .zero)
    }
    
    public static func + (a: AdditiveProductGroup<Left, Right>, b: AdditiveProductGroup<Left, Right>) -> AdditiveProductGroup<Left, Right> {
        return AdditiveProductGroup(a.left + b.left, a.right + b.right)
    }
    
    public static prefix func - (a: AdditiveProductGroup<Left, Right>) -> AdditiveProductGroup<Left, Right> {
        return AdditiveProductGroup(-a.left, -a.right)
    }
}

public struct AdditiveQuotientGroup<Base, Sub: AdditiveSubgroup>: AdditiveGroup, QuotientSetType where Base == Sub.Super {
    private let x: Base
    public init(_ x: Base) {
        self.x = x
    }
    
    public var representative: Base {
        return x
    }
    
    public static func isEquivalent(_ a: Base, _ b: Base) -> Bool {
        return Sub.contains( a - b )
    }
    
    public static var zero: AdditiveQuotientGroup<Base, Sub> {
        return AdditiveQuotientGroup(Base.zero)
    }
    
    public static func + (a: AdditiveQuotientGroup<Base, Sub>, b: AdditiveQuotientGroup<Base, Sub>) -> AdditiveQuotientGroup<Base, Sub> {
        return AdditiveQuotientGroup(a.x + b.x)
    }
    
    public static prefix func - (a: AdditiveQuotientGroup<Base, Sub>) -> AdditiveQuotientGroup<Base, Sub> {
        return AdditiveQuotientGroup(-a.x)
    }
    
    public static var symbol: String {
        return "\(Base.symbol)/\(Sub.symbol)"
    }
}

public protocol AdditiveGroupHomType: MapType, AdditiveGroup where Domain: AdditiveGroup, Codomain: AdditiveGroup {}

public extension AdditiveGroupHomType {
    public static var zero: Self {
        return Self { _ in .zero }
    }
    
    public static func + (f: Self, g: Self) -> Self {
        return Self { x in f.applied(to: x) + g.applied(to: x) }
    }
    
    public prefix static func - (f: Self) -> Self {
        return Self { x in -f.applied(to: x) }
    }
}

public typealias AdditiveGroupHom<X: AdditiveGroup, Y: AdditiveGroup> = Map<X, Y>
extension AdditiveGroupHom: AdditiveGroup, AdditiveGroupHomType where Domain: AdditiveGroup, Codomain: AdditiveGroup {}
