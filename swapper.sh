#NOTICE: jot (used for random file selection) has a distribution issue on OS X 10.10 and below making it less likely to generate a range's min and max values, and is therefore unsecure. For more info, see https://unix.stackexchange.com/questions/140750/generate-random-numbers-in-specific-range



#!/usr/bin/env bash

##############
## SETTINGS ##
##############
f_name="test" #File name
f_ext=".jpg" #File extension
use_hashing=0 #1 is yes


#hash_alg="crc32"  #Fastest
#hash_alg="sha1"   #Slightly outperforms MD5, making it preferable with its also longer digest
hash_alg="sha256"  #Safest - No known collisions (as of 2020)




##########
## START #
##########
####Change to working directory and handle args
cd "$(dirname "$0")"
f="$f_name$f_ext"
OS=`uname -s`
if [ -n "$1" ]; then #if arg is non-zero
	if [ ! -d "$1" ]; then
		echo "Directory does not exist $1"
		exit 1;
	fi

	cd "$1"
fi

if [ ! -f "$f" ]; then
    echo "File $f not found"
    exit 1;
fi

####Command checks (to avoid any errors later on)
if [ "$OS" == "FreeBSD" ] || [ "$OS" == "Darwin" ]; then
    if ! [ "$(command -v jot)" ]; then
        echo "jot utility not found"
        exit 1;
    fi
else
    if ! [ "$(command -v shuf)" ]; then
        echo "shuf utility not found"
        exit 1;
    fi
fi

####Find hash utility and calculate digest for renaming
if [ "$use_hashing" -eq 1 ]; then
    if [ "$(command -v openssl)" ] && [ "$(command -v sed)" ]; then
        digest=$(openssl dgst -"$hash_alg" "$f")
        digest=($(echo "$digest" | sed 's/.*=//'))
    else
        if ! [ -x "$(command -v sed)" ]; then
            echo "Sed utility not found"
        else
            echo "Hashing/digest utility not found"
        fi

        exit 1;
    fi
else
    if ! [ "$(command -v uuid)" ] && ! [ "$(command -v uuidgen)" ]; then
        echo "UUID utility not found"
        exit 1;
    fi


    if [ "$(command -v uuid)" ]; then
        digest=$(uuid)
    elif [ "$(command -v uuidgen)" ]; then
        digest=$(uuidgen)
    else
        echo "Unknown error occurred while finding UUID utilities"
        exit 1;
    fi
fi


####Find files
mv "$f" "$digest$f_ext"
files=(*"$f_ext")
for file  in "${files[@]}"; do
    #echo "File matched: ${files[$i]}" #DEBUG
	i=$((i+1))
done

i=$((i-1)) #Subtract 1 since arrays begin at 0
#echo "File count: $((i+1))" #DEBUG


####Select file to rename
if [ "$OS" == "FreeBSD" ]; then
    select=`jot -r 1 0 $i` #Generate 1 number between 0 and i (total files in directory)
    #echo "File selected (index $i): ${files[select]}" #DEBUG
elif [ "$OS" == "Darwin" ]; then
    select=`jot -r 1 0 $i` #Generate 1 number between 0 and i (total files in directory)
    #echo "File selected (index $i): ${files[select]}" #DEBUG
else
    echo "OS $OS not tested and may have undefined behavior"
	select=`shuf -i 0-$i -n 1` #Generate number between 0 and i (total files in directory), -n meaning "one of"
fi


####Swap files
mv "${files[select]}" "$f"
echo "Done"
