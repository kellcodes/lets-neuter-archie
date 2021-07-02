#!/bin/bash

###############################################################################
# Permissions Fix                                                             #
#    This script checks file permissions and ownership and fixes them on Arch.#
#    If you have accidentally chmodded an important directory, this can help. #
#    NOTE:                                                                    #
#        This software is provided as-is and without any warranty or          #
#        guarantee.  USE AT YOUR OWN RISK!                                    #
#                                                                             #
#    AGAIN:                                                                   #
#        THIS PROGRAM MODIFIES THE CORE FILES ON YOUR SYSTEM AND MAY HAVE     #
#        UNINTENDED RESULTS!  MAKE SURE YOU KNOW EXACTLY WHAT IS HAPPENING    #
#        AND HOW TO FIX IT IF YOU SCREW SOMETHING UP!                         #
#                                                                             #
#        I WILL NOT BE LIABLE FOR ANY DAMAGES CAUSED TO YOUR SYSTEM.          #
#        I WOULD ADDITIONALLY RECOMMEND READING THROUGH THIS SCRIPT TO ENSURE #
#        THERE ARE NO BUGS!                                                   #
###############################################################################
#    Copyright (C) 2020  kell-codes                                           #
#                                                                             #
#    This program is free software: you can redistribute it and/or modify     #
#    it under the terms of the GNU General Public License as published by     #
#    the Free Software Foundation, either version 3 of the License, or        #
#    (at your option) any later version.                                      #
#                                                                             #
#    This program is distributed in the hope that it will be useful,          #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of           #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            #
#    GNU General Public License for more details.                             #
#                                                                             #
#    You should have received a copy of the GNU General Public License        #
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.   #
###############################################################################

if ! command -v paccheck &> /dev/null
then
	echo "command 'paccheck' could not be found!"
	echo "Please check that it is installed."
	exit 1
fi
if ! command -v chmod &> /dev/null
then
	echo "Unable to run chmod."
	echo "You will probably have to chroot in to fix this problem."
	exit 1
fi
if ! command -v chown &> /dev/null
then
	echo "unable to run chown."
	echo "You will probably have to chroot in to fix this problem."
	exit 1
fi
if ! command -v chgrp &> /dev/null
then
	echo "unable to run chgrp."
	echo "You will probably have to chroot in to fix this problem."
	exit 1
fi

if [ "$EUID" -ne 0 ]
then
	echo "ERROR: This script must be run as root."
	echo "It hurts, I know."
	echo "If it helps, here's a picture of a panda: "
	echo "        .---.      .---."
	echo "       (     )    (     )"
	echo "      /      ^^^^^^      \\"
	echo "      |    (-)    (-)    |"
	echo "      |        --        |"
	echo "      |       (  )       |"
	echo "      \\       ^^^^       / "
	echo "       ^^^^^^^^^^^^^^^^"
	exit 2
else
	echo "LICENSE AGREEMENT: https://www.gnu.org/licenses/gpl-3.0.en.html"
	echo "Type 'Y' if you accept the terms of the license (GPL3): "
	read LICENSE
	while [ "$LICENSE" != "Y" ]; do 
		echo "LICENSE AGREEMENT: https://www.gnu.org/licenses/gpl-3.0.en.html"
		echo "Type 'Y' if you accept the terms of the license (GPL3): "
		read LICENSE
	done
	echo "WARNING: THIS PROGRAM IS ABOUT TO RUN AS ROOT!"
	echo "THE CHANGES MADE HERE COULD IRREVERSABLY BREAK YOUR SYSTEM!"
	echo "I AM NOT LIABLE FOR ANY ERRORS THAT OCCUR HERE!"
	echo "USE AT YOUR OWN RISK, AND ENSURE YOU HAVE A BACK-UP STRATEGY!"
	echo ""
	echo "READ THIS SCRIPT BEFORE EXECUTING!  FAILURE TO DO SO MAY RESULT IN A BROKEN SYSTEM!"
	echo "IF YOU ARE AWARE OF THE RISKS, TYPE Y: "
	read response
	if [ "$response" == "Y" ] 
	then
		echo "AS YOU WISH, MASTER!"
	else
		echo "(response: $response != Y)"
		echo "OK, I LOVE YOU, BYE-BYE!"
		exit 2
	fi
fi

#Check file modes
echo "Checking File Permissions (chmod): "
paccheck --file-properties --quiet | grep permission > /tmp/permission.tmp

#Check file ownership
echo "Checking File Ownership (chown): "
paccheck --file-properties --quiet | grep UID > /tmp/ownership.tmp

#Check file group
echo "Checking file Group (chgrp): "
paccheck --file-properties --quiet | grep GID > /tmp/groupie.tmp

echo "The files at /tmp/permission.tmp will be modified (type 'y' to continue)"
read response
if [ "$response" == "y" ]
then
	echo "Response: $response == y.  Modifying files..."
	readarray -t permies < /tmp/permission.tmp
	for i in "${permies[@]}"
	do
		FILE=`echo $i | cut -d "'" -f2`
		PERM=`echo $i | cut -d "(" -f2 | cut -d ")" -f1 | grep -Eo '[0-9]+'`
		echo "Running: chmod $PERM $FILE"
		chmod $PERM $FILE
	done
else
	echo "Response: $response != y.  No files were modified."
fi
response="n"

echo "The files at /tmp/ownership.tmp will be modified (type 'y' to continue)"
read response
if [ "$response" == "y" ]
then
	echo "Response: $response == y.  Modifying files..."
	readarray -t ownies < /tmp/ownership.tmp
	for i in "${ownies[@]}"
	do
		FILE=`echo $i | cut -d "'" -f2`
		OWN=`echo $i | cut -d "(" -f2 | cut -d ")" -f1 | cut -d "/" -f1 | grep -Eo '[0-9]+'`
		echo "Running: chown $OWN $FILE"
		chown $OWN $FILE
	done
else
	echo "Response: $response != y.  No files were modified."
fi
response="n"

echo "The files at /tmp/groupie.tmp will be modified (type 'y' to continue)"
read response
if [ "$response" == "y" ]
then
	echo "Response: $response == y.  Modifying files..."
	readarray -t groupies < /tmp/groupie.tmp
	for i in "${groupies[@]}"
	do
		FILE=`echo $i | cut -d "'" -f2`
		OWN=`echo $i | cut -d "(" -f2 | cut -d ")" -f1 | cut -d "/" -f1 | grep -Eo '[0-9]+'`
		echo "Running: chgrp $OWN $FILE"
		chgrp $OWN $FILE
	done
else
	echo "Response: $response != y.  Exiting..."
	exit 0
fi
response="n"

echo "Remove temporary files? (y/n): "
read response
while [ "$response" != "y" ] && [ "$response" != "n" ]
do
	echo "BAD RESPONSE!"
	echo "Remove temporary files? (y/n): "
	read response
done
if [ "$response" == "y" ]
then
	rm /tmp/permission.tmp
	rm /tmp/ownership.tmp
	rm /tmp/groupie.tmp
fi

#The Pantstainer
echo "You should have read the script first!"
echo "bash$> dd if=/dev/null of=/dev/sda count=160 bs=4M"
sleep 10
echo "655360 bytes (66 MB, 64 MiB) copied, 10 s, 6.6 MB/s"

echo "bash: echo: command not found"
