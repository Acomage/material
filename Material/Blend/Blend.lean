module
public import Material.Hct.Cam16
public import Material.Hct.Hct
public import Material.Utils.ColorUtils
public import Material.Utils.MathUtils

public section

open MathUtils ColorUtils

namespace Blend

def harmonize (designColor sourceColor : UInt32) : UInt32 :=
  let fromHct := Hct.fromInt designColor
  let toHct := Hct.fromInt sourceColor
  let differenceDegrees := differenceDegrees fromHct.hue toHct.hue
  let rotationDegrees := min (differenceDegrees * 0.5) 15.0
  let outputHue := sanitizeDegreesDouble (fromHct.hue + rotationDegrees * (rotationDirection fromHct.hue toHct.hue))
  (Hct.fromHct outputHue fromHct.chroma fromHct.tone).toInt

def cam16Ucs (fromArgb toArgb : UInt32) (amount : Float) : UInt32 :=
  let fromCam := Cam16jab.fromInt fromArgb
  let toCam := Cam16jab.fromInt toArgb
  let jstar := lerp fromCam.jstar toCam.jstar amount
  let astar := lerp fromCam.astar toCam.astar amount
  let bstar := lerp fromCam.bstar toCam.bstar amount
  (Cam16.fromUcs jstar astar bstar).toInt

def hctHue (fromArgb toArgb : UInt32) (amount : Float) : UInt32 :=
  let ucs := cam16Ucs fromArgb toArgb amount
  let ucsCam := Cam16.fromInt ucs
  let fromCam := Cam16.fromInt fromArgb
  let blended := Hct.fromHct ucsCam.hue fromCam.chroma (lstarFromArgb fromArgb)
  blended.toInt

end Blend
