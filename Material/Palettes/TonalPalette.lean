module
public import Material.Hct.Hct
public import Material.Hct.HctSolver
public import Material.Utils.ColorUtils

open ColorUtils

-- TODO:find some way to implement caching

/--
  the tonal palette structure in google's implementation
  contains a cache which map Int to Int, however lean4
  is a functional programming language which does not
  allow mutable fields in structures, so we will omit
  the cache for now.
-/
public structure TonalPalette where
  hue : Float
  chroma : Float
  keyColor : Hct
deriving Inhabited

namespace TonalPalette

def averageArgb (argb1 argb2 : UInt32) : UInt32 :=
  let avg := (argb1 ||| argb2) - (((argb1 ^^^ argb2) &&& 0xFEFEFEFE) >>> 1)
  avg ||| -16777216

def tone (tonalPalette : TonalPalette) (tone : UInt32) : UInt32 :=
  if h : tone == 99 && Hct.isYellow tonalPalette.hue then
    have hy : 0 < if tone = 99 then 1 else 0 := by grind
    averageArgb (tonalPalette.tone 98) (tonalPalette.tone 100)
  else
    (Hct.fromHct tonalPalette.hue tonalPalette.chroma tone.toFloat).toInt

public def getArgb (tonalPalette : TonalPalette) (tone : Float) : UInt32 :=
  HctSolver.solveToInt tonalPalette.hue tonalPalette.chroma tone

structure KeyColor where
  hue : Float
  requestedChroma : Float

namespace KeyColor

def create (keyColor : KeyColor) : Hct := Id.run do
  let pivotTone := 50
  let toneStepSize := 1
  let epsilon := 0.01
  let hue := keyColor.hue
  let requestedChroma := keyColor.requestedChroma
  let maxChromaFn := fun tone : Int32 => HctSolver.maxChroma hue tone.toFloat
  let mut lowerTone : Int32 := 0
  let mut upperTone : Int32 := 100
  while lowerTone < upperTone do
    let midTone := (lowerTone + upperTone) / 2
    let sufficientChroma := maxChromaFn midTone >= requestedChroma - epsilon
    if sufficientChroma then
      if (lowerTone - pivotTone).abs < (upperTone - pivotTone).abs then
        upperTone := midTone
      else if lowerTone == midTone then
        return Hct.fromHct hue requestedChroma lowerTone.toFloat
      else
        lowerTone := midTone
    else
      let isAscending := maxChromaFn midTone < maxChromaFn (midTone + toneStepSize)
      if isAscending then
        lowerTone := midTone + toneStepSize
      else
        upperTone := midTone
  return Hct.fromHct hue requestedChroma lowerTone.toFloat

end KeyColor

public def fromHct (hct : Hct) : TonalPalette :=
  ⟨hct.hue, hct.chroma, hct⟩

public def fromHueAndChroma (hue chroma : Float) : TonalPalette :=
  let keyColor := KeyColor.create ⟨hue, chroma⟩
  ⟨hue, chroma, keyColor⟩

end TonalPalette
