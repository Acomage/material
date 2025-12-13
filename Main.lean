import Material.Utils.StringUtils
import Material.Extract.lean.Extract

open IO
open ColorExtract

def dealWithImage (imagePath : String) : IO Unit := do
  try
    let img ← extractColors imagePath 4
    /- println s!"Image loaded: {img.width}x{img.height}" -/
    /- println s!"First 10 pixels (as Int32):\n{(img.data.take 10).map (fun x => StringUtils.hexFromArgb x)}" -/
    println s!"Extracted {img.2} Colors:"
    println s!"{String.intercalate "\n" ((img.1.map (fun x => StringUtils.hexFromArgb x)).toList)}"
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
