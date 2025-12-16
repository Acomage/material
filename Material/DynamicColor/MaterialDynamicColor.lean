import Material.DynamicColor.DynamicColor
import Material.DynamicColor.Types
import Material.Hct.Cam16
import Material.Hct.Hct
import Material.Dislike.DislikeAnalyzer

namespace MaterialDynamicColors

def isFidelity (scheme : DynamicScheme) : Bool :=
  match scheme.variant with
  | .fidelity | .content => True
  | _ => false

def isMonoChrome (scheme : DynamicScheme) : Bool :=
  match scheme.variant with
  | .monoChrome => True
  | _ => false

def findDesiredChromaByTone (hue chroma tone : Float) (by_decreasing_tone : Bool) : Float := Id.run do
  let mut answer := tone
  let mut closest_to_chroma := Hct.fromHct hue chroma tone
  if closest_to_chroma.chroma < chroma then
    let mut chroma_peak := closest_to_chroma.chroma
    while closest_to_chroma.chroma < chroma do
      answer := answer + (if by_decreasing_tone then -1.0 else 1.0)
      let potential_solution := Hct.fromHct hue chroma answer
      if chroma_peak > potential_solution.chroma then
        break
      if (potential_solution.chroma - chroma).abs < 0.4 then
        break
      let potential_delta := (potential_solution.chroma - chroma).abs
      let current_delta := (closest_to_chroma.chroma - chroma).abs
      if potential_delta < current_delta then
        closest_to_chroma := potential_solution
      chroma_peak := max chroma_peak potential_solution.chroma
  return answer

def contentAccentToneDelta := 15.0

open DynamicColor

def primaryPaletteKeyColor : DynamicColor :=
  fromPalette "primary_palette_key_color"
    (fun s => s.primaryPalette)
    (fun s => s.primaryPalette.keyColor.tone)

def secondaryPaletteKeyColor : DynamicColor :=
  fromPalette "secondary_palette_key_color"
    (fun s => s.secondaryPalette)
    (fun s => s.secondaryPalette.keyColor.tone)

def tertiaryPaletteKeyColor : DynamicColor :=
  fromPalette "tertiary_palette_key_color"
    (fun s => s.tertiaryPalette)
    (fun s => s.tertiaryPalette.keyColor.tone)

def neutralPaletteKeyColor : DynamicColor :=
  fromPalette "neutral_palette_key_color"
    (fun s => s.neutralPalette)
    (fun s => s.neutralPalette.keyColor.tone)

def neutralVariantPaletteKeyColor : DynamicColor :=
  fromPalette "neutral_variant_palette_key_color"
    (fun s => s.neutralVariantPalette)
    (fun s => s.neutralVariantPalette.keyColor.tone)

def background : DynamicColor :=
  ⟨
    "background",
    (fun s => s.neutralPalette),
    (fun s => if s.isDark then 6.0 else 98.0),
    true,
    .none,
    .none,
    .none,
    .none
  ⟩

def onBackground : DynamicColor :=
  ⟨
    "on_background",
    (fun s => s.neutralPalette),
    (fun s => if s.isDark then 90.0 else 10.0),
    false,
    some (fun _ => background),
    .none,
    .some ⟨3.0, 3.0, 4.5, 7.0⟩,
    .none
  ⟩

def surface : DynamicColor :=
  ⟨
    "surface",
    (fun s => s.neutralPalette),
    (fun s => if s.isDark then 6.0 else 98.0),
    true,
    .none,
    .none,
    .none,
    .none
  ⟩

def surfaceDim : DynamicColor :=
  ⟨
    "surface_dim",
    (fun s => s.neutralPalette),
    (fun s => if s.isDark then 6.0 else {low := 87.0, normal := 87.0, medium := 80.0, high := 75.0 : ContrastCurve}.get s.contrastLevel),
    true,
    .none,
    .none,
    .none,
    .none
  ⟩

def surfaceBright : DynamicColor :=
  ⟨
    "surface_bright",
    (fun s => s.neutralPalette),
    (fun s => if s.isDark then {low := 24.0, normal := 24.0, medium := 29.0, high := 34.0 : ContrastCurve}.get s.contrastLevel else 98.0),
    true,
    .none,
    .none,
    .none,
    .none
  ⟩

