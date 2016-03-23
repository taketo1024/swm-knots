import Foundation

public protocol TPInt {
    static var value: Int { get }
}

public struct TPInt_0 : TPInt {
    public static let value = 0
}

public struct TPInt_Succ<n: TPInt> : TPInt {
    public static var value: Int {
        return n.value + 1
    }
}

public typealias TPInt_1 =  TPInt_Succ<TPInt_0>
public typealias TPInt_2 =  TPInt_Succ<TPInt_1>
public typealias TPInt_3 =  TPInt_Succ<TPInt_2>
public typealias TPInt_4 =  TPInt_Succ<TPInt_3>
public typealias TPInt_5 =  TPInt_Succ<TPInt_4>
public typealias TPInt_6 =  TPInt_Succ<TPInt_5>
public typealias TPInt_7 =  TPInt_Succ<TPInt_6>
public typealias TPInt_8 =  TPInt_Succ<TPInt_7>
public typealias TPInt_9 =  TPInt_Succ<TPInt_8>
public typealias TPInt_10 = TPInt_Succ<TPInt_9>
