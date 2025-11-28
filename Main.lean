import Material
import Image

def main : IO Unit := do
  IO.println s!"Hello, {hello}!"
  let img ← loadImage "/home/acomage/Pictures/wallpaper/Shuukura.png"
  IO.println s!"Image loaded: {img.width}x{img.height}, channels: {img.channels}"
