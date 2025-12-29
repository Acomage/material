module
public import Material.Hct.Hct
public import Material.Hct.HctSolver
public import Material.Utils.ColorUtils
public import Material.Hct.MaxChroma
public import Material.Utils.MathUtils

open ColorUtils MathUtils

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
  let pivotTone := 50.0
  let hue := keyColor.hue
  let requestedChroma := keyColor.requestedChroma
  let index := (hue * 2).round.toUInt32.toNat
  let maxChromaFn := HctSolver.maxChroma hue
  let (peakTone, peakChroma) := maxChromaPeak[index]!
  if peakChroma <= requestedChroma then
    return Hct.fromHct hue requestedChroma peakTone
  let mut y0 := (maxChromaFn pivotTone) - requestedChroma
  let mut p0 := pivotTone
  let mut p1 := peakTone
  let mut y1 := peakChroma - requestedChroma
  if y0 >= 0 then return Hct.fromHct hue requestedChroma pivotTone
  let epsilon := 0.1
  let mut iterations := 0
  while (p1 - p0).abs > epsilon && iterations < 20 do
    iterations := iterations + 1
    let mut mid := p0 - y0 * (p1 - p0) / (y1 - y0)
    if mid <= p0 + 0.005 || mid >= p1 - 0.005 then
      mid := (p0 + p1) / 2.0
    let y_mid := (maxChromaFn mid) - requestedChroma
    if y_mid < 0.0 then
      p0 := mid
      y0 := y_mid
    else
      p1 := mid
      y1 := y_mid
  return Hct.fromHct hue requestedChroma p1

end KeyColor

public def fromHct (hct : Hct) : TonalPalette :=
  ⟨hct.hue, hct.chroma, hct⟩

public def fromHueAndChroma (hue chroma : Float) : TonalPalette :=
  let hue := sanitizeDegreesDouble hue
  let keyColor := KeyColor.create ⟨hue, chroma⟩
  ⟨hue, chroma, keyColor⟩

end TonalPalette
