import Material.Utils.ColorUtils

namespace StringUtils

def hexFromArgb (argb : Int32) : String :=
  "#" ++ (argb.toBitVec.extractLsb 23 0).toHex

end StringUtils
