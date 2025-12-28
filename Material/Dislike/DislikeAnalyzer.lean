module
public import Material.Hct.Hct


open Hct

namespace DislikeAnalyzer

def isDisliked (hct : Hct) : Bool :=
  let huePasses := (hct.hue).round >= 90.0 && (hct.hue).round <= 111.0
  let chromaPasses := (hct.chroma).round > 16.0
  let tonePasses := (hct.tone).round < 65.0
  huePasses && chromaPasses && tonePasses

public def fixIfDisliked (hct : Hct) : Hct :=
  if isDisliked hct then fromHct hct.hue hct.chroma 70.0 else hct

end DislikeAnalyzer
