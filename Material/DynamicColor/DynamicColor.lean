import Material.DynamicColor.Types
import Material.Contrast.Contrast
import Material.DynamicColor.ContrastCurve
import Material.Utils.MathUtils
-- some helpers

open Contrast MathUtils

def isFidelity (scheme : DynamicScheme) : Bool :=
  match scheme.variant with
  | .fidelity | .content => True
  | _ => false

def isMonoChrome (scheme : DynamicScheme) : Bool :=
  match scheme.variant with
  | .monoChrome => True
  | _ => false

def tonePrefersLightForeground (tone : Float) : Bool :=
  tone < 60.5

def foregroundTone (bgTone ratio : Float) : Float :=
  let lighterTone := Contrast.lighterUnsafe bgTone ratio
  let darkerTone := Contrast.darkerUnsafe bgTone ratio
  let lighterRatio := Contrast.rationOfTones lighterTone bgTone
  let darkerRatio := Contrast.rationOfTones darkerTone bgTone
  let preferLighter := tonePrefersLightForeground bgTone
  if preferLighter then
    let negligibleDifference := (lighterRatio - darkerRatio).abs < 0.1 && lighterRatio < ratio && darkerRatio < ratio
    if lighterRatio >= ratio || lighterRatio >= darkerRatio || negligibleDifference then lighterTone else darkerTone
  else
    if darkerRatio >= ratio || darkerRatio >= lighterRatio then darkerTone else lighterTone

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

-- combinator.

/--
  tone_delta_pair == .none
  background == .none
-/
def constantTone (tone : Float) : ToneFn :=
  fun _ => tone

/--
  tone_delta_pair == .none
  background == .none
-/
def fromPalette (fn : DynamicScheme → TonalPalette) : ToneFn :=
  fun ds => (fn ds).keyColor.tone

/--
  tone_delta_pair == .none
  background == .none
-/
def fromCurve (curve : ContrastCurve) : ToneFn :=
  fun ds => curve.get ds.contrastLevel

/--
  tone_delta_pair == .none
  background == .none
-/
def darkLight (dark light : ToneFn) : ToneFn :=
  fun ds => if ds.isDark then dark ds else light ds

/--
  tone_delta_pair == .none
  background == .none
-/
def darkLightConst (dark light : Float) : ToneFn :=
  fun ds => if ds.isDark then dark else light

def fidelity (yes no : ToneFn) : ToneFn :=
  fun ds => if isFidelity ds then yes ds else no ds

def monoChrome (yes no : ToneFn) : ToneFn :=
  fun ds => if isMonoChrome ds then yes ds else no ds

def monoChromeConst (yes no : Float) : ToneFn :=
  fun ds => if isMonoChrome ds then yes else no

/--
  tone_delta_pair == .none
  background == .some bg
  isBackground == false
  second_background == .none
-/
def withContrast
  (bg : ToneFn)
  (curve : ContrastCurve)
  : ToneFn → ToneFn :=
  fun toneFn =>
    fun s => Id.run do
      let bgTone := bg s
      let desired := curve.get s.contrastLevel
      let mut t := toneFn s
      if rationOfTones bgTone t < desired then
        t := foregroundTone bgTone desired
      if s.contrastLevel < 0 then
        t := foregroundTone bgTone desired
      return t
/--
  tone_delta_pair == .none
  background == .some bg1
  second_background == .some bg2
  isBackground == false
-/
def withTwoBackgrounds
  (bg1 bg2 : ToneFn)
  (curve : ContrastCurve)
  : ToneFn → ToneFn :=
  fun toneFn =>
    fun s => Id.run do
      let bgTone1 := bg1 s
      let bgTone2 := bg2 s
      let upper := max bgTone1 bgTone2
      let lower := min bgTone1 bgTone2
      let desired := curve.get s.contrastLevel
      let mut t := toneFn s
      if rationOfTones upper t >= desired && rationOfTones lower t >= desired then
        if s.contrastLevel < 0 then
          t := foregroundTone bgTone1 desired
        return t
      else
        let lightOption := Contrast.lighter upper desired
        let darkOption := Contrast.darker lower desired
        let preferLighter := tonePrefersLightForeground bgTone1 || tonePrefersLightForeground bgTone2
        if preferLighter then
          return lightOption.getD 100.0
        else
          return darkOption.getD (lightOption.getD 0.0)

/--
  tone_delta_pair == .some roleA roleB delta polarity stay_together
-/
def toneFnPair
  (roleA roleB : ToneFn)
  (delta : Float)
  (polarity : TonePolarity)
  (stay_together : Bool)
  (s : DynamicScheme) : Float × Float := Id.run do
  let aIsNearer :=
    match polarity with
    | .nearer   => true
    | .farther  => false
    | .lighter  => not s.isDark
    | .darker   => s.isDark
  let nearer := if aIsNearer then roleA else roleB
  let farther := if aIsNearer then roleB else roleA
  let expansionDir := if s.isDark then 1.0 else -1.0
  let mut n_tone := nearer s
  let mut f_tone := farther s
  if (f_tone - n_tone) * expansionDir < delta then
    f_tone := clampDouble (n_tone + delta * expansionDir) 0 100
    if (f_tone - n_tone) * expansionDir < delta then
      n_tone := clampDouble (f_tone - delta * expansionDir) 0 100
  if 50 <= n_tone && n_tone < 60 then
    if expansionDir > 0 then
      n_tone := 60
      f_tone := max f_tone  (n_tone + delta * expansionDir)
    else
      n_tone := 49
      f_tone := min f_tone (n_tone + delta * expansionDir)
  else if 50 <= f_tone && f_tone < 60 then
    if stay_together then
      if expansionDir > 0 then
        n_tone := 60
        f_tone := max f_tone (n_tone + delta * expansionDir)
      else
        n_tone := 49
        f_tone := min f_tone (n_tone + delta * expansionDir)
    else
      if expansionDir > 0 then
        f_tone := 60
      else
        f_tone := 49
  return (if aIsNearer then n_tone else f_tone, if aIsNearer then f_tone else n_tone)

def pairConbinator
  (delta : Float)
  (polarity : TonePolarity)
  (stayTogether : Bool)
  : (ToneFn × ToneFn) → ToneFn × ToneFn :=
  fun (roleA, roleB) =>
    (fun s => (toneFnPair roleA roleB delta polarity stayTogether s).1,
     fun s => (toneFnPair roleA roleB delta polarity stayTogether s).2)

def getPalette (palette : Palette) : DynamicScheme → TonalPalette :=
  fun ds =>
    match palette with
    | .primary          => ds.primaryPalette
    | .secondary        => ds.secondaryPalette
    | .tertiary         => ds.tertiaryPalette
    | .neutral          => ds.neutralPalette
    | .neutralVariant   => ds.neutralVariantPalette
    | .error            => ds.errorPalette

def getArgb (dc : DynamicColor) (scheme : DynamicScheme) : UInt32 :=
  (getPalette dc.palette scheme).getArgb (dc.toneFn scheme)
