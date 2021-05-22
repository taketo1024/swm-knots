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
    public static func loadResource(_ name: String) throws {
        #if os(macOS)
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "cannot load: \(name).json", code: 0)
        }
        
        let data = try Data(contentsOf: url)
        let table = try JSONDecoder().decode(CodeTable.self, from: data)
        _table.merge(table, overwrite: true)
        #else
        throw NSError(domain: "cannot load: \(name).json", code: 0)
        #endif
    }

    public static func load(_ name: String) throws -> Link {
        if let code = _table[name] {
            return Link(name: name, pdCode: code)
        } else {
            throw NSError(domain: "cannot load: \(name)", code: 0)
        }
    }
    
    public static func unloadResources() {
        _table = [:]
    }
}

private typealias CodeTable = [String: Link.PDCode]
private var _table: CodeTable = [:]