def surfaceContainerLowest : DynamicColor :=
  ⟨
    "surface_container_lowest",
    (fun s => s.neutralPalette),
    (fun s => if s.isDark then {low := 4.0, normal := 4.0, medium := 2.0, high := 0.0 : ContrastCurve}.get s.contrastLevel else 100.0),
    true,
    .none,
    .none,
    .none,
    .none
  ⟩

def surfaceContainerLow : DynamicColor :=
  ⟨
    "surface_container_low",
    (fun s => s.neutralPalette),
    (fun s => if s.isDark then {low := 10.0, normal := 10.0, medium := 11.0, high := 12.0 : ContrastCurve}.get s.contrastLevel else {low := 96.0, normal := 96.0, medium := 96.0, high := 95.0 : ContrastCurve}.get s.contrastLevel),
    true,
    .none,
    .none,
    .none,
    .none
  ⟩

def surfaceContainer : DynamicColor :=
  ⟨
    "surface_container",
    (fun s => s.neutralPalette),
    (fun s => if s.isDark then {low := 12.0, normal := 12.0, medium := 16.0, high := 20.0 : ContrastCurve}.get s.contrastLevel else {low := 94.0, normal := 94.0, medium := 92.0, high := 90.0 : ContrastCurve}.get s.contrastLevel),
    true,
    .none,
    .none,
    .none,
    .none
  ⟩

def surfaceContainerHigh : DynamicColor :=
  ⟨
    "surface_container_high",
    (fun s => s.neutralPalette),
    (fun s => if s.isDark then {low := 17.0, normal := 17.0, medium := 21.0, high := 25.0 : ContrastCurve}.get s.contrastLevel else {low := 92.0, normal := 92.0, medium := 88.0, high := 85.0 : ContrastCurve}.get s.contrastLevel),
    true,
    .none,
    .none,
    .none,
    .none
  ⟩

def surfaceContainerHighest : DynamicColor :=
  ⟨
    "surface_container_highest",
    (fun s => s.neutralPalette),
    (fun s => if s.isDark then {low := 22.0, normal := 22.0, medium := 26.0, high := 30.0 : ContrastCurve}.get s.contrastLevel else {low := 90.0, normal := 90.0, medium := 84.0, high := 80.0 : ContrastCurve}.get s.contrastLevel),
    true,
    .none,
    .none,
    .none,
    .none
  ⟩

def highestSurface (scheme : DynamicScheme) : DynamicColor :=
  if scheme.isDark then surfaceBright else surfaceDim

def onSurface : DynamicColor :=
  ⟨
    "on_surface",
    (fun s => s.neutralPalette),
    (fun s => if s.isDark then 90.0 else 10.0),
    false,
    .some (fun s => highestSurface s),
    .none,
    .some ⟨4.5, 7.0, 11.0, 21.0⟩,
    .none
  ⟩

def surfaceVariant : DynamicColor :=
  ⟨
    "surface_variant",
    (fun s => s.neutralVariantPalette),
    (fun s => if s.isDark then 30.0 else 90.0),
    true,
    .none,
    .none,
    .none,
    .none
  ⟩

def onSurfaceVariant : DynamicColor :=
  ⟨
    "on_surface_variant",
    (fun s => s.neutralVariantPalette),
    (fun s => if s.isDark then 80.0 else 30.0),
    false,
    .some (fun s => highestSurface s),
    .none,
    .some ⟨3.0, 4.5, 7.0, 11.0⟩,
    .none
  ⟩

def inverseSurface : DynamicColor :=
  ⟨
    "inverse_surface",
    (fun s => s.neutralPalette),
    (fun s => if s.isDark then 90.0 else 20.0),
    false,
    .none,
    .none,
    .none,
    .none
  ⟩

def inverseOnSurface : DynamicColor :=
  ⟨
    "inverse_on_surface",
    (fun s => s.neutralPalette),
    (fun s => if s.isDark then 20.0 else 95.0),
    false,
    .some (fun _ => inverseSurface),
    .none,
    .some ⟨4.5, 7.0, 11.0, 21.0⟩,
    .none
  ⟩

def outline : DynamicColor :=
  ⟨
    "outline",
    (fun s => s.neutralVariantPalette),
    (fun s => if s.isDark then 60.0 else 50.0),
    false,
    .some (fun s => highestSurface s),
    .none,
    .some ⟨1.5, 3.0, 4.5, 7.0⟩,
    .none
  ⟩

