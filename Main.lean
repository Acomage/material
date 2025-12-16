import Material.Utils.StringUtils
import Material.Extract.lean.Extract
import Material.Hct.Hct
import Material.Scheme.SchemeTonalSpot
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
    println s!"Use source color {hexFromArgb ((img.1)[0]!)} to create a Tonal Spot scheme:"
    let schemeDark := schemeTonalSpot (fromInt ((img.1)[0]!)) true
    println (showAllColors schemeDark)
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
