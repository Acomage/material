import Lake
open System Lake DSL

package material where
  precompileModules := true

lean_lib Material where
  moreLinkArgs := #[
  "-L/usr/lib",
  "-L/home/acomage/workspace/material/Material/Extract/futhark/build",
  "-L/home/acomage/workspace/material/Material/Extract/futhark/build/src/blend2d",
  "-lblend2d",
  "-lcolor_extract",
  "-lturbojpeg",
  "-lm"
]


@[default_target]
lean_exe material where
  root := `Main
  moreLinkArgs := #[
  "-L/usr/lib",
  "-L/home/acomage/workspace/material/Material/Extract/futhark/build",
  "-L/home/acomage/workspace/material/Material/Extract/futhark/build/src/blend2d",
  "-lcolor_extract",
  "-lblend2d",
  "-lturbojpeg",
  "-lm"
]
