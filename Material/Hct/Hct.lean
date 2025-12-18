module
public import Material.Utils.ColorUtils
public import Material.Hct.Cam16
public import Material.Hct.HctSolver
public import Material.Hct.ViewingConditions


open HctSolver

public structure Hct where
  hue : Float
  chroma : Float
  tone : Float
  argb : UInt32
deriving Inhabited

namespace Hct

public def toInt (hct : Hct) : UInt32 :=
  hct.argb

def setInteralState (argb : UInt32) : Hct :=
  let cam := Cam16.fromInt argb
  let tone := ColorUtils.lstarFromArgb argb
  ⟨cam.hue, cam.chroma, tone, argb⟩

public def fromHct (hue chroma tone : Float) : Hct :=
  let argb := solveToInt hue chroma tone
  ⟨hue, chroma, tone, argb⟩

public def fromInt (argb : UInt32) : Hct :=
  setInteralState argb

public def isYellow (hue : Float) : Bool :=
  (hue >= 105.0) && (hue <= 125.0)

instance : ToString Hct where
  toString hct :=
    s!"Hct({hct.hue}, {hct.chroma}, {hct.tone})"

end Hct

