import SwiftyMath
import SwiftyHomology
import SwiftyKnots

// see: Knot Table http://katlas.org/wiki/The_Rolfsen_Knot_Table
let PDCodes = [
    "3_1": [[1,4,2,5], [3,6,4,1], [5,2,6,3]],
    "4_1": [[4,2,5,1], [8,6,1,5], [6,3,7,4], [2,7,3,8]],
    "5_1": [[1,6,2,7], [3,8,4,9], [5,10,6,1], [7,2,8,3], [9,4,10,5]],
    "5_2": [[1,4,2,5], [3,8,4,9], [5,10,6,1], [9,6,10,7], [7,2,8,3]],
]

typealias R = 𝐐

let name = "3_1"
let K = Link(pdCode: PDCodes[name]!)
let Kh = KhovanovHomology<R>(K)

print("Kh(\(name); \(R.symbol))\n")
Kh.printTable()
