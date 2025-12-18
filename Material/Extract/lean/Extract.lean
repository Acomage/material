module

public section

namespace ColorExtract

/-- External C function for color extraction -/
@[extern "lean_extract_colors"]
opaque extractColorsImpl : @& String → UInt32 → Array UInt32 × UInt32

/-- Extract dominant colors from an image file. 
    
    Parameters:
    - `path`: Path to the image file
    - `desiredCount`: Number of colors to extract (max 128)
    
    Returns:
    - `Array UInt32`: Array of extracted colors in 0xRRGGBB format
    - `Nat`: Actual number of colors extracted (may be less than requested)
-/
def extractColors (path : String) (desiredCount : Nat := 4) : IO (Array UInt32 × Nat) := do
  let count := UInt32.ofNat (min desiredCount 128)
  let (colors, actualCount) := extractColorsImpl path count
  return (colors, actualCount.toNat)

end ColorExtract
