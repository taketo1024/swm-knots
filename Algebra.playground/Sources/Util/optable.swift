import Foundation

public func printOpTable<T>(symbol: String, _ values: [T], op: (T, T) -> T) {
    let n = values.count
    
    let head = (0 ..< n).reduce("\(symbol)\t|") { (res, i) in
        "\(res)\t\(values[i])"
    }
    let line = String(count: 4*(n+1)+2, repeatedValue: Character("-"))
    let body = (0 ..< n).map { i in
        return (0 ..< n).reduce("\(values[i])\t|") { (res, j) in
            "\(res)\t\(op(values[i], values[j]))"
        }
    }
    let result = ([head, line] + body).joinWithSeparator("\n")
    print(result)
}

public func printAddOpTable<G: AdditiveGroup>(values: [G]) {
    printOpTable("+", values) { $0 + $1 }
}

public func printMulOpTable<M: Monoid>(values: [M]) {
    printOpTable("*", values) { $0 * $1 }
}