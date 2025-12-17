import Material.DynamicColor.Types
import Material.Contrast.Contrast
import Material.DynamicColor.ContrastCurve

namespace DynamicColor

-- TODO: I don't know why there is a round, if test proof that it is not needed remove it
def tonePrefersLightForeground (tone : Float) : Bool :=
  tone < 60.5

def toneAllowsLightForeground (tone : Float) : Bool :=
  tone <= 49.5

def foregroundTone (bgTone ratio : Float) : Float :=
  let lighterTone := Contrast.lighterUnsafe bgTone ratio
  let darkerTone := Contrast.darkerUnsafe bgTone ratio
  let lighterRatio := Contrast.rationOfTones lighterTone bgTone
  let darkerRatio := Contrast.rationOfTones darkerTone bgTone
  let preferLighter := tonePrefersLightForeground bgTone
  if preferLighter then
    let negligibleDifference := (lighterRatio - darkerRatio).abs < 0.1 && lighterRatio < ratio && darkerRatio < ratio
    if lighterRatio >= ratio || lighterRatio >= darkerRatio || negligibleDifference then lighterTone else darkerTone
  else
    if darkerRatio >= ratio || darkerRatio >= lighterRatio then darkerTone else lighterTone

def enableLightForeground (tone : Float) : Float :=
  if tonePrefersLightForeground tone && !toneAllowsLightForeground tone then 49.0 else tone

def fromPalette
  (name : String)
  (palette : DynamicScheme → TonalPalette)
  (tone : DynamicScheme → Float) : DynamicColor :=
  ⟨name, palette, tone, false, .none, .none, .none, .none⟩

-- TODO: maybe this funtion is not partial
partial def getTone (dc : DynamicColor) (scheme : DynamicScheme) : Float := Id.run do
  let decreasingContrast : Bool := scheme.contrastLevel < 0
  match dc.tone_delta_pair with
  | none =>
    let mut answer := dc.tone scheme
    match dc.background with
    | none => return answer
    | some bg =>
      let bg_tone := (bg scheme).getTone scheme
      let desiredRatio := (dc.contrast_curve.get!).get scheme.contrastLevel
      if Contrast.rationOfTones bg_tone answer < desiredRatio then
        answer := foregroundTone bg_tone desiredRatio
      if decreasingContrast then
        answer := foregroundTone bg_tone desiredRatio
      if dc.isBackground && 50 <= answer && answer < 60 then
        if Contrast.rationOfTones 49.0 bg_tone >= desiredRatio then
          answer := 49.0
        else
          answer := 60.0
      match dc.second_background with
      | none => return answer
      | some sbg =>
        let bg_tone_1 := (bg scheme).getTone scheme
        let bg_tone_2 := (sbg scheme).getTone scheme
        let upper := max bg_tone_1 bg_tone_2
        let lower := min bg_tone_1 bg_tone_2
        if Contrast.rationOfTones upper answer >= desiredRatio &&
          Contrast.rationOfTones lower answer >= desiredRatio then
            return answer
        else
          let lightOption := Contrast.lighter upper desiredRatio
          let darkOption := Contrast.darker lower desiredRatio
          let mut available : Array Float := #[]
          if h : lightOption.isSome then
            available := available.push (lightOption.get h)
          if h' : darkOption.isSome then
            available := available.push (darkOption.get h')
          let prefersLight := tonePrefersLightForeground bg_tone_1 ||
            tonePrefersLightForeground bg_tone_2
          if prefersLight then
            return lightOption.getD 100.0
          if h'' : available.size = 1 then
            have h''' : 0 < available.size := by
              rw [h'']
              decide
            return available[0]
          return darkOption.getD 0.0
  | some tdp =>
    let toneDeltaPair := tdp scheme
    let roleA := toneDeltaPair.role_a
    let roleB := toneDeltaPair.role_b
    let delta := toneDeltaPair.delta
    let polarity := toneDeltaPair.polarity
    let stayTogether := toneDeltaPair.stay_together
    -- here we use getD, but seems like the none case is not possible
    -- is so, we need to fix it.
    -- TODO: review this part
    let bg := dc.background.getD (fun _ => Inhabited.default) scheme
    let bg_tone := bg.getTone scheme
    let aIsNearer := match polarity with
      | TonePolarity.nearer => true
      | TonePolarity.farther => false
      | TonePolarity.darker => scheme.isDark
      | TonePolarity.lighter => not scheme.isDark
    let nearer := if aIsNearer then roleA else roleB
    let farther := if aIsNearer then roleB else roleA
    let amNearer := dc.name == nearer.name
    let expansionDir := if scheme.isDark then 1.0 else -1.0
    -- here we use get!, but seems like the none case is not possible
    -- TODO: review this part
    let n_contrast := (nearer.contrast_curve.get!).get scheme.contrastLevel
    let f_contrast := (farther.contrast_curve.get!).get scheme.contrastLevel
    let n_initial_tone := nearer.tone scheme
    let mut n_tone := if Contrast.rationOfTones bg_tone n_initial_tone >= n_contrast then
      n_initial_tone
    else
      foregroundTone bg_tone n_contrast
    let f_initial_tone := farther.tone scheme
    let mut f_tone := if Contrast.rationOfTones bg_tone f_initial_tone >= f_contrast then
      f_initial_tone
    else
      foregroundTone bg_tone f_contrast
    if decreasingContrast then do
      n_tone := foregroundTone bg_tone n_contrast
      f_tone := foregroundTone bg_tone f_contrast
    if (f_tone - n_tone) * expansionDir < delta then
      f_tone := MathUtils.clampDouble (n_tone + delta * expansionDir) 0.0 100.0
      if (f_tone - n_tone) * expansionDir < delta then
        n_tone := MathUtils.clampDouble (f_tone - delta * expansionDir) 0.0 100.0
    if 50 <= n_tone && n_tone < 60 then
      if expansionDir > 0 then
        n_tone := 60
        f_tone := max f_tone  (n_tone + delta * expansionDir)
      else
        n_tone := 49
        f_tone := min f_tone (n_tone + delta * expansionDir)
    else if 50 <= f_tone && f_tone < 60 then
      if stayTogether then
        if expansionDir > 0 then
          n_tone := 60
          f_tone := max f_tone (n_tone + delta * expansionDir)
        else
          n_tone := 49
          f_tone := min f_tone (n_tone + delta * expansionDir)
      else
        if expansionDir > 0 then
          f_tone := 60
        else
          f_tone := 49
    return if amNearer then n_tone else f_tone

def getArgb (dc : DynamicColor) (scheme : DynamicScheme) : UInt32 :=
  (dc.palette scheme).getArgb (getTone dc scheme)

def getHct (dc : DynamicColor) (scheme : DynamicScheme) : Hct :=
  (dc.palette scheme).getHct (getTone dc scheme)

end DynamicColor
