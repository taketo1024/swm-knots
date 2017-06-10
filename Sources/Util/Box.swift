//
//  Box.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/14.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public final class Box<Content> {
    public var content: Content?
    public init(_ content: Content?) {
        self.content = content
    }
}
