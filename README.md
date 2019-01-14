# Compiler Test

These scripts act a bit like local continuous integration if you don't have access to your own instance to run on.

## [multi\_build.sh](multi_build.sh)

This script uses [cmake](https://cmake.org/) to build your project with all permutations of build type and compiler specified. The builds are timed and a summary printed to stdout at the end so you can see which took the longest. The output of cmake and the compiler are hidden by default for cleaner screen, but can be viewed if required.

```
$ ./multi-build.sh 

  USAGE: multi-build.sh -p path/to/project/source [-v] [-j jobs] [-g generator] [-m path/to/cmake] [-b build_typeA,build_typeB] [-c compilerA,compilerB,... ]

  Required Arguments
    -p   Path to the source that will be built

  Optional Arguments:
    -v   Show the cmake & make output, use as ON/OFF flag [default: OFF]
    -j   How many jobs to spawn during the build (ignored for ninja builds) [default: 4]
    -g   The build system to use [default: Unix Makefiles]
    -m   The version of cmake to use [default: /usr/bin/cmake]
    -b   Comma ',' separated list of build type to use with cmake [default: Debug]
    -c   Comma ',' separated list of compilers to create builds for [default: g++ clang++]
```

## [runtime.sh](runtime.sh)

This script will run the provided list of executables the number of times given. Printed are the total runtime and average.

```
$ ./runtime.sh 

  USAGE: runtime.sh [-n runs] [-s] [-p] [executable [executable ...] ]

  Required Arguments
    executable   Space separated list of executables to run
                 MUST appear after all other arguments [default: None]

  Optional Arguments:
    -n           Number of times to run each executable [default: 1]
    -p           Run each executable in the background, i.e. allow all to be run at once [default: OFF]
    -s           Store the individual run times into a file for further analysis [default: OFF]
```
