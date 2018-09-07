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

DEFAULT_RUNS=100

#Allow ctrl-c to kill all processes spawned by this script
trap 'pkill -P $$' EXIT

usage () {
    echo -e "
  ${BLUE}USAGE${RESTORE}: ${BASH_SOURCE##*/} [-n runs] [-p] [executable [executable ...] ]

  Required Arguments
    executable   Space separated list of executables to run
                 ${YELLOW}MUST appear after all other arguments ${RESTORE}[default: None]

  Optional Arguments:
    -n           Number of times to run each executable [default: ${DEFAULT_RUNS}]
    -p           Run each executable in the background, i.e. allow all to be run at once [default: OFF]
"
    exit 1
}


CreateOptionFile() {
    echo "section=a
    type=c
    choice=b
    "
}


runEXE() {
    NAME="${1%-*}"
    TIMES="${2}"

    optionFile="${NAME}.in"

    CreateOptionFile > "${optionFile}"

    for ((i=0; i<"${TIMES}"; i++))
    do
        /usr/bin/time -f "RunTime - %e" "$1" -i "${optionFile}" -o "${NAME}" > /dev/null 2>> "${NAME}"_runtime.dat
        rm -f "${NAME}.eps"
    done

    echo -e "Finished running ${1}\t${2} times @ $(date +%H:%M:%S)"
}


while getopts ":hpn:" OPTIONS
do
    case "${OPTIONS}" in
        h | \? | : )
            usage
            ;;
        p )
            PARALLEL=1
            ;;
        n )
            RUNS=${OPTARG}
            ;;
    esac
done
shift $((OPTIND-1))

EXES=( "$@")

if [[ ${#EXES[@]} -eq 0 ]]
then
    usage
fi

RUNS=${RUNS:-${DEFAULT_RUNS}}


echo -e "
${BLUE}Start time${RESTORE}: $(date +%H:%M:%S)
Running the following ${GREEN}${RUNS}${RESTORE} times:
"

for EXE in "${EXES[@]}"
do
    echo -e " - ${PURPLE}${EXE}${RESTORE}"
    if [[ ${PARALLEL} -eq 1 ]]
    then
        runEXE "${EXE}" "${RUNS}" &
    else
        runEXE "${EXE}" "${RUNS}"
    fi
done

echo -e "\\nRunning the different versions...\\n"

#Wait for all runs to be finished
wait

echo -e "\\nAll versions have finished...\\n"

exit $?
