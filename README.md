# Material

This repository contains the google material color utilities rewritten in Lean4.

The qauntizer and score algorithms are implemented by Futhark.
Other algorithms are implemented by Lean4.

I'm have just ported the original code to Lean4 and Futhark thesedays.
Since the original code is written in OOP style, the code here may not be very "leany".
I will try to refactor the code to be more idiomatic Lean4 in the future.

# Build it from source
To Build the project from source, you need:
- lake
- Futhark
- ISPC (I use ISPC for the Futhark backend, but you can use other backends too)
- libpng and libjpeg-turbo (for image loading)
- make
- clang (I use clang for compiling the Futhark generated C code and LEAN_CC, but you can use other C compilers too)

Then, you can build the project by running:
```bash
make
```
or just run:
```bash
LEAN_CC=clang lake build
```

However, There are some tips you may want to know before building the project.
Since the C toolchain of Lean4 use old glibc, if your libpng and libjpeg-turbo
on your system are linked to your system glibc, you may get some errors.
So I recommend you to use clang or other C compilers for LEAN_CC instead of
using the default C toolchain of Lean4.
