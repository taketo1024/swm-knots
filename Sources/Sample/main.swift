import SwiftyMath
import SwiftyKnots
import SwiftyHomology

let K = Knot(3, 1)
let Kh = KhovanovHomology<𝐙>(K)

print(K.name)
Kh.printTable()
