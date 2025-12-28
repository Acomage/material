module
public import Material.Hct.HctSolver
public import Material.DynamicColor.Types
public import Material.Contrast.Contrast
public import Material.DynamicColor.ContrastCurve
public import Material.Utils.MathUtils

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

public def foregroundTone (bgTone ratio : Float) : Float :=
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

-- maybe can be speeded up with binary search?
-- maybe cache results?
-- or just precompute a table?
-- TODO: review this function for performance
public def findDesiredChromaByTone (hue chroma tone : Float) (by_decreasing_tone : Bool) : Float := Id.run do
  let maxChromaFn := HctSolver.maxChroma hue
  let epsilon := 0.4
  let mut answer := tone
  let mut closest_to_chroma := maxChromaFn tone
  let step := if by_decreasing_tone then -1.0 else 1.0
  if closest_to_chroma < chroma then
    let mut chroma_peak := closest_to_chroma
    while closest_to_chroma < chroma do
      answer := answer + step
      let potential_solution := maxChromaFn answer
      if chroma_peak > potential_solution then
        break
      if potential_solution > chroma - epsilon then
        break
      let potential_delta := (potential_solution - chroma).abs
      let current_delta := (closest_to_chroma - chroma).abs
      if potential_delta < current_delta then
        closest_to_chroma := potential_solution
      chroma_peak := max chroma_peak potential_solution
  return answer

-- combinator.

public def constantTone (tone : Float) : ToneFn :=
  fun _ => tone

public def fromPalette (fn : DynamicScheme → TonalPalette) : ToneFn :=
  fun ds => (fn ds).keyColor.tone

public def fromCurve (curve : ContrastCurve) : ToneFn :=
  fun ds => curve.get ds.contrastLevel

public def darkLight (dark light : ToneFn) : ToneFn :=
  fun ds => if ds.isDark then dark ds else light ds

public def darkLightConst (dark light : Float) : ToneFn :=
  fun ds => if ds.isDark then dark else light

public def fidelity (yes no : ToneFn) : ToneFn :=
  fun ds => if isFidelity ds then yes ds else no ds

public def monoChrome (yes no : ToneFn) : ToneFn :=
  fun ds => if isMonoChrome ds then yes ds else no ds

public def monoChromeConst (yes no : Float) : ToneFn :=
  fun ds => if isMonoChrome ds then yes else no

public def withContrast
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

public def pair
  (delta : Float)
  (polarity : TonePolarity)
  (stay_together : Bool)
  (roleA roleB : ToneFn)
  : ToneFnPair := fun s => Id.run do
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
    f_tone := clampDouble 0 100 (n_tone + delta * expansionDir)
    if (f_tone - n_tone) * expansionDir < delta then
      n_tone := clampDouble 0 100 (f_tone - delta * expansionDir)
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
  return #v[if aIsNearer then n_tone else f_tone, if aIsNearer then f_tone else n_tone]

public def group0
  (toneFnPair : ToneFnPair)
  (curveOnA curveOnB : ContrastCurve)
  (toneFnOnA toneFnOnB : ToneFn)
  : ToneFnGroup := fun s => Id.run do
  let toneAB := toneFnPair s
  let toneA := toneAB[0]
  let toneB := toneAB[1]
  let desiredOnA := curveOnA.get s.contrastLevel
  let desiredOnB := curveOnB.get s.contrastLevel
  let mut toneOnA := toneFnOnA s
  let mut toneOnB := toneFnOnB s
  if rationOfTones toneA toneOnA < desiredOnA then
    toneOnA := foregroundTone toneA desiredOnA
  if rationOfTones toneB toneOnB < desiredOnB then
    toneOnB := foregroundTone toneB desiredOnB
  if s.contrastLevel < 0 then
    toneOnA := foregroundTone toneA desiredOnA
    toneOnB := foregroundTone toneB desiredOnB
  return #v[toneA, toneB, toneOnA, toneOnB]

-- very stupid implementation, maybe optimize later
-- TODO: optimize
public def group1
  (toneFnPair : ToneFnPair)
  (curveC curveD : ContrastCurve)
  (toneFnC toneFnD : ToneFn)
  : ToneFnGroup := fun s => Id.run do
  let bgTones := toneFnPair s
  let bgTone2 := bgTones[0]
  let bgTone1 := bgTones[1]
  let upper := max bgTone1 bgTone2
  let lower := min bgTone1 bgTone2
  let desiredC := curveC.get s.contrastLevel
  let desiredD := curveD.get s.contrastLevel
  let mut toneC := toneFnC s
  let mut toneD := toneFnD s
  if rationOfTones upper toneC >= desiredC && rationOfTones lower toneC >= desiredC then
    if s.contrastLevel < 0 then
      toneC := foregroundTone bgTone1 desiredC
  else
    let lightOption := Contrast.lighter upper desiredC
    let darkOption := Contrast.darker lower desiredC
    let preferLighter := tonePrefersLightForeground bgTone1 || tonePrefersLightForeground bgTone2
    if preferLighter then
      toneC := lightOption.getD 100.0
    else
      toneC := darkOption.getD (lightOption.getD 0.0)
  if rationOfTones upper toneD >= desiredD && rationOfTones lower toneD >= desiredD then
    if s.contrastLevel < 0 then
      toneD := foregroundTone bgTone1 desiredD
  else
    let lightOption := Contrast.lighter upper desiredD
    let darkOption := Contrast.darker lower desiredD
    let preferLighter := tonePrefersLightForeground bgTone1 || tonePrefersLightForeground bgTone2
    if preferLighter then
      toneD := lightOption.getD 100.0
    else
      toneD := darkOption.getD (lightOption.getD 0.0)
  return #v[bgTone2, bgTone1, toneC, toneD]

public def getPalette (palette : Palette) : DynamicScheme → TonalPalette :=
  fun ds =>
    match palette with
    | .primary          => ds.primaryPalette
    | .secondary        => ds.secondaryPalette
    | .tertiary         => ds.tertiaryPalette
    | .neutral          => ds.neutralPalette
    | .neutralVariant   => ds.neutralVariantPalette
    | .error            => ds.errorPalette

public def getArgb (dc : DynamicColor) (scheme : DynamicScheme) : UInt32 :=
  (getPalette dc.palette scheme).getArgb (dc.toneFn scheme)

public def getArgbGroup (dcg : DynamicColorGroup) (scheme : DynamicScheme) : Vector UInt32 4:=
  (dcg.toneFnGroup scheme).map (getPalette dcg.palette scheme).getArgb
