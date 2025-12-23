module
public import Material.Hct.Hct
public import Material.Utils.ColorUtils
public import Material.Utils.MathUtils

open MathUtils

structure AppendPlan where
  color : Hct
  count : Nat
deriving Inhabited

structure PlanState where
  lastTemp : Float
  totalTempDelta : Float
  plans : Array AppendPlan

namespace PlanState

def size (s : PlanState) : Nat :=
  s.plans.foldl (fun acc p => acc + p.count) 0

end PlanState

structure HueRing where
  chroma : Float
  tone   : Float
  hcts : Array Hct
  temps  : Array Float
  coldestTemp : Float
  warmestTemp : Float
  coldestHue : Int
  warmestHue : Int
  invRange  : Float

namespace HueRing

def rawTemperature (color : Hct) : Float :=
  let lab := ColorUtils.labFromArgb color.toInt
  let hue := sanitizeDegreesDouble (Float.atan2 lab[2] lab[1] * 180.0 / Pi)
  let chroma := hypot lab[1] lab[2]
  (- 0.5 + 0.02 * (chroma ^ 1.07) * Float.cos (sanitizeDegreesDouble (hue - 50.0) * Pi / 180.0))

def getHctsByHue (input : Hct) : Array Hct:=
  (Array.range 360).map fun i => Hct.fromHct (i.toFloat) input.chroma input.tone

def make (input : Hct) : HueRing :=
  let hcts := getHctsByHue input
  let temps := hcts.map rawTemperature
  let coldestHue := argMin temps
  let warmestHue := argMax temps
  let coldestTemp := temps[coldestHue]!
  let warmestTemp := temps[warmestHue]!
  let invRange :=
    if warmestTemp - coldestTemp == 0.0 then 0.0
    else 1.0 / (warmestTemp - coldestTemp)
  { chroma := input.chroma
    tone := input.tone
    hcts := hcts
    temps := temps
    coldestTemp := coldestTemp
    warmestTemp := warmestTemp
    coldestHue := Int.ofNat coldestHue
    warmestHue := Int.ofNat warmestHue
    invRange := invRange }

end HueRing

namespace Temperature

def isBetween (angle a b : Int) : Bool :=
  if a < b then
    a <= angle && angle <= b
  else
    a <= angle || angle <= b

def getRelativeTemperature (inputTemp coldestTemp warmestTemp : Float) : Float :=
  let range := warmestTemp - coldestTemp
  if range == 0.0 then 0.5 else
    (inputTemp - coldestTemp) / range

def getFindIndex(startHue endHue : Int) : Array Nat :=
  Array.range 360 |>.filter fun i =>
    isBetween i startHue endHue

public def getComplement(input : Hct) : Hct :=
  let hueRing := HueRing.make input
  let hctByHue := hueRing.hcts
  let coldestHue := hueRing.coldestHue
  let coldestTemp := hueRing.coldestTemp
  let warmestHue := hueRing.warmestHue
  let warmestTemp := hueRing.warmestTemp
  let startHueIsColdestToWarmest := isBetween input.hue.toInt64.toInt coldestHue warmestHue
  let startHue := if startHueIsColdestToWarmest then warmestHue else coldestHue
  let endHue := if startHueIsColdestToWarmest then coldestHue else warmestHue
  let indices := getFindIndex startHue endHue
  if indices.size == 0 then input
  else
    let complementTemp := coldestTemp + warmestTemp - (HueRing.rawTemperature input)
    let temps := indices.map fun i => hueRing.temps[i]!
    let errors := temps.map fun t => (complementTemp - t).abs
    let answerIndex := argMin errors
    hctByHue[indices[answerIndex]!]!

def calculateTotalTempDelta (startHue : Nat) (hueRing : HueRing) : Float :=
  let hues := (Array.range' startHue 360).map fun i => sanitizeDegreesInt i.toUInt32
  let temps := hues.map fun h => getRelativeTemperature hueRing.temps[h.toNat]! hueRing.coldestTemp hueRing.warmestTemp
  let tempDeltas := Array.range 359 |>.map fun i => (temps[i + 1]! - temps[i]!).abs
  tempDeltas.sum

def trimPlansTo
  (limit : Nat)
  (plans : Array AppendPlan) : Array AppendPlan :=
  let rec go (i accCount : Nat) (acc : Array AppendPlan) :=
    if i < plans.size then
      let p := plans[i]!
      let next := accCount + p.count
      if next < limit then
        go (i + 1) next (acc.push p)
      else
        acc.push { p with count := limit - accCount }
    else
      match acc.back? with
      | none => acc
      | some last =>
          let extra := limit - accCount
          if extra == 0 then acc
          else acc.pop.push { last with count := last.count + extra }
  go 0 0 #[]

def sampleCount
  (totalDelta tempStep : Float)
  (currentSize : Nat) : Nat :=
  let nRaw :=
    (((totalDelta / tempStep - currentSize.toFloat) / 2).floor + 1)
  if nRaw <= 0 then 0 else nRaw.toUInt64.toNat

def stepPlan
  (tempStep : Float)
  (hueRing : HueRing)
  (hct : Hct)
  (s : PlanState) : PlanState :=
  let temp := getRelativeTemperature hueRing.temps[hct.hue.toUInt32.toNat]! hueRing.coldestTemp hueRing.warmestTemp
  let delta := (temp - s.lastTemp).abs
  let total := s.totalTempDelta + delta
  let n := sampleCount total tempStep s.size
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

public def getAnalogousColors
  (input : Hct)
  (count : Int32 := 5)
  (divisions : Int32 := 12) : Array Hct :=
  let hueRing := HueRing.make input
  let hctByHue := hueRing.hcts
  let coldestTemp := hueRing.temps[hueRing.coldestHue.toNat]!
  let warmestTemp := hueRing.temps[hueRing.warmestHue.toNat]!
  let startHue := input.hue.toInt64.toNatClampNeg
  let totalDelta :=
    calculateTotalTempDelta startHue hueRing
  let tempStep := totalDelta / divisions.toFloat
  let hues :=
    (Array.range 360).map fun i =>
      sanitizeDegreesInt (startHue + i).toUInt32
  let initialState : PlanState :=
    { lastTemp := getRelativeTemperature hueRing.temps[startHue]! coldestTemp warmestTemp
      totalTempDelta := 0.0
      plans := #[] }
  let plans :=
    hues.foldl
      (fun s h =>
        stepPlan tempStep hueRing hctByHue[h.toNat]! s)
      initialState
    |>.plans
    |> trimPlansTo divisions.toNatClampNeg
  let allColors := materialize plans
  let ccwCount := (count - 1) / 2
  let indices :=
    (Array.range count.toNatClampNeg).map fun i =>
      (Int.ofNat i - ccwCount.toInt) % allColors.size
  indices
    |>.map (fun i => allColors[i.toNat]!)
    |>.set! ccwCount.toNatClampNeg input

end Temperature
