import Material.Utils.MathUtils

open MathUtils

class PointProvider (α : Type u) where
  fromInt (argb : Int32) : Vec3
  toInt (point : Vec3) : Int32
  distance (c1 c2 : Vec3) : Float
