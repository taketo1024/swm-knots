//
//  GridDiagram_Examples.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2019/07/17.
//

import Foundation

extension GridDiagram {
    public static func load(_ name: String) -> GridDiagram? {
        loadTable()
        if let code = _table[name] {
            return GridDiagram(arcPresentation: code)
        } else {
            return nil
        }
    }
}

private typealias CodeTable = [String: [Int]]

private func loadTable() {
    if _table.isEmpty {
        _table = CodeTable.loadJSON(_jsonString)!
    }
}

private var _table: CodeTable = [:]
private let _jsonString = """
{
"0_1": [1, 2, 2, 1],
"3_1": [5, 2, 1, 3, 2, 4, 3, 5, 4, 1],
"4_1": [3, 5, 6, 4, 5, 2, 1, 3, 2, 6, 4, 1],
"5_1": [7, 2, 1, 3, 2, 4, 3, 5, 4, 6, 5, 7, 6, 1],
"5_2": [7, 4, 3, 5, 4, 2, 1, 3, 2, 6, 5, 7, 6, 1],
"6_1": [8, 5, 4, 6, 5, 3, 2, 4, 3, 1, 7, 2, 6, 8, 1, 7],
"6_2": [8, 2, 1, 6, 7, 3, 2, 4, 6, 8, 3, 5, 4, 7, 5, 1],
"6_3": [3, 7, 2, 5, 4, 6, 5, 8, 7, 9, 8, 4, 1, 3, 9, 2, 6, 1],
"7_1": [9, 2, 1, 3, 2, 4, 3, 5, 4, 6, 5, 7, 6, 8, 7, 9, 8, 1],
"7_2": [9, 6, 5, 7, 6, 4, 3, 5, 4, 2, 1, 3, 2, 8, 7, 9, 8, 1],
"7_3": [4, 9, 3, 5, 6, 4, 5, 8, 2, 6, 9, 7, 1, 3, 8, 2, 7, 1],
"7_4": [3, 5, 6, 4, 5, 7, 2, 6, 8, 3, 7, 9, 1, 8, 9, 2, 4, 1],
"7_5": [9, 2, 1, 7, 6, 8, 7, 9, 8, 3, 2, 4, 3, 5, 4, 6, 5, 1],
"7_6": [10, 2, 1, 8, 6, 9, 8, 10, 7, 3, 2, 6, 4, 7, 3, 5, 9, 4, 5, 1],
"7_7": [9, 3, 2, 7, 8, 4, 3, 5, 7, 9, 4, 1, 6, 2, 5, 8, 1, 6],

}
"""
