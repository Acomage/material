module
public import Material.Utils.MathUtils

def SRGB_TO_XYZ : MathUtils.Mat3 := #v[
  #v[0.41233895, 0.35762064, 0.18051042],
  #v[0.2126,     0.7152,     0.0722    ],
  #v[0.01932141, 0.11916382, 0.95034478]
]

def XYZ_TO_SRGB : MathUtils.Mat3 := #v[
  #v[3.2413774792388685, -1.5376652402851851, -0.49885366846268053],
  #v[-0.9691452513005321, 1.8758853451067872, 0.04156585616912061 ],
  #v[0.05562093689691305, -0.20395524564742123, 1.0571799111220335]
]

namespace ColorUtils

public def WHITE_POINT_D65 := #v[95.047, 100.0, 108.883]

def linearized (rgbComponent : UInt32) : Float :=
  let normalized := rgbComponent.toFloat / 255.0
  if normalized <= 0.040449936 then
    normalized / 12.92 * 100.0
  else
    (((normalized + 0.055) / 1.055).pow 2.4) * 100.0

def trueDelinearized (rgbComponent : Float) : Float :=
  let normalized := rgbComponent / 100.0
  let delinearized :=
    if normalized <= 0.0031308 then
      normalized * 12.92
    else
      1.055 * (normalized.pow (1.0 / 2.4)) - 0.055
  delinearized * 255.0

def delinearized (rgbComponent : Float) : UInt32 :=
  MathUtils.clampInt 0 255 (trueDelinearized rgbComponent).toUInt32

def labF (t : Float) : Float :=
  let e := 216.0 / 24389.0
  let kappa := 24389.0 / 27.0
  if t > e then
    t.pow (1.0 / 3.0)
  else
    (kappa * t + 16.0) / 116.0

def labInvf (ft : Float) : Float :=
  let e := 216.0 / 24389.0
  let kappa := 24389.0 / 27.0
  let ft3 := ft.pow 3
  if ft3 > e then
    ft3
  else
    (116.0 * ft - 16.0) / kappa

public def yFromLstar (lstar : Float) : Float :=
  100.0 * labInvf ((lstar + 16.0) / 116.0)

public def lstarFromY (y : Float) : Float :=
  labF (y / 100.0) * 116.0 - 16.0

def argbFromRgb (red green blue : UInt32) : UInt32 :=
  (0xFF000000 : UInt32) ||| ((red &&& 255) <<< 16) ||| ((green &&& 255) <<< 8) ||| (blue &&& 255)

public def argbFromLinrgb (linrgb : MathUtils.Vec3) : UInt32 :=
  let v := linrgb.map delinearized
  argbFromRgb v[0] v[1] v[2]

def redFromArgb (argb : UInt32) : UInt32 :=
  (argb >>> 16) &&& 255

def greenFromArgb (argb : UInt32) : UInt32 :=
  (argb >>> 8) &&& 255

def blueFromArgb (argb : UInt32) : UInt32 :=
  argb &&& 255

public def argbFromXyz (x y z : Float) : UInt32 :=
  argbFromLinrgb (#v[x, y, z] * XYZ_TO_SRGB)

public def xyzFromArgb (argb : UInt32) : MathUtils.Vec3 :=
  let r := redFromArgb argb
  let g := greenFromArgb argb
  let b := blueFromArgb argb
  #v[r, g, b].map linearized * SRGB_TO_XYZ

public def labFromArgb (argb : UInt32) : MathUtils.Vec3 :=
  let xyz := xyzFromArgb argb
  let fxyz := (xyz.zipWith (·/·) WHITE_POINT_D65).map labF
  let fx := fxyz[0]
  let fy := fxyz[1]
  let fz := fxyz[2]
  #v[
    116.0 * fy - 16.0,
    500.0 * (fx - fy),
    200.0 * (fy - fz)
  ]

public def argbFromLstar (lstar : Float) : UInt32 :=
  let component := delinearized (yFromLstar lstar)
  argbFromRgb component component component

public def lstarFromArgb (argb : UInt32) : Float :=
  let y := (xyzFromArgb argb)[1]
  lstarFromY y

end ColorUtils