def outlineVariant : DynamicColor :=
  ⟨
    "outline_variant",
    (fun s => s.neutralVariantPalette),
    (fun s => if s.isDark then 30.0 else 80.0),
    false,
    .some (fun s => highestSurface s),
    .none,
    .some ⟨1.0, 1.0, 3.0, 4.5⟩,
    .none
  ⟩

def shadow : DynamicColor :=
  ⟨
    "shadow",
    (fun s => s.neutralPalette),
    (fun _ => 0.0),
    false,
    .none,
    .none,
    .none,
    .none
  ⟩

def scrim : DynamicColor :=
  ⟨
    "scrim",
    (fun s => s.neutralPalette),
    (fun _ => 0.0),
    false,
    .none,
    .none,
    .none,
    .none
  ⟩

def surfaceTint : DynamicColor :=
  ⟨
    "surface_tint",
    (fun s => s.primaryPalette),
    (fun s => if s.isDark then 80.0 else 40.0),
    true,
    .none,
    .none,
    .none,
    .none
  ⟩

-- I don't know if I implemented this way is correct
-- TODO: review this part
mutual
  partial def primaryFn : Unit → DynamicColor := fun _ =>
    (⟨
      "primary",
      (fun s => s.primaryPalette),
      (fun s => if isMonoChrome s then
        if s.isDark then 100.0 else 0.0
        else if s.isDark then 80.0 else 40.0),
      true,
      .some (fun s => highestSurface s),
      .none,
      .some ⟨3.0, 4.5, 7.0, 7.0⟩,
      .some (fun _ => ⟨primaryContainerFn (), primaryFn (), 10.0, TonePolarity.nearer, false⟩)
    ⟩)
 
  partial def primaryContainerFn : Unit → DynamicColor := fun _ =>
    (⟨
      "primary_container",
      (fun s => s.primaryPalette),
      (fun s => if isFidelity s then
        s.sourceColorHct.tone
        else if isMonoChrome s then
          if s.isDark then 85.0 else 25.0
        else if s.isDark then 30.0 else 90.0),
      true,
      .some (fun s => highestSurface s),
      .none,
      .some ⟨1.0, 1.0, 3.0, 4.5⟩,
      .some (fun _ => ⟨primaryContainerFn (), primaryFn (), 10.0, TonePolarity.nearer, false⟩)
    ⟩)
end

def primary : DynamicColor := primaryFn ()

def primaryContainer : DynamicColor := primaryContainerFn ()

def onPrimary : DynamicColor :=
  ⟨
    "on_primary",
    (fun s => s.primaryPalette),
    (fun s => if isMonoChrome s then
      if s.isDark then 10.0 else 90.0
      else if s.isDark then 20.0 else 100.0),
    false,
    .some (fun _ => primary),
    .none,
    .some ⟨4.5, 7.0, 11.0, 21.0⟩,
    .none
  ⟩

def onPrimaryContainer : DynamicColor :=
  ⟨
    "on_primary_container",
    (fun s => s.primaryPalette),
    (fun s => if isFidelity s then
      DynamicColor.foregroundTone (primaryContainer.tone s) 4.5
      else if isMonoChrome s then
        if s.isDark then 0.0 else 100.0
      else if s.isDark then 90.0 else 30.0),
    false,
    .some (fun _ => primaryContainer),
    .none,
    .some ⟨3.0, 4.5, 7.0, 11.0⟩,
    .none
  ⟩

def inversePrimary : DynamicColor :=
  ⟨
    "inverse_primary",
    (fun s => s.primaryPalette),
    (fun s => if s.isDark then 40.0 else 80.0),
    false,
    .some (fun _ => inverseSurface),
    .none,
    .some ⟨3.0, 4.5, 7.0, 7.0⟩,
    .none
  ⟩

-- TODO: review this part
mutual
partial def secondaryFn : Unit → DynamicColor := fun _ =>
  (⟨
    "secondary",
    (fun s => s.secondaryPalette),
    (fun s => if s.isDark then 80.0 else 40.0),
    true,
    (fun s => highestSurface s),
    .none,
    .some ⟨3.0, 4.5, 7.0, 7.0⟩,
    .some (fun _ => ⟨secondaryContainerFn (), secondaryFn (), 10.0, TonePolarity.nearer, false⟩)
  ⟩)

