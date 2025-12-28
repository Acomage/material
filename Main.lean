import Material.Utils.StringUtils
import Material.Extract.lean.Extract
import Material.Hct.Hct
import Material.Scheme.SchemeContent
import Material.Scheme.SchemeExpressive
import Material.Scheme.SchemeFidelity
import Material.Scheme.SchemeFruitSalad
import Material.Scheme.SchemeMonoChrome
import Material.Scheme.SchemeNeutral
import Material.Scheme.SchemeRainbow
import Material.Scheme.SchemeTonalSpot
import Material.Scheme.SchemeVibrant
import Material.DynamicColor.DynamicScheme

open IO
open ColorExtract
open StringUtils
open Hct
open DynamicScheme

def dealWithImage (imagePath : String) : IO Unit := do
  try
    let img ← extractColors imagePath 4
    println s!"Extracted {img.2} Colors:"
    println s!"{String.intercalate "\n" ((img.1.map (fun x => hexFromArgb x)).toList)}"
    println s!"Use source color {hexFromArgb ((img.1)[0]!)} to create scheme:"
    let contentDark := schemeContent (fromInt ((img.1)[0]!)) true
    let contentLight := schemeContent (fromInt ((img.1)[0]!)) false
    let expressiveDark := schemeExpressive (fromInt ((img.1)[0]!)) true
    let expressiveLight := schemeExpressive (fromInt ((img.1)[0]!)) false
    let fidelityDark := schemeFidelity (fromInt ((img.1)[0]!)) true
    let fidelityLight := schemeFidelity (fromInt ((img.1)[0]!)) false
    let fruitSaladDark := schemeFruitSalad (fromInt ((img.1)[0]!)) true
    let fruitSaladLight := schemeFruitSalad (fromInt ((img.1)[0]!)) false
    let monoChromeDark := schemeMonoChrome (fromInt ((img.1)[0]!)) true
    let monoChromeLight := schemeMonoChrome (fromInt ((img.1)[0]!)) false
    let neutralDark := schemeNeutral (fromInt ((img.1)[0]!)) true
    let neutralLight := schemeNeutral (fromInt ((img.1)[0]!)) false
    let rainbowDark := schemeRainbow (fromInt ((img.1)[0]!)) true
    let rainbowLight := schemeRainbow (fromInt ((img.1)[0]!)) false
    let tonalSpotDark := schemeTonalSpot (fromInt ((img.1)[0]!)) true
    let tonalSpotLight := schemeTonalSpot (fromInt ((img.1)[0]!)) false
    let vibrantDark := schemeVibrant (fromInt ((img.1)[0]!)) true
    let vibrantLight := schemeVibrant (fromInt ((img.1)[0]!)) false
    println "\nScheme Content Light:"
    println (showAllColors contentLight)
    println "\nScheme Content Dark:"
    println (showAllColors contentDark)
    println "\nScheme Expressive Light:"
    println (showAllColors expressiveLight)
    println "\nScheme Expressive Dark:"
    println (showAllColors expressiveDark)
    println "\nScheme Fidelity Light:"
    println (showAllColors fidelityLight)
    println "\nScheme Fidelity Dark:"
    println (showAllColors fidelityDark)
    println "\nScheme FruitSalad Light:"
    println (showAllColors fruitSaladLight)
    println "\nScheme FruitSalad Dark:"
    println (showAllColors fruitSaladDark)
    println "\nScheme MonoChrome Light:"
    println (showAllColors monoChromeLight)
    println "\nScheme MonoChrome Dark:"
    println (showAllColors monoChromeDark)
    println "\nScheme Neutral Light:"
    println (showAllColors neutralLight)
    println "\nScheme Neutral Dark:"
    println (showAllColors neutralDark)
    println "\nScheme Rainbow Light:"
    println (showAllColors rainbowLight)
    println "\nScheme Rainbow Dark:"
    println (showAllColors rainbowDark)
    println "\nScheme TonalSpot Light:"
    println (showAllColors tonalSpotLight)
    println "\nScheme TonalSpot Dark:"
    println (showAllColors tonalSpotDark)
    println "\nScheme Vibrant Light:"
    println (showAllColors vibrantLight)
    println "\nScheme Vibrant Dark:"
    println (showAllColors vibrantDark)
  catch ex =>
    eprintln s!"Failed to extractColors: {ex}"
    return

def dealWithImageFile (path : String) : IO UInt32 := do
  let file := System.FilePath.mk path
  if ←file.pathExists then
    println s!"Extract colors from {←FS.realPath file}..."
    dealWithImage (←FS.realPath file).toString
    return 0
  else
    eprintln s!"File not found: {file}"
    return 1

def main (args : List String) : IO UInt32 := do
  match args with
  | [] => eprintln "Argument required: path to image file" *> return 1
  | [x] => return (←dealWithImageFile x)
  | _ => eprintln "Too many arguments" *> return 1
