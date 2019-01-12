#!/usr/bin/env bash

# Reset
RESTORE='\e[0m'

YELLOW='\e[0;33m'
BLUE='\e[0;34m'
GREEN='\e[0;32m'
PURPLE='\e[0;35m'
RED='\e[0;31m'
CYAN='\e[0;36m'
#WHITE="\e[0;37m"
#BLACK="\e[0;30m"

DEFAULT_COMPILERS=(g++ clang++)
DEFAULT_CMAKE=$(command -v cmake)
DEFAULT_BUILDGENERATOR="Unix Makefiles"
DEFAULT_JOBS=$(($(nproc)/2))
DEFAULT_BUILDTYPE=Debug
VERBOSE=0

usage() {
    echo -e "
  ${BLUE}USAGE${RESTORE}: ${BASH_SOURCE##*/} -p path/to/project/source [-j jobs] [-g generator] [-m path/to/cmake] [-b build_type] [compiler [compiler ...] ]

  Required Arguments
    -p         Path to the source that will be built

  Optional Arguments:
    -v         Show the cmake & make output, use as ON/OFF flag [default: OFF]
    -j         How many jobs to spawn during the build [default: ${DEFAULT_JOBS}]
    -g         The build system to use [default: ${DEFAULT_BUILDGENERATOR}]
    -m         The version of cmake to use [default: ${DEFAULT_CMAKE}]
    -b         Build type to use with cmake, for >1 use multiple instances of this option [default: ${DEFAULT_BUILDTYPE}]

    compiler   Space separated list of compilers to create builds for
               ${YELLOW}MUST appear after all other arguments ${RESTORE}[default: ${DEFAULT_COMPILERS[*]}]
"
    exit 1
}


RunCmake() {
    ${CMAKE} \
        -G "${BUILDGENERATOR}" \
        -DCMAKE_CXX_COMPILER="${1}" \
        -DCMAKE_BUILD_TYPE="${2}" \
        "${PROJECT}" > "${3}"
}


while getopts ":hvm:j:g:b:p:" OPTIONS
do
    case "${OPTIONS}" in
        h | \? | : )
            usage
            ;;
        v )
            VERBOSE=1
            ;;
        m )
            CMAKE=${OPTARG}
            ;;
        j )
            JOBS=${OPTARG}
            ;;
        g )
            BUILDGENERATOR=${OPTARG}
            ;;
        b )
            BUILDTYPE+=("${OPTARG}")
            ;;
        p )
            PROJECT=$(readlink -f "${OPTARG}")
            [ -d "${PROJECT}" ] || usage
            ;;
    esac
done
shift $((OPTIND-1))

COMPILERS=( "$@" )

if [[ ${#COMPILERS[@]} -eq 0 ]]
then
   COMPILERS=( "${DEFAULT_COMPILERS[@]}" )
fi

CMAKE=${CMAKE:-${DEFAULT_CMAKE}}
BUILDGENERATOR=${BUILDGENERATOR:-${DEFAULT_BUILDGENERATOR}}
JOBS=${JOBS:-${DEFAULT_JOBS}}

if [[ ${#BUILDTYPE[@]} -eq 0 ]]
then
    BUILDTYPE=( "${DEFAULT_BUILDTYPE}" )
fi

if [[ -z ${PROJECT} ]]
then
    usage
fi

#echo "<${VERBOSE}> <${CMAKE}> <${JOBS}> <${BUILDTYPE}> <${PROJECT}> <${COMPILERS[*]}>"
echo -e "
Running builds with
Compilers:    ${GREEN}${COMPILERS[*]}${RESTORE}
Build system: ${YELLOW}${BUILDGENERATOR}${RESTORE}"

declare -A COMPILE_TIMES

for COMPILER in "${COMPILERS[@]}"
do
    echo -e "\\nUsing ${PURPLE}${COMPILER}${RESTORE}"
    if ! command -v "${COMPILER}" > /dev/null
    then
        echo -e "${RED}WARNING${RESTORE}: ${COMPILER} not found in your PATH"
        continue
    fi

    EXE=$(command -v "${COMPILER}")

    for BUILD in "${BUILDTYPE[@]}"
    do
        BUILDDIR="${COMPILER##*/}-${BUILD}-build"

        if [[ ! -d "${BUILDDIR}" ]]
        then
            echo -e "Creating build directory: ${CYAN}${BUILDDIR}${RESTORE}"
            mkdir "${BUILDDIR}" || continue
        else
            echo -e "Using existing directory: ${CYAN}${BUILDDIR}${RESTORE}"
        fi

        pushd "${BUILDDIR}" > /dev/null || continue

        outfile=/dev/null
        if [[ ${VERBOSE} -eq 1 ]]
        then
            outfile=/dev/stdout
        fi

        if ! RunCmake "${EXE}" "${BUILD}" "${outfile}"
        then
            echo "cmake failed"
            continue
        fi

        if [[ ${BUILDGENERATOR} != "Ninja" ]]
        then
            ADDITIONALFLAGS=-j${JOBS}
        fi

        exec 3>${outfile}
        # Don't double quote ADDITIONALFLAGS, it can be empty
        # shellcheck disable=SC2086
        TIME=$(TIMEFORMAT="%R"; { time cmake --build . -- ${ADDITIONALFLAGS} 1>&3 ; } 2>&1 )
        exec 3>&-

        echo "Run time: ${TIME}"

        COMPILE_TIMES["${COMPILER##*/}-${BUILD}"]=${TIME}

        popd > /dev/null || continue
    done
done

echo ""
echo "Sorted compile times:"

for K in "${!COMPILE_TIMES[@]}"
do
    echo "$K | ${COMPILE_TIMES[$K]}"
done |
    sort -n -k3 | column -t

echo ""

exit $?
