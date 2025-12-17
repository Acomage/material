import Material.DynamicColor.Types
import Material.Palettes.TonalPalette
import Material.Utils.MathUtils
import Material.DynamicColor.MaterialDynamicColor
import Material.Utils.StringUtils

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

def sourceColorArgb (ds : DynamicScheme) : UInt32 := ds.sourceColorHct.toInt

open MaterialDynamicColors

def getPrimaryPaletteKeyColor (ds : DynamicScheme) : UInt32 :=
  primaryPaletteKeyColor.getArgb ds

def getSecondaryPaletteKeyColor (ds : DynamicScheme) : UInt32 :=
  secondaryPaletteKeyColor.getArgb ds

def getTertiaryPaletteKeyColor (ds : DynamicScheme) : UInt32 :=
  tertiaryPaletteKeyColor.getArgb ds

def getNeutralPaletteKeyColor (ds : DynamicScheme) : UInt32 :=
  neutralPaletteKeyColor.getArgb ds

def getNeutralVariantPaletteKeyColor (ds : DynamicScheme) : UInt32 :=
  neutralVariantPaletteKeyColor.getArgb ds

def getBackground (ds : DynamicScheme) : UInt32 :=
  background.getArgb ds

def getOnBackground (ds : DynamicScheme) : UInt32 :=
  onBackground.getArgb ds

def getSurface (ds : DynamicScheme) : UInt32 :=
  surface.getArgb ds

def getSurfaceDim (ds : DynamicScheme) : UInt32 :=
  surfaceDim.getArgb ds

def getSurfaceBright (ds : DynamicScheme) : UInt32 :=
  surfaceBright.getArgb ds

def getSurfaceContainerLowest (ds : DynamicScheme) : UInt32 :=
  surfaceContainerLowest.getArgb ds

def getSurfaceContainerLow (ds : DynamicScheme) : UInt32 :=
  surfaceContainerLow.getArgb ds

def getSurfaceContainer (ds : DynamicScheme) : UInt32 :=
  surfaceContainer.getArgb ds

def getSurfaceContainerHigh (ds : DynamicScheme) : UInt32 :=
  surfaceContainerHigh.getArgb ds

def getSurfaceContainerHighest (ds : DynamicScheme) : UInt32 :=
  surfaceContainerHighest.getArgb ds

def getOnSurface (ds : DynamicScheme) : UInt32 :=
  onSurface.getArgb ds

def getSurfaceVariant (ds : DynamicScheme) : UInt32 :=
  surfaceVariant.getArgb ds

def getOnSurfaceVariant (ds : DynamicScheme) : UInt32 :=
  onSurfaceVariant.getArgb ds

def getInverseSurface (ds : DynamicScheme) : UInt32 :=
  inverseSurface.getArgb ds

def getInverseOnSurface (ds : DynamicScheme) : UInt32 :=
  inverseOnSurface.getArgb ds

def getOutline (ds : DynamicScheme) : UInt32 :=
  outline.getArgb ds

def getOutlineVariant (ds : DynamicScheme) : UInt32 :=
  outlineVariant.getArgb ds

def getShadow (ds : DynamicScheme) : UInt32 :=
  shadow.getArgb ds

def getScrim (ds : DynamicScheme) : UInt32 :=
  scrim.getArgb ds

def getSurfaceTint (ds : DynamicScheme) : UInt32 :=
  surfaceTint.getArgb ds

def getPrimary (ds : DynamicScheme) : UInt32 :=
  primary.getArgb ds

def getOnPrimary (ds : DynamicScheme) : UInt32 :=
  onPrimary.getArgb ds

def getPrimaryContainer (ds : DynamicScheme) : UInt32 :=
  primaryContainer.getArgb ds

def getOnPrimaryContainer (ds : DynamicScheme) : UInt32 :=
  onPrimaryContainer.getArgb ds

def getInversePrimary (ds : DynamicScheme) : UInt32 :=
  inversePrimary.getArgb ds

def getSecondary (ds : DynamicScheme) : UInt32 :=
  secondary.getArgb ds

def getOnSecondary (ds : DynamicScheme) : UInt32 :=
  onSecondary.getArgb ds

def getSecondaryContainer (ds : DynamicScheme) : UInt32 :=
  secondaryContainer.getArgb ds

def getOnSecondaryContainer (ds : DynamicScheme) : UInt32 :=
  onSecondaryContainer.getArgb ds

def getTertiary (ds : DynamicScheme) : UInt32 :=
  tertiary.getArgb ds

def getOnTertiary (ds : DynamicScheme) : UInt32 :=
  onTertiary.getArgb ds

def getTertiaryContainer (ds : DynamicScheme) : UInt32 :=
  tertiaryContainer.getArgb ds

def getOnTertiaryContainer (ds : DynamicScheme) : UInt32 :=
  onTertiaryContainer.getArgb ds

def getError (ds : DynamicScheme) : UInt32 :=
  error.getArgb ds

def getOnError (ds : DynamicScheme) : UInt32 :=
  onError.getArgb ds

def getErrorContainer (ds : DynamicScheme) : UInt32 :=
  errorContainer.getArgb ds

def getOnErrorContainer (ds : DynamicScheme) : UInt32 :=
  onErrorContainer.getArgb ds

def getPrimaryFixed (ds : DynamicScheme) : UInt32 :=
  primaryFixed.getArgb ds

def getPrimaryFixedDim (ds : DynamicScheme) : UInt32 :=
  primaryFixedDim.getArgb ds

