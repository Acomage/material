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
/- termination_by (if tone == 99 then 1 else 0) -/

public def getHct (tonalPalette : TonalPalette) (tone : Float) : Hct :=
  Hct.fromHct tonalPalette.hue tonalPalette.chroma tone

public def getArgb (tonalPalette : TonalPalette) (tone : Float) : UInt32 :=
  HctSolver.solveToInt tonalPalette.hue tonalPalette.chroma tone

/--
  the KeyColor structure in google's implementation also have a cache,
  we will omit it for the same reason as above.
-/
structure KeyColor where
  hue : Float
  requestedChroma : Float

namespace KeyColor

def MAX_CHROMA_VALUE := 200.0

def maxChroma (keyColor : KeyColor) (tone : Int32) : Float :=
  (Hct.fromHct keyColor.hue MAX_CHROMA_VALUE tone.toFloat).chroma

def create (keyColor : KeyColor) : Hct := runST fun s => do
  let pivotTone := 50
  let toneStepSize := 1
  let epsilon := 0.01
  let lowerToneRef : (ST.Ref s Int32) ← ST.mkRef 0
  let upperToneRef : (ST.Ref s Int32) ← ST.mkRef 100
  while (←lowerToneRef.get) < (←upperToneRef.get) do
    let lowerTone ← lowerToneRef.get
    let upperTone ← upperToneRef.get
    let midTone := (lowerTone + upperTone) / 2
    let isAscending := maxChroma keyColor midTone < maxChroma keyColor (midTone + toneStepSize)
    let sufficientChroma := maxChroma keyColor midTone >= keyColor.requestedChroma - epsilon
    if sufficientChroma then
      if (lowerTone - pivotTone).abs < (upperTone - pivotTone).abs then
        upperToneRef.set midTone
      else
        if lowerTone == midTone then
          return Hct.fromHct keyColor.hue keyColor.requestedChroma lowerTone.toFloat
        else
          lowerToneRef.set midTone
    else
      if isAscending then
        lowerToneRef.set (midTone + toneStepSize)
      else
        upperToneRef.set midTone
  return Hct.fromHct keyColor.hue keyColor.requestedChroma (←lowerToneRef.get).toFloat

end KeyColor

public def fromHct (hct : Hct) : TonalPalette :=
  ⟨hct.hue, hct.chroma, hct⟩

public def fromInt (argb : UInt32) : TonalPalette :=
  fromHct (Hct.fromInt argb)

public def fromHueAndChroma (hue chroma : Float) : TonalPalette :=
  let keyColor := KeyColor.create ⟨hue, chroma⟩
  ⟨hue, chroma, keyColor⟩

end TonalPalette
