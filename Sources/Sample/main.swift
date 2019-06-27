import SwiftyMath
import SwiftyKnots

let K = Knot(3, 1)
let Kh = K.KhovanovHomology(𝐙.self)

print(K.name)
Debug.measure {
    Kh.printTable()
}
