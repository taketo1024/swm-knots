import SwiftyMath
import SwiftyKnots

let K = Knot(3, 1)
let Kh = KhovanovHomology(K, 𝐙.self)

print(K.name)
Kh.printTable()
