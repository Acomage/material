import Lake
open System Lake DSL

package material where
  precompileModules := true

def futharkDir : FilePath := "Material" / "Extract" / "futhark"
def futharkSrc : FilePath := futharkDir / "src"
def futharkBuild : FilePath := futharkDir / "build"

target futhark.c pkg :  FilePath := do
  let srcDir := pkg.dir / futharkSrc
  let buildDir := pkg.dir / futharkBuild
  let outFile := buildDir / "extract.c"
  let srcJob ← inputFile (srcDir / "extract.fut") true

  buildFileAfterDep outFile srcJob fun _srcFile => do
    createParentDirs outFile
    proc {
      cmd := "futhark"
      args := #["ispc", "--library", (srcDir / "extract.fut").toString,
                "-o", (buildDir / "extract").toString]
      cwd := pkg.dir
    }

target ispc.o pkg : FilePath := do
  let buildDir := pkg.dir / futharkBuild
  let ispcFile := buildDir / "extract.kernels.ispc"
  let oFile := buildDir / "extract.kernels.o"
  let futharkJob ← fetch <| pkg.target ``futhark.c

  buildFileAfterDep oFile futharkJob fun _ => do
    proc {
      cmd := "ispc"
      args := #[ispcFile.toString, "-o", oFile.toString,
                "--addressing=32", "--pic", "--woff", "-O3"]
      cwd := pkg.dir
    }

target extract.o pkg : FilePath := do
  let buildDir := pkg.dir / futharkBuild
  let srcDir := pkg.dir / futharkSrc
  let srcFile := buildDir / "extract.c"
  let oFile := buildDir / "extract.o"
  let futharkJob ← fetch <| pkg.target ``futhark.c
 

  buildFileAfterDep oFile futharkJob fun _ => do
    proc {
      cmd := "clang"
      args := #["-c", "-O3", "-march=native", "-ffast-math", "-fPIC",
                "-Wnan-infinity-disabled",
                "-I", srcDir.toString,
                srcFile.toString, "-o", oFile.toString]
      cwd := pkg.dir
    }

target ffi.o pkg :  FilePath := do
  let srcDir := pkg.dir / futharkSrc
  let buildDir := pkg.dir / futharkBuild
  let srcFile := srcDir / "color_extract_ffi.c"
  let oFile := buildDir / "color_extract_ffi.o"
  let futharkJob ← fetch <| pkg.target ``futhark.c
  let srcJob ← inputFile srcFile true
  let depJob := futharkJob.mix srcJob
  buildFileAfterDep oFile depJob fun _ => do
    let leanInclude ← getLeanIncludeDir
    proc {
      cmd := "clang"
      args := #["-c", "-O3", "-ffast-math", "-fPIC",
                "-I", leanInclude.toString,
                "-I", srcDir.toString,
                "-I", buildDir.toString,
                srcFile.toString, "-o", oFile.toString]
      cwd := pkg.dir
    }

extern_lib libextractffi pkg := do
  let name := nameToStaticLib "extractffi"
  let ispcO ← fetch <| pkg.target ``ispc.o
  let extractO ← fetch <| pkg.target ``extract.o
  let ffiO ← fetch <| pkg.target ``ffi.o
  buildStaticLib (pkg.staticLibDir / name) #[ispcO, extractO, ffiO]

lean_lib Material where
  /- leanOptions := #[⟨`experimental.module, true⟩] -/
  moreLinkArgs := #["-L/usr/lib", "-lm", "-lpng", "-lturbojpeg"]

@[default_target]
lean_exe material where
  root := `Main
  /- leanOptions := #[⟨`experimental.module, true⟩] -/
  moreLinkArgs :=#[
    "-L/usr/lib", "-lm", "-lpng", "-lturbojpeg",
    ]
