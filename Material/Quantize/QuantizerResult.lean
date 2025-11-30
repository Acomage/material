import Std.Data.HashMap

structure QuantizerResult where
  colorToCount : Std.HashMap UInt32 UInt32
  inputPixelToClusterPixel : Std.HashMap UInt32 UInt32
