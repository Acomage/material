import Material.Utils.StringUtils
import Image

open IO

def dealWithImage (imagePath : String) : IO Unit := do
  let img ← loadImage imagePath
  println s!"Image loaded: {img.width}x{img.height}, channels: {img.channels}"
  println s!"First 10 pixels (as Int32):\n{(img.toPixelArrayFast.take 10).map (fun x => StringUtils.hexFromArgb x)}"

def dealWithImageFile (path : String) : IO UInt32 := do
  let file := System.FilePath.mk path
  if ←file.pathExists then
    println s!"Loading image from {←FS.realPath file}..."
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
