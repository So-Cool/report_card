#!/bin/bash

# check whether real is already installed
# input: $REAL-VERSION $REAL-SOURCE $SWIPL-VERSION
function realInstall {
    swipl -g "use_module(library('real')), halt" -t 'halt(1)' 2>/dev/null 1>/dev/null
    REALi=$?
    if [ $REALi -eq 0 ]; then
        # check version of installed package and suggest upgrade if possible
        REALvi=$(swipl -g 'pack_property(real, version(A)), write(A), halt' -t 'halt(1)' | sed 's/\([0-9]\)\.\([0-9]\)\.[0-9]/\1.\2/')
        echo "-- Real package already installed in version $REALvi.x"
        if [[ $3 == *"6"* ]] & [[ $REALvi == "1.1" ]]; then
            echo "-- Nothing to do here"
        elif [[ $3 == *"6"* ]]; then
            echo "-- Please consider upgrading you real version from currently installed $REALvi.x to 1.1.0"
        elif [[ $3 == *"7"* ]] & [[ $REALvi == "1.4" ]]; then
            echo "-- Nothing to do here"
        elif [[ $3 == *"7"* ]]; then
            echo "-- Please consider upgrading you real version from currently installed $REALvi.x to 1.4.0"
        fi
    else
        echo "-- Real package not detected"
        echo "-- Installing real $1 into default location"
        swipl -g "Os=[interactive(false), url('$2')], pack_install(real, Os), halt" -t 'halt(1)'
    fi
}

# check whether SWI is installed and memorise its version # .\2.\3
if hash swipl 2>/dev/null; then
    SWIPLv=$(swipl -v | sed 's/SWI-Prolog version \([0-9]\)\.\([0-9]\)\.\([0-9]\).*/\1/')
else
    echo "-- SWI-Prolog is not installed!"
    exit 1
fi

# check whether R is installed - version does not matter
if hash R 2>/dev/null; then
    true
else
    echo "-- R is not installed!"
    exit 1
fi

# install real pack depending on the version of SWI-Prolog
# if SWI is in version 6 install real 1.2
if [[ $SWIPLv == *"7"* ]]; then
    REALl='https://github.com/So-Cool/packages-real/releases/download/1.4.0/real-1.4.tgz'
    REALv="1.4.0"
    echo "-- SWI-Prolog $SWIPLv.x.x detected"
    realInstall $REALv $REALl $SWIPLv
# if SWI is in version 7 install real 1.4
elif [[ $SWIPLv == *"6"* ]]; then
    REALl='https://github.com/So-Cool/packages-real/releases/download/1.1.0/real-1.1.0.tgz'
    REALv="1.1.0"
    echo "-- SWI-Prolog $SWIPLv.x.x detected"
    realInstall $REALv $REALl $SWIPLv
# if SWI is in other version tell that it's not supported
else
    echo "-- Your version of SWI-Prolog $SWIPLv.x.x is not supported!"
    exit 1
fi
