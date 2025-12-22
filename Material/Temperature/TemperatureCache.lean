module
public import Material.Hct.Hct
public import Material.Utils.ColorUtils
public import Material.Utils.MathUtils

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
  (- 0.5 + 0.02 * (chroma ^ 1.07) * Float.cos (sanitizeDegreesDouble (hue - 50.0) * Pi / 180.0))

def getHctsByHue (input : Hct) : Array Hct:=
  (Array.range 360).map fun i => Hct.fromHct (i.toFloat) input.chroma input.tone

def getColdest (hcts : Array Hct) : Hct :=
  hcts.foldl (fun acc c =>
    if rawTemperature c < rawTemperature acc then c else acc) hcts[0]!

def getWarmest (hcts : Array Hct) : Hct :=
  hcts.foldl (fun acc c =>
    if rawTemperature c > rawTemperature acc then c else acc) hcts[0]!

def getRelativeTemperature (input : Hct) (coldestTemp warmestTemp : Float) : Float :=
  let inputTemp := rawTemperature input
  let range := warmestTemp - coldestTemp
  if range == 0.0 then 0.5 else
    (inputTemp - coldestTemp) / range

def getFindIndex(startHue endHue : Float) : Array Nat :=
  Array.range 360 |>.filter fun i =>
    isBetween i.toFloat startHue endHue

def argMin (xs : Array Float) : Nat :=
  Array.range xs.size |>.foldl (fun acc i =>
    if xs[i]! < xs[acc]! then i else acc) 0

public def getComplement(input : Hct) : Hct :=
  let hctByHue := getHctsByHue input
  let coldest := getColdest hctByHue
  let coldestHue := coldest.hue
  let coldestTemp := rawTemperature coldest
  let warmest := getWarmest hctByHue
  let warmestHue := warmest.hue
  let warmestTemp := rawTemperature warmest
  let range := warmestTemp - coldestTemp
  let startHueIsColdestToWarmest := isBetween input.hue coldestHue warmestHue
  let startHue := if startHueIsColdestToWarmest then warmestHue else coldestHue
  let endHue := if startHueIsColdestToWarmest then coldestHue else warmestHue
  let answer := hctByHue[input.hue.floor.toInt64.toNatClampNeg]!
  let complementRelativeTemp := 1.0 - getRelativeTemperature input coldestTemp warmestTemp
  let indices := getFindIndex startHue endHue
  let possibleAnswers := indices.map fun i => hctByHue[i]!
  let relativeTemps := possibleAnswers.map fun c => (rawTemperature c - coldestTemp) / range
  let errors := relativeTemps.map fun t => (complementRelativeTemp - t).abs
  let answerIndex := argMin errors
  possibleAnswers.getD answerIndex answer

def calculateTotalTempDelta (startHue : Nat) (hcts : Array Hct) (coldestTemp warmestTemp : Float) : Float :=
  let hues := (Array.range' startHue 360).map fun i => sanitizeDegreesInt i.toUInt32
  let hctsOrdered := hues.map fun h => hcts[h.toNat]!
  let temps := hctsOrdered.map fun c => getRelativeTemperature c coldestTemp warmestTemp
  let tempDeltas := Array.range 360 |>.map fun i =>
    if i == 0 then temps[0]! else (temps[i]! - temps[i - 1]!).abs
  tempDeltas.sum

structure AppendPlan where
  color : Hct
  count : Nat
deriving Inhabited

structure PlanState where
  lastTemp : Float
  totalTempDelta : Float
  plans : Array AppendPlan

def trimPlansTo
  (limit : Nat)
  (plans : Array AppendPlan) : Array AppendPlan :=
  let rec go
    (i : Nat)
    (accCount : Nat)
    (acc : Array AppendPlan) : Array AppendPlan :=
    if h : i < plans.size then
      let p := plans[i]!
      let next := accCount + p.count
      if next < limit then
        go (i + 1) next (acc.push p)
      else
        let adjusted :=
          { p with count := limit - accCount }
        acc.push adjusted
    else
      match acc.back? with
      | none => acc
      | some last =>
          let extra := limit - accCount
          if extra == 0 then acc
          else
            acc.pop.push { last with count := last.count + extra }
  go 0 0 #[]


def plannedSize (plans : Array AppendPlan) : Nat :=
  plans.foldl (fun acc p => acc + p.count) 0

def stepPlan
  (tempStep : Float)
  (coldestTemp warmestTemp : Float)
  (hct : Hct)
  (s : PlanState) : PlanState :=
  let temp := getRelativeTemperature hct coldestTemp warmestTemp
  let delta := (temp - s.lastTemp).abs
  let total := s.totalTempDelta + delta
  let currentSize := plannedSize s.plans
  let nRaw :=
    (((total / tempStep - currentSize.toFloat) / 2).floor + 1)
  let n :=
    if nRaw <= 0 then 0 else nRaw.toUInt64.toNat
  let plans :=
    if n == 0 then s.plans
    else s.plans.push { color := hct, count := n }
  { lastTemp := temp
    totalTempDelta := total
    plans := plans }

def materialize (plans : Array AppendPlan) : Array Hct :=
  plans.foldl
    (fun acc p => acc ++ Array.replicate p.count p.color)
    #[]

public def getAnalogousColors(input : Hct)(count : Int32 := 5)(divisions : Int32 := 12) : Array Hct := Id.run do
  let hctByHue := getHctsByHue input
  let coldest := getColdest hctByHue
  let coldestTemp := rawTemperature coldest
  let warmest := getWarmest hctByHue
  let warmestTemp := rawTemperature warmest
  let startHue := input.hue.toInt64.toNatClampNeg
  let startHct := hctByHue[startHue]!
  let absoluteTotalTempDelta := calculateTotalTempDelta startHue hctByHue coldestTemp warmestTemp
  let tempStep := absoluteTotalTempDelta / divisions.toFloat
  let hues :=
    (Array.range 360).map fun i =>
      sanitizeDegreesInt (startHue + i).toUInt32
  let initialState : PlanState :=
    { lastTemp := getRelativeTemperature startHct coldestTemp warmestTemp
      totalTempDelta := 0.0
      plans := #[] }
  let finalPlanState :=
    hues.foldl
      (fun s h =>
        let hct := hctByHue[h.toNat]!
        stepPlan tempStep coldestTemp warmestTemp hct s)
      initialState
  let trimmedPlans := trimPlansTo divisions.toNatClampNeg finalPlanState.plans
  let allColors := materialize trimmedPlans
  let ccwCount := (count - 1) / 2
  let indices := (Array.range count.toNatClampNeg).map fun i =>
    (i.toInt32 - ccwCount) % allColors.size.toInt32
  let colors := indices.map fun i => allColors[i.toNatClampNeg]!
  return colors.set! ccwCount.toNatClampNeg input

end Temperature
