module
public import Material.Hct.Hct
public import Material.Utils.ColorUtils
public import Material.Utils.MathUtils
import all Init.Data.Array.QSort.Basic


open MathUtils

namespace Temperature

def isBetween (angle a b : Float) : Bool :=
  if a < b then
    a <= angle && angle <= b
  else
    a <= angle || angle <= b

def rawTemperature (color : Hct) : Float :=
  let lab := ColorUtils.labFromArgb color.toInt
  let hue := sanitizeDegreesDouble (Float.atan2 lab[2] lab[1] * 180.0 / Pi)
  let chroma := MathUtils.hypot lab[1] lab[2]
  let temperature := -0.5 + 0.02 * (chroma ^ 1.07) * Float.cos (sanitizeDegreesDouble (hue - 50.0) * Pi / 180.0)
  temperature

def getHctsByHue (input : Hct) : Array Hct:=
  (Array.range 361).map fun i => Hct.fromHct (i.toFloat) input.chroma input.tone

def getHctsByTemp(input : Hct) : Array Hct :=
  let hcts := getHctsByHue input
  let hcts := hcts.push input
  hcts.qsort (fun a b => rawTemperature a < rawTemperature b)

theorem getHctsByTemp_nonempty (input : Hct) : 0 < (getHctsByTemp input).size := by
  simp[getHctsByTemp, getHctsByHue, Array.qsort]

def getColdest (input : Hct) : Hct :=
  (getHctsByTemp input)[0]'(getHctsByTemp_nonempty input)

def getWarmest (input : Hct) : Hct :=
  (getHctsByTemp input).back (getHctsByTemp_nonempty input)

def getRelativeTemperature (input : Hct) : Float :=
  let coldest := getColdest input
  let warmest := getWarmest input
  let coldestTemp := rawTemperature coldest
  let warmestTemp := rawTemperature warmest
  let inputTemp := rawTemperature input
  let range := warmestTemp - coldestTemp
  if range == 0.0 then 0.5 else
    (inputTemp - coldestTemp) / range

public def getComplement(input : Hct) : Hct := Id.run do
  let hctByHue := getHctsByHue input
  let coldest := getColdest input
  let coldestHue := coldest.hue
  let coldestTemp := rawTemperature coldest
  let warmest := getWarmest input
  let warmestHue := warmest.hue
  let warmestTemp := rawTemperature warmest
  let range := warmestTemp - coldestTemp
  let startHueIsColdestToWarmest := isBetween input.hue coldestHue warmestHue
  let startHue := if startHueIsColdestToWarmest then warmestHue else coldestHue
  let endHue := if startHueIsColdestToWarmest then coldestHue else warmestHue
  let directionOfRotation := 1.0
  let mut smallestError := 1000.0
  -- TODO: prove index valid
  let mut answer := hctByHue[input.hue.round.toInt64.toNatClampNeg]!
  let complementRelativeTemp := 1.0 - getRelativeTemperature input
  let mut hueAddend := 0.0
  while hueAddend < 360.0 do
    let hue := sanitizeDegreesDouble (startHue + directionOfRotation * hueAddend)
    if not (isBetween hue startHue endHue) then
      hueAddend := hueAddend + 1.0
      continue
    -- TODO: prove index valid
    let possibleAnswer := hctByHue[hue.round.toInt64.toNatClampNeg]!
    let relativeTemp := (rawTemperature possibleAnswer - coldestTemp) / range
    let error := (complementRelativeTemp - relativeTemp).abs
    if error < smallestError then
      smallestError := error
    answer := possibleAnswer
    hueAddend := hueAddend + 1.0
  return answer

public def getAnalogousColors(input : Hct)(count : Int32 := 5)(divisions : Int32 := 12) : Array Hct := Id.run do
  let hctbyHue := getHctsByHue input
  let startHue := input.hue.toInt64.toNatClampNeg
  -- TODO: prove index valid
  let startHct := hctbyHue[startHue]!
  let mut lastTemp := getRelativeTemperature startHct
  let mut allColors : Array Hct := #[startHct]
  let mut absoluteTotalTempDelta := 0
  for i in Array.range 360 do
    let hue := sanitizeDegreesInt (startHue + i).toUInt32
    -- TODO: prove index valid
    let hct := hctbyHue[hue.toNat]!
    let temp := getRelativeTemperature hct
    let tempDelta := (temp - lastTemp).abs
    lastTemp := temp
    absoluteTotalTempDelta := absoluteTotalTempDelta + tempDelta
  let mut hueAddend := 1
  let tempStep := absoluteTotalTempDelta / divisions.toFloat
  let mut totalTempDelta := 0.0
  lastTemp := getRelativeTemperature startHct
  while allColors.size.toInt32 < divisions do
    let hue := sanitizeDegreesInt (startHue + hueAddend).toUInt32
    -- TODO: prove index valid
    let hct := hctbyHue[hue.toNat]!
    let temp := getRelativeTemperature hct
    let tempDelta := (temp - lastTemp).abs
    totalTempDelta := totalTempDelta + tempDelta
    let mut desiredTotalTempDeltaForIndex := (allColors.size).toFloat * tempStep
    let mut indexSatisfied : Bool := totalTempDelta >= desiredTotalTempDeltaForIndex
    let mut indexAddend := 1
    while indexSatisfied && (allColors.size.toInt32 < divisions) do
      allColors := allColors.push hct
      desiredTotalTempDeltaForIndex := (allColors.size + indexAddend).toFloat * tempStep
      indexSatisfied := totalTempDelta >= desiredTotalTempDeltaForIndex
      indexAddend := indexAddend + 1
    lastTemp := temp
    hueAddend := hueAddend + 1
    if hueAddend >= 360 then
      while allColors.size.toInt32 < divisions do
        allColors := allColors.push hct
      break
  let mut answers : Array Hct := #[input]
  let ccwCount := (count - 1) / 2
  for i in Array.range ccwCount.toNatClampNeg do
    let mut index : Int32 := - 1 - i.toInt32
    while index < 0 do
      index := index + allColors.size.toInt32
    if index >= allColors.size.toInt32 then
      index := index % (allColors.size.toInt32)
    answers := answers.insertIdx 0 allColors[index.toNatClampNeg]!
  let cwCount := count - ccwCount - 1
  for i in Array.range cwCount.toNatClampNeg do
    let index := (i.toInt32 + 1) % allColors.size.toInt32
    answers := answers.push allColors[index.toNatClampNeg]!
  return answers

end Temperature