partial def secondaryContainerFn : Unit → DynamicColor := fun _ =>
  (⟨
    "secondary_container",
    (fun s => s.secondaryPalette),
    (fun s =>
      let initialTone := if s.isDark then 30.0 else 90.0
      if isMonoChrome s then
        if s.isDark then 30.0 else 85.0
      else
        if not (isFidelity s) then
          initialTone
        else
          findDesiredChromaByTone s.secondaryPalette.hue s.secondaryPalette.chroma initialTone (not s.isDark)),
    true,
    (fun s => highestSurface s),
    .none,
    .some ⟨1.0, 1.0, 3.0, 4.5⟩,
    .some (fun _ => ⟨secondaryContainerFn (), secondaryFn (), 10.0, TonePolarity.nearer, false⟩)
  ⟩)
end

def secondary : DynamicColor := secondaryFn ()

def secondaryContainer : DynamicColor := secondaryContainerFn ()

def onSecondary : DynamicColor :=
  ⟨
    "on_secondary",
    (fun s => s.secondaryPalette),
    (fun s => if isMonoChrome s then
      if s.isDark then 10.0 else 100.0
      else if s.isDark then 20.0 else 100.0),
    false,
    .some (fun _ => secondary),
    .none,
    .some ⟨4.5, 7.0, 11.0, 21.0⟩,
    .none
  ⟩

def onSecondaryContainer : DynamicColor :=
  ⟨
    "on_secondary_container",
    (fun s => s.secondaryPalette),
    (fun s => if isMonoChrome s then
      if s.isDark then 90.0 else 10.0
      else if not (isFidelity s) then
        if s.isDark then 90.0 else 30.0
      else DynamicColor.foregroundTone (secondaryContainer.tone s) 4.5),
    false,
    .some (fun _ => secondaryContainer),
    .none,
    .some ⟨3.0, 4.5, 7.0, 11.0⟩,
    .none
  ⟩

mutual
partial def tertiaryFn : Unit → DynamicColor := fun _ =>
  (⟨
    "tertiary",
    (fun s => s.tertiaryPalette),
    (fun s => if isMonoChrome s then
      if s.isDark then 90.0 else 25.0
      else if s.isDark then 80.0 else 40.0),
    true,
    (fun s => highestSurface s),
    .none,
    .some ⟨3.0, 4.5, 7.0, 7.0⟩,
    .some (fun _ => ⟨tertiaryContainerFn (), tertiaryFn (), 10.0, TonePolarity.nearer, false⟩)
  ⟩)

partial def tertiaryContainerFn : Unit → DynamicColor := fun _ =>
  (⟨
    "tertiary_container",
    (fun s => s.tertiaryPalette),
    (fun s => if isMonoChrome s then
      if s.isDark then 60.0 else 49.0
      else if not (isFidelity s) then
        if s.isDark then 30.0 else 90.0
      else
        let proposedHct := Hct.fromInt (s.tertiaryPalette.getArgb s.sourceColorHct.tone)
        (DislikeAnalyzer.fixIfDisliked proposedHct).tone),
    true,
    (fun s => highestSurface s),
    .none,
    .some ⟨1.0, 1.0, 3.0, 4.5⟩,
    .some (fun _ => ⟨tertiaryContainerFn (), tertiaryFn (), 10.0, TonePolarity.nearer, false⟩)
  ⟩)
end

def tertiary : DynamicColor := tertiaryFn ()

def tertiaryContainer : DynamicColor := tertiaryContainerFn ()

def onTertiary : DynamicColor :=
  ⟨
    "on_tertiary",
    (fun s => s.tertiaryPalette),
    (fun s => if isMonoChrome s then
      if s.isDark then 10.0 else 90.0
      else if s.isDark then 20.0 else 100.0),
    false,
    .some (fun _ => tertiary),
    .none,
    .some ⟨4.5, 7.0, 11.0, 21.0⟩,
    .none
  ⟩