def getOnPrimaryFixed (ds : DynamicScheme) : UInt32 :=
  onPrimaryFixed.getArgb ds

def getOnPrimaryFixedVariant (ds : DynamicScheme) : UInt32 :=
  onPrimaryFixedVariant.getArgb ds

def getSecondaryFixed (ds : DynamicScheme) : UInt32 :=
  secondaryFixed.getArgb ds

def getSecondaryFixedDim (ds : DynamicScheme) : UInt32 :=
  secondaryFixedDim.getArgb ds

def getOnSecondaryFixed (ds : DynamicScheme) : UInt32 :=
  onSecondaryFixed.getArgb ds

def getOnSecondaryFixedVariant (ds : DynamicScheme) : UInt32 :=
  onSecondaryFixedVariant.getArgb ds

def getTertiaryFixed (ds : DynamicScheme) : UInt32 :=
  tertiaryFixed.getArgb ds

def getTertiaryFixedDim (ds : DynamicScheme) : UInt32 :=
  tertiaryFixedDim.getArgb ds

def getOnTertiaryFixed (ds : DynamicScheme) : UInt32 :=
  onTertiaryFixed.getArgb ds

def getOnTertiaryFixedVariant (ds : DynamicScheme) : UInt32 :=
  onTertiaryFixedVariant.getArgb ds

def showAllColors (ds : DynamicScheme) : String :=
  let entries := [
("getPrimaryPaletteKeyColor",
  primaryPaletteKeyColor.getArgb ds),
("getSecondaryPaletteKeyColor",
  secondaryPaletteKeyColor.getArgb ds),
("getTertiaryPaletteKeyColor",
  tertiaryPaletteKeyColor.getArgb ds),
("getNeutralPaletteKeyColor",
  neutralPaletteKeyColor.getArgb ds),
("getNeutralVariantPaletteKeyColor",
  neutralVariantPaletteKeyColor.getArgb ds),
("getBackground",
  background.getArgb ds),
("getOnBackground",
  onBackground.getArgb ds),
("getSurface",
  surface.getArgb ds),
("getSurfaceDim",
  surfaceDim.getArgb ds),
("getSurfaceBright",
  surfaceBright.getArgb ds),
("getSurfaceContainerLowest",
  surfaceContainerLowest.getArgb ds),
("getSurfaceContainerLow",
  surfaceContainerLow.getArgb ds),
("getSurfaceContainer",
  surfaceContainer.getArgb ds),
("getSurfaceContainerHigh",
  surfaceContainerHigh.getArgb ds),
("getSurfaceContainerHighest",
  surfaceContainerHighest.getArgb ds),
("getOnSurface",
  onSurface.getArgb ds),
("getSurfaceVariant",
  surfaceVariant.getArgb ds),
("getOnSurfaceVariant",
  onSurfaceVariant.getArgb ds),
("getInverseSurface",
  inverseSurface.getArgb ds),
("getInverseOnSurface",
  inverseOnSurface.getArgb ds),
("getOutline",
  outline.getArgb ds),
("getOutlineVariant",
  outlineVariant.getArgb ds),
("getShadow",
  shadow.getArgb ds),
("getScrim",
  scrim.getArgb ds),
("getSurfaceTint",
  surfaceTint.getArgb ds),
("getPrimary",
  primary.getArgb ds),
("getOnPrimary",
  onPrimary.getArgb ds),
("getPrimaryContainer",
  primaryContainer.getArgb ds),
("getOnPrimaryContainer",
  onPrimaryContainer.getArgb ds),
("getInversePrimary",
  inversePrimary.getArgb ds),
("getSecondary",
  secondary.getArgb ds),
("getOnSecondary",
  onSecondary.getArgb ds),
("getSecondaryContainer",
  secondaryContainer.getArgb ds),
("getOnSecondaryContainer",
  onSecondaryContainer.getArgb ds),
("getTertiary",
  tertiary.getArgb ds),
("getOnTertiary",
  onTertiary.getArgb ds),
("getTertiaryContainer",
  tertiaryContainer.getArgb ds),
("getOnTertiaryContainer",
  onTertiaryContainer.getArgb ds),
("getError",
  error.getArgb ds),
("getOnError",
  onError.getArgb ds),
("getErrorContainer",
  errorContainer.getArgb ds),
("getOnErrorContainer",
  onErrorContainer.getArgb ds),
("getPrimaryFixed",
  primaryFixed.getArgb ds),
("getPrimaryFixedDim",
  primaryFixedDim.getArgb ds),
("getOnPrimaryFixed",
  onPrimaryFixed.getArgb ds),
("getOnPrimaryFixedVariant",
  onPrimaryFixedVariant.getArgb ds),
("getSecondaryFixed",
  secondaryFixed.getArgb ds),
("getSecondaryFixedDim",
  secondaryFixedDim.getArgb ds),
("getOnSecondaryFixed",
  onSecondaryFixed.getArgb ds),
("getOnSecondaryFixedVariant",
  onSecondaryFixedVariant.getArgb ds),
("getTertiaryFixed",
  tertiaryFixed.getArgb ds),
("getTertiaryFixedDim",
  tertiaryFixedDim.getArgb ds),
("getOnTertiaryFixed",
  onTertiaryFixed.getArgb ds),
("getOnTertiaryFixedVariant",
  onTertiaryFixedVariant.getArgb ds)]
  let res := entries.map (fun (name, color) =>
    s!"{name}: {StringUtils.hexFromArgb color}"
  )
  let header := s!"DynamicScheme Colors:"
  header ++ "\n" ++ String.intercalate "\n" res

end DynamicScheme
