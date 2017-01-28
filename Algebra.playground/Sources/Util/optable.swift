import Foundation

public func printOpTable<T1, T2>(_ symbol: String, rows: [T1], cols: [T2], op: (T1, T2) -> T1) {
    let head = (0 ..< cols.count).reduce("\(symbol)\t|") { (res, j) in
        "\(res)\t\(cols[j])"
    }
    let line = String(repeating: "-", count: 4 * (cols.count + 1) + 2)
    let body = (0 ..< rows.count).map { i in
        return (0 ..< cols.count).reduce("\(rows[i])\t|") { (res, j) in
            "\(res)\t\(op(rows[i], cols[j]))"
        }
    }
    let result = ([head, line] + body).joined(separator: "\n")
    print(result)
}

public func printAddOpTable<G: AdditiveGroup>(values: [G]) {
    printOpTable("+", rows: values, cols: values) { $0 + $1 }
}

public func printMulOpTable<M: Monoid>(values: [M]) {
    printOpTable("*", rows: values, cols: values) { $0 * $1 }
}

public func printPowOpTable<M: Monoid>(values: [M], _ n: Int) {
    printOpTable("^", rows: values, cols: Array(0 ... n)) { $0 ** $1 }
}