def onTertiaryContainer : DynamicColor :=
  ⟨
    "on_tertiary_container",
    (fun s => s.tertiaryPalette),
    (fun s => if isMonoChrome s then
      if s.isDark then 0.0 else 100.0
      else if not (isFidelity s) then
        if s.isDark then 90.0 else 30.0
      else DynamicColor.foregroundTone (tertiaryContainer.tone s) 4.5),
    false,
    .some (fun _ => tertiaryContainer),
    .none,
    .some ⟨3.0, 4.5, 7.0, 11.0⟩,
    .none
  ⟩

mutual
partial def errorFn : Unit → DynamicColor := fun _ =>
  (⟨
    "error",
    (fun s => s.errorPalette),
    (fun s => if s.isDark then 80.0 else 40.0),
    true,
    .some (fun s => highestSurface s),
    .none,
    .some ⟨3.0, 4.5, 7.0, 7.0⟩,
    .some (fun _ => ⟨errorContainerFn (), errorFn (), 10.0, TonePolarity.nearer, false⟩)
  ⟩)

partial def errorContainerFn : Unit → DynamicColor := fun _ =>
  (⟨
    "error_container",
    (fun s => s.errorPalette),
    (fun s => if s.isDark then 30.0 else 90.0),
    true,
    .some (fun s => highestSurface s),
    .none,
    .some ⟨1.0, 1.0, 3.0, 4.5⟩,
    .some (fun _ => ⟨errorContainerFn (), errorFn (), 10.0, TonePolarity.nearer, false⟩)
  ⟩)
end

def error : DynamicColor := errorFn ()

def errorContainer : DynamicColor := errorContainerFn ()

def onError : DynamicColor :=
  ⟨
    "on_error",
    (fun s => s.errorPalette),
    (fun s => if s.isDark then 20.0 else 100.0),
    false,
    .some (fun _ => error),
    .none,
    .some ⟨4.5, 7.0, 11.0, 21.0⟩,
    .none
  ⟩

def onErrorContainer : DynamicColor :=
  ⟨
    "on_error_container",
    (fun s => s.errorPalette),
    (fun s => if isMonoChrome s then
      if s.isDark then 90.0 else 10.0
      else if s.isDark then 90.0 else 30.0),
    false,
    .some (fun _ => errorContainer),
    .none,
    .some ⟨3.0, 4.5, 7.0, 11.0⟩,
    .none
  ⟩

mutual
partial def primaryFixedFn : Unit → DynamicColor := fun _ =>
  (⟨
    "primary_fixed",
    (fun s => s.primaryPalette),
    (fun s => if isMonoChrome s then 40.0 else 90.0),
    true,
    .some (fun s => highestSurface s),
    .none,
    .some ⟨1.0, 1.0, 3.0, 4.5⟩,
    .some (fun _ => ⟨primaryFixedFn (), primaryFixedDimFn (), 10.0, TonePolarity.lighter, true⟩)
  ⟩)

partial def primaryFixedDimFn : Unit → DynamicColor := fun _ =>
  (⟨
    "primary_fixed_dim",
    (fun s => s.primaryPalette),
    (fun s => if isMonoChrome s then 30.0 else 80.0),
    true,
    .some (fun s => highestSurface s),
    .none,
    .some ⟨1.0, 1.0, 3.0, 4.5⟩,
    .some (fun _ => ⟨primaryFixedFn (), primaryFixedDimFn (), 10.0, TonePolarity.lighter, true⟩)
  ⟩)
end

def primaryFixed : DynamicColor := primaryFixedFn ()

def primaryFixedDim : DynamicColor := primaryFixedDimFn ()

def onPrimaryFixed : DynamicColor :=
  ⟨
    "on_primary_fixed",
    (fun s => s.primaryPalette),
    (fun s => if isMonoChrome s then 100.0 else 10.0),
    false,
    .some (fun _ => primaryFixedDim),
    .some (fun _ => primaryFixed),
    .some ⟨4.5, 7.0, 11.0, 21.0⟩,
    .none
  ⟩

def onPrimaryFixedVariant : DynamicColor :=
  ⟨
    "on_primary_fixed_variant",
    (fun s => s.primaryPalette),
    (fun s => if isMonoChrome s then 90.0 else 20.0),
    false,
    .some (fun _ => primaryFixedDim),
    .some (fun _ => primaryFixed),
    .some ⟨3.0, 4.5, 7.0, 11.0⟩,
    .none
  ⟩

