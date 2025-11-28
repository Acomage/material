import Material.Utils.ColorUtils

open ColorUtils

def CONTRAST_RATIO_EPSILON := 0.04

def LUMINANCE_GAMUT_MAP_TOLERANCE := 0.4

namespace Contrast

def RATIO_MIN := 1.0

def RATIO_MAX := 21.0

def RATIO_30 := 3.0

def RATIO_45 := 4.5

def RATIO_70 := 7.0

def ratioOfYs (y1 y2 : Float) : Float :=
  let lighter := max y1 y2
  let darker := min y1 y2
  (lighter + 5.0) / (darker + 5.0)

def rationOfTones (t1 t2 : Float) : Float :=
  ratioOfYs (yFromLstar t1) (yFromLstar t2)

def lighter (tone ratio : Float) : Option Float :=
  if tone < 0.0 || tone > 100.0
    then none
  else
    let darkY := yFromLstar tone
    let lightY := ratio * (darkY + 5.0) - 5.0
    if lightY < 0.0 || lightY > 100.0
      then none
    else
      let realContrast := ratioOfYs lightY darkY
      let delta := (realContrast - ratio).abs
      if realContrast < ratio && delta > CONTRAST_RATIO_EPSILON
        then none
      else
        let returnValue := (lstarFromY lightY) + LUMINANCE_GAMUT_MAP_TOLERANCE
        if returnValue < 0.0 || returnValue > 100.0
          then none
        else some returnValue

def lighterUnsafe (tone ratio : Float) : Float :=
  (lighter tone ratio).getD 100.0

def darker (tone ratio : Float) : Option Float :=
  if tone < 0.0 || tone > 100.0
    sorry
  else
    sorry

end Contrast
