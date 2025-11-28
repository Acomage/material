import Material.Utils.ColorUtils
import Material.Hct.Cam16
import Material.Hct.HctSolver
import Material.Hct.ViewingConditions

open HctSolver

structure Hct where
  hue : Float
  chroma : Float
  tone : Float
  argb : Int32

namespace Hct

def toInt (hct : Hct) : Int32 :=
  hct.argb

def setInteralState (argb : Int32) : Hct :=
  let cam := Cam16.fromInt argb
  let tone := ColorUtils.lstarFromArgb argb
  ⟨cam.hue, cam.chroma, tone, argb⟩

def setHue (hct : Hct) (newHue : Float) : Hct :=
  setInteralState (solveToInt newHue hct.chroma hct.tone)

def setChroma (hct : Hct) (newChroma : Float) : Hct :=
  setInteralState (solveToInt hct.hue newChroma hct.tone)

def setTone (hct : Hct) (newTone : Float) : Hct :=
  setInteralState (solveToInt hct.hue hct.chroma newTone)

def fromHct (hue chroma tone : Float) : Hct :=
  let argb := solveToInt hue chroma tone
  setInteralState argb

def inViewingConditions (hct : Hct) (vc : ViewingConditions) : Hct :=
  let cam := Cam16.fromInt hct.toInt
  let viewedInVc := cam.xyzInViewingConditions vc
  let recastInVc := Cam16.fromXyzInViewingConditions viewedInVc[0] viewedInVc[1] viewedInVc[2] ViewingConditions.DEFAULT
  fromHct recastInVc.hue recastInVc.chroma hct.tone

def fromInt (argb : Int32) : Hct :=
  setInteralState argb

def isBlue (hue : Float) : Bool :=
  (hue >= 250.0) && (hue <= 270.0)

def isYellow (hue : Float) : Bool :=
  (hue >= 105.0) && (hue <= 125.0)

def isCyan (hue : Float) : Bool :=
  (hue >= 170.0) && (hue <= 207.0)

instance : ToString Hct where
  toString hct :=
    s!"Hct({hct.hue}, {hct.chroma}, {hct.tone})"

end Hct

