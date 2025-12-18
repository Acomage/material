module
public import Material.Utils.MathUtils
public import Material.Hct.Hct
public import Material.DynamicColor.Types
public import Material.DynamicColor.MaterialDynamicColor
public import Material.DynamicColor.DynamicColor
public import Material.Utils.StringUtils

public section

open MathUtils

namespace DynamicScheme

def getRotatedHue (sourceColor : Hct) (hues : Vector Float 9) (rotations : Vector Float 9) : Float := Id.run do
  let sourceHue := sourceColor.hue
  if h : rotations.size = 1 then
    return sanitizeDegreesDouble (sourceHue + rotations[0])
  else
    for i in Vector.finRange 8 do
      let thisHue := hues[i]
      have h : (Fin.natAdd 1 i) < hues.size := by
        simp[Fin.natAdd]
        grind
      let nextHue := hues[i.natAdd 1]
      if (thisHue <= sourceHue) && (sourceHue < nextHue) then
        return sanitizeDegreesDouble (sourceHue + rotations[i])
  return sourceHue

def showAllColors (s : DynamicScheme) : String :=
  let colors := allMaterialDynamicColors
  let colorStrs := colors.map (fun dc =>
    let argb := getArgb dc s
    s!"{dc.name}: Tone {StringUtils.hexFromArgb argb}"
  )
  String.intercalate "\n" colorStrs

end DynamicScheme
