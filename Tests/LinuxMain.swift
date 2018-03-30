import XCTest
@testable import SwiftyAlgebraTests
@testable import SwiftyTopologyTests

XCTMain([
    testCase(SwiftyAlgebraTests.allTests),
    testCase(SwiftyTopologyTests.allTests),
])
