//
//  PlanarCode.swift
//  Sample
//
//  Created by Taketo Sano on 2018/12/06.
//

// see:
// - Knot Table  http://katlas.org/wiki/The_Rolfsen_Knot_Table
// - Link Table  http://katlas.org/wiki/The_Thistlethwaite_Link_Table
// - Torus Knots http://katlas.org/wiki/36_Torus_Knots

import Foundation

extension Link {
    public static func load(_ name: String) -> Link? {
        if let code = _table[name] {
            return Link(name: name, planarCode: code)
        } else {
            return nil
        }
    }
    
    public static func loadTable(_ name: String) throws {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "cannot load: \(name).json", code: 0)
        }
        
        let data = try Data(contentsOf: url)
        let table = try JSONDecoder().decode(CodeTable.self, from: data)
        _table.merge(table)
    }

    public static func unloadTable() {
        _table = [:]
    }
}

private typealias CodeTable = [String: Link.PlanarCode]
private var _table: CodeTable = [:]
