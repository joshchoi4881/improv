# Author:       Andreas
# Usage:        ./impv.sh <filename>
# Description:  This shell script compiles and runs a single .impv file

# Path to the LLVM interpreter
LLI="lli"

# Path to the LLVM compiler
LLC="llc"

# Path to the C compiler
CC="cc"

IMPROV="../src/improv.native"

ulimit -t 5

basename=`echo $1 | sed 's/.*\\///
                         s/.impv//'`
reffile=`echo $1 | sed 's/.impv$//'`
basedir="`echo $1 | sed 's/\/[^\/]*$//'`/."

# lastSeen=""

Check() {
    if [ $? -ne 0 ]; then
        if [[ "$basename" == *"test-"* ]]; then
            echo "FAILED"
            exit 1
        fi
        if [[ "$basename" == *"fail"* ]]; then
            echo "Failed but that was the plan"
            exit 1
        fi
    fi
}


echo "$IMPROV $1 > $basename.ll"
$IMPROV $1 > $basename.ll
Check

echo "llc -relocation-model=pic $basename.ll > $basename.s"
llc -relocation-model=pic $basename.ll > $basename.s
Check

echo "cc -o $basename.exe $basename.s"
cc -o $basename.exe $basename.s
Check


./$basename.exe
Check
