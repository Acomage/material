import Material.Quantize.PointProvider
import Material.Utils.MathUtils
import Material.Utils.ColorUtils

open MathUtils ColorUtils

--TODO:delete PointProvider if not used elsewhere

/--
  I don't know if the PointProviderLab is the only
  instance of PointProvider. If it is, I will delete PointProvider.
  just use PointProviderLab directly.
-/
def PointProviderLab := PUnit

--instance : PointProvider PointProviderLab where
--  fromInt argb := labFromArgb argb
--  toInt point := argbFromLab point[0] point[1] point[2]
--  distance c1 c2 := (c1.zipWith (fun a b => (a - b) ^ 2) c2).sum

namespace PointProviderLab

def fromInt (argb : UInt32) : Vec3 :=
  labFromArgb argb

def toInt (point : Vec3) : UInt32 :=
  argbFromLab point[0] point[1] point[2]

def distance (c1 c2 : Vec3) : Float :=
  (c1.zipWith (fun a b => (a - b) ^ 2) c2).sum

instance : PointProvider PointProviderLab where
  fromInt := fromInt
  toInt := toInt
  distance := distance

end PointProviderLab
