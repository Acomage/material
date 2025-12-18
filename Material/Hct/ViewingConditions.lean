module
public import Material.Utils.ColorUtils
public import Material.Utils.MathUtils


public structure ViewingConditions where
  n : Float
  aw : Float
  nbb : Float
  ncb : Float
  c : Float
  nc : Float
  rgbD : MathUtils.Vec3
  fl : Float
  flRoot : Float
  z : Float

namespace ViewingConditions

open MathUtils ColorUtils

public def DEFAULT : ViewingConditions :=
  ⟨
    0.18418651851244414,
    29.98099719444734,
    1.0169191804458757,
    1.0169191804458757,
    0.69,
    1,
    #v[1.02117770275752, 0.9863077294280124, 0.9339605082802299],
    0.3884814537800353,
    0.7894826179304937,
    1.909169568483652
  ⟩

end ViewingConditions