mutual
partial def secondaryFixedFn : Unit → DynamicColor := fun _ =>
  (⟨
    "secondary_fixed",
    (fun s => s.secondaryPalette),
    (fun s => if isMonoChrome s then 80.0 else 90.0),
    true,
    .some (fun s => highestSurface s),
    .none,
    .some ⟨1.0, 1.0, 3.0, 4.5⟩,
    .some (fun _ => ⟨secondaryFixedFn (), secondaryFixedDimFn (), 10.0, TonePolarity.lighter, true⟩)
  ⟩)

partial def secondaryFixedDimFn : Unit → DynamicColor := fun _ =>
  (⟨
    "secondary_fixed_dim",
    (fun s => s.secondaryPalette),
    (fun s => if isMonoChrome s then 70.0 else 80.0),
    true,
    .some (fun s => highestSurface s),
    .none,
    .some ⟨1.0, 1.0, 3.0, 4.5⟩,
    .some (fun _ => ⟨secondaryFixedFn (), secondaryFixedDimFn (), 10.0, TonePolarity.lighter, true⟩)
  ⟩)
end

def secondaryFixed : DynamicColor := secondaryFixedFn ()

def secondaryFixedDim : DynamicColor := secondaryFixedDimFn ()

def onSecondaryFixed : DynamicColor :=
  ⟨
    "on_secondary_fixed",
    (fun s => s.secondaryPalette),
    (fun _ => 10.0),
    false,
    .some (fun _ => secondaryFixedDim),
    .some (fun _ => secondaryFixed),
    .some ⟨4.5, 7.0, 11.0, 21.0⟩,
    .none
  ⟩

def onSecondaryFixedVariant : DynamicColor :=
  ⟨
    "on_secondary_fixed_variant",
    (fun s => s.secondaryPalette),
    (fun s => if isMonoChrome s then 25.0 else 30.0),
    false,
    .some (fun _ => secondaryFixedDim),
    .some (fun _ => secondaryFixed),
    .some ⟨3.0, 4.5, 7.0, 11.0⟩,
    .none
  ⟩

mutual
partial def tertiaryFixedFn : Unit → DynamicColor := fun _ =>
  (⟨
    "tertiary_fixed",
    (fun s => s.tertiaryPalette),
    (fun s => if isMonoChrome s then 40.0 else 90.0),
    true,
    .some (fun s => highestSurface s),
    .none,
    .some ⟨1.0, 1.0, 3.0, 4.5⟩,
    .some (fun _ => ⟨tertiaryFixedFn (), tertiaryFixedDimFn (), 10.0, TonePolarity.lighter, true⟩)
  ⟩)
partial def tertiaryFixedDimFn : Unit → DynamicColor := fun _ =>
  (⟨
    "tertiary_fixed_dim",
    (fun s => s.tertiaryPalette),
    (fun s => if isMonoChrome s then 30.0 else 80.0),
    true,
    .some (fun s => highestSurface s),
    .none,
    .some ⟨1.0, 1.0, 3.0, 4.5⟩,
    .some (fun _ => ⟨tertiaryFixedFn (), tertiaryFixedDimFn (), 10.0, TonePolarity.lighter, true⟩)
  ⟩)
end

def tertiaryFixed : DynamicColor := tertiaryFixedFn ()

def tertiaryFixedDim : DynamicColor := tertiaryFixedDimFn ()

def onTertiaryFixed : DynamicColor :=
  ⟨
    "on_tertiary_fixed",
    (fun s => s.tertiaryPalette),
    (fun s => if isMonoChrome s then 100.0 else 10.0),
    false,
    .some (fun _ => tertiaryFixedDim),
    .some (fun _ => tertiaryFixed),
    .some ⟨4.5, 7.0, 11.0, 21.0⟩,
    .none
  ⟩

def onTertiaryFixedVariant : DynamicColor :=
  ⟨
    "on_tertiary_fixed_variant",
    (fun s => s.tertiaryPalette),
    (fun s => if isMonoChrome s then 90.0 else 20.0),
    false,
    .some (fun _ => tertiaryFixedDim),
    .some (fun _ => tertiaryFixed),
    .some ⟨3.0, 4.5, 7.0, 11.0⟩,
    .none
  ⟩

end MaterialDynamicColors

