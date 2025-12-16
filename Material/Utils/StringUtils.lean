import Material.Utils.ColorUtils

namespace StringUtils

def hexFromArgb (argb : UInt32) : String :=
  "#" ++ (argb.toBitVec.extractLsb 23 0).toHex

end StringUtils
