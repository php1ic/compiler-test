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

declare -A AVG_RUNTIMES

#Allow ctrl-c to kill all processes spawned by this script
trap 'pkill -P $$' EXIT

usage () {
    echo -e "
  ${BLUE}USAGE${RESTORE}: ${BASH_SOURCE##*/} [-n runs] [-s] [-p] [executable [executable ...] ]

  Required Arguments
    executable   Space separated list of executables to run
                 ${YELLOW}MUST appear after all other arguments ${RESTORE}[default: None]

  Optional Arguments:
    -n           Number of times to run each executable [default: ${DEFAULT_RUNS}]
    -p           Run each executable in the background, i.e. allow all to be run at once [default: OFF]
    -s           Store the individual run times into a file for further analysis [default: OFF]
"
    exit 1
}

# Setup prior to running the command
preCommand() {
    local NAME="${1%-*}"
    local optionFile="${NAME}.in"
    local outFile="${NAME}.eps"

    echo "section=a
    type=c
    choice=b" > "${optionFile}"
}

# Run the actual command
fullCommand() {
    local NAME="${1%-*}"
    local optionFile="${NAME}.in"
    local outFile="${NAME}.eps"

    "${1}" -i "${optionFile}" -o "${outFile}"
}

# Cleanup after running the command
postCommand() {
    local NAME="${1%-*}"
    local optionFile="${NAME}.in"
    local outFile="${NAME}.eps"

    rm -f "${outFile}" "${optionFile}"
}


runCommand() {
    local NAME="${1%-*}"
    local TIMES="${2}"
    local SUM
    local AVG

    declare -a ALLTIMES
    exec 3>/dev/null
    for ((i=0; i<"${TIMES}"; i++))
    do
        preCommand "${1}"
        ALLTIMES+=( "$(TIMEFORMAT="%R"; { time fullCommand "$1" 1>&3; } 2>&1)" )
        postCommand "${1}"
    done
    exec 3>&-

    SUM=$( IFS='+'; bc <<< "${ALLTIMES[*]}" )

    AVG=$(echo "${SUM} ${#ALLTIMES[@]}" | awk '{print $1/$2}')

    AVG_RUNTIMES["${NAME}"]=${AVG}
    echo -e "Finished running ${1}\t${2} times @ $(date +%H:%M:%S), average runtime was ${AVG}s"

    if [[ ${STORE} -eq 1 ]]
    then
        printf "%s\n" "${ALLTIMES[@]}" > "${NAME}_runtime.dat"
    fi
}


while getopts ":hpsn:" OPTIONS
do
    case "${OPTIONS}" in
        h | \? | : )
            usage
            ;;
        p )
            PARALLEL=1
            ;;
        s )
            STORE=1
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
        runCommand "${EXE}" "${RUNS}" &
    else
        runCommand "${EXE}" "${RUNS}"
    fi
done

echo -e "\\nRunning the different versions...\\n"

#Wait for all runs to be finished
wait

echo -e "\\nAll versions have finished...\\n"

for t in "${!AVG_RUNTIMES[@]}"
do
    echo "${t} | ${AVG_RUNTIMES[$t]}"
done |
    sort -n -k3 | column -t

echo ""

exit $?
