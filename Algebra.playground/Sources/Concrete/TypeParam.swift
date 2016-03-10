import Foundation

public protocol TPInt {
    static var value: Int { get }
}

public class TPInt_0 : TPInt {
    public static let value = 0
}

public class TPInt_Succ<n: TPInt> : TPInt {
    public static var value: Int {
        return n.value + 1
    }
}

public typealias TPInt_1 = TPInt_Succ<TPInt_0>
public typealias TPInt_2 = TPInt_Succ<TPInt_1>
public typealias TPInt_3 = TPInt_Succ<TPInt_2>
public typealias TPInt_4 = TPInt_Succ<TPInt_3>