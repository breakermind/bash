#!/bin/bash

############################################################
# Help                                                     #
############################################################
Help()
{
	# Display Help
	echo "Bash script params."
	echo
	echo "Syntax: scriptTemplate [-h|m|d]"
	echo "options:"
	echo "-h 	Print this Help."
	echo "-m 	Change email address."
	echo "-d 	Change domain hostname."
	echo
}

############################################################
# Main program                                             #
############################################################
# Set variables
_HOST=""
_EMAIL=""

############################################################
# Process the input options                                #
############################################################
# Get the options
while getopts ":m:d:h" option
do
	case $option in
		h) 	Help
			exit;;
		d)
			_HOST=${OPTARG};;
		m)
			_EMAIL=${OPTARG};;
		\?)
			echo "Error: Invalid option"
			exit;;
	esac
done

############################################################
# Script params                                            #
############################################################
# validate
if [ -z "$_HOST" ]; then
	echo "[error] Empty host: $0 -d [host] -m [email]"
	exit
fi

if [ -z "$_EMAIL" ]; then
	echo "[error] Empty email: $0 -d [host] -m [email]"
	exit
fi

############################################################
# Functionality                                            #
############################################################
echo "Hostname: ${_HOST}"
echo "Email: ${_EMAIL}"
