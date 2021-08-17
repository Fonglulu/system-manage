#!/bin/bash

#autoinstall.sh
# A file named by package.list is required to present in the BASE directory.
# The current version supports Debian and RHEL family
# Run with sudo privilege


# Change base to youe $HOME 
BASE=/home/fredf
DATETIME=$(date "+%Y-%m-%d-%H-%M-%S")
MY_INSTALL="install"


################################################################################
# Echo functions print progress
################################################################################



function echo_equals() {
	COUNTER=0
	while [  $COUNTER -lt "$1" ]; do
		printf '='
		(( COUNTER=COUNTER+1 ))
	done
}

# echo_title() outputs a title padded by =, in yellow.
function echo_title() {
	TITLE=$1
	NCOLS=$(tput cols)
	NEQUALS=$(((NCOLS-${#TITLE})/2-1))
	tput setaf 3 0 0 # 3 = yellow
	echo_equals "$NEQUALS"
	printf " %s " "$TITLE"
	echo_equals "$NEQUALS"
	tput sgr0  # reset terminal
	echo
}

# echo_step() outputs a step collored in cyan, without outputing a newline.
function echo_step() {
	tput setaf 6 0 0 # 6 = cyan
	echo -n "$1"
	tput sgr0  # reset terminal
}

# echo_step_info() outputs additional step info in cyan, without a newline.
function echo_step_info() {
	tput setaf 6 0 0 # 6 = cyan
	echo -n " ($1)"
	tput sgr0  # reset terminal
}

# echo_right() outputs a string at the rightmost side of the screen.
function echo_right() {
	TEXT=$1
	echo
	tput cuu1
	tput cuf "$(tput cols)"
	tput cub ${#TEXT}
	echo "$TEXT"
}

# echo_failure() outputs [ FAILED ] in red, at the rightmost side of the screen.
function echo_failure() {
	tput setaf 1 0 0 # 1 = red
	echo_right "[ FAILED ]"
	tput sgr0  # reset terminal
}

# echo_success() outputs [ OK ] in green, at the rightmost side of the screen.
function echo_success() {
	tput setaf 2 0 0 # 2 = green
	echo_right "[ OK ]"
	tput sgr0  # reset terminal
}

# echo_warning() outputs a message and [ WARNING ] in yellow, at the rightmost side of the screen.
function echo_warning() {
	tput setaf 3 0 0 # 3 = yellow
	echo_right "[ WARNING ]"
	tput sgr0  # reset terminal
	echo "    ($1)"
}

# exit_with_message() outputs and logs a message before exiting the script.
function exit_with_message() {
	echo
	echo "$1"
	echo
	debug_variables
	echo
	exit 1
}

# exit_with_failure() calls echo_failure() and exit_with_message().
function exit_with_failure() {
	echo_failure
	exit_with_message "FAILURE: $1" 1
}

# echo_step() outputs a step collored in cyan, without outputing a newline.
function echo_step() {
	tput setaf 6 0 0 # 6 = cyan
	echo -n "$1"
	tput sgr0  # reset terminal
}



# command_exists() tells if a given command exists.
function command_exists() {
	command -v "$1" >/dev/null 2>&1
}


# check_if_root_or_die() verifies if the script is being run as root and exits
# otherwise (i.e. die).
function check_if_root_or_die() {
	echo_step "Checking installation privileges"

	SCRIPT_UID=$(id -u)
	if [ "$SCRIPT_UID" != 0 ]; then
		exit_with_failure "$ME should be run as root"
	fi
	echo_success
}

# check_bash() check if current shell is bash
function check_bash() {
	echo_step "Checking if current shell is bash"
	if [[ "$0" == *"bash" ]]; then
		exit_with_failure "Failed, your current shell is $0"
	fi
	echo_success
}

# use the given PACKAGES_LIST or set it to a random file in /tmp
function set_packages_list() {

	if [[ ! $PACKAGES_LIST ]]; then
		# Termux
		if [ -d "$PREFIX/tmp" ]; then
			export PACKAGES_LIST="$PREFIX/tmp/packages_$DATETIME.list"
		# Normal
		else
			export PACKAGES_LIST="/tmp/packages_$DATETIME.list"
		fi
	fi
	if [ -e "$PACKAGES_LIST" ]; then
		exit_with_failure "$PACKAGES_LIST already exists"
	fi
}


function detect_operating_system() {
	echo_step "Detecting operating system"
	# Within the bash shell, the environment variable OSTYPE contains a value similar (but not identical) to the value of uname (-o)
	OPERATING_SYSTEM_TYPE=$(uname)
	export OPERATING_SYSTEM_TYPE
	if [ -f /etc/debian_version ]; then
		echo_step_info "Debian/Ubuntu"
		OPERATING_SYSTEM="DEBIAN"

	elif [ -f /etc/redhat-release ] || [ -f /etc/system-release-cpe ]; then
		echo_step_info "Red Hat / Fedora / CentOS"
		OPERATING_SYSTEM="REDHAT"

	fi
	echo_success
	export OPERATING_SYSTEM
}


# detect_installer() obtains the operating system package management software and exits if it's not installed
function detect_installer() {
	echo_step "Checking installation tools"
	case $OPERATING_SYSTEM in
	
		DEBIAN)
			if command_exists apt-get; then
		
				export MY_INSTALLER="apt-get"
				export MY_INSTALL="-qq install"
			else
				exit_with_failure "Command 'apt-get' not found"
			fi
			;;
		REDHAT)
			# https://fedoraproject.org/wiki/Dnf
		    if command_exists dnf; then
			#	echo -e "\ndnf found" >>"$INSTALL_LOG"
			export MY_INSTALLER="dnf"
			export MY_INSTALL="-y install"
			# https://fedoraproject.org/wiki/Yum
			# As of Fedora 22, yum has been replaced with dnf.
		    elif command_exists yum; then
			#	echo -e "\nyum found" >>"$INSTALL_LOG"
				export MY_INSTALLER="yum"
				export MY_INSTALL="-y install"
		    else
			exit_with_failure "Either 'dnf' or 'yum' are needed"
			fi
			;;

	esac
	echo_success
}


function build_script() {

    INPUT_ARRAY_NAME=("$@")
    ((last_idx=${#INPUT_ARRAY_NAME[@]} - 1))
    OUTPUT_NAME=${INPUT_ARRAY_NAME[last_idx]}  
    unset "INPUT_ARRAY_NAME[last_idx]"
	

    echo '#/bin/bash' > "$OUTPUT_NAME"
	

    for INPUT_NAME in "${INPUT_ARRAY_NAME[@]}"; do
		
	
	echo -e "\n\n#$INPUT_NAME\n" >> "$OUTPUT_NAME"
	if [ -f "$INPUT_NAME" ]; then
	
	    cat "$INPUT_NAME" >> "$OUTPUT_NAME"
	    if [ "$?" -ne 0 ]; then
		exit_with_failure "Failed to append $INPUT_NAME to $OUTPUT_NAME"
	    fi
	    echo >> "$INPUT_NAME"
	fi
    done


   
    echo_success
}




debug_variables() {
	echo "USERNAME: $USERNAME"
	echo "SHELL: $SHELL"
	echo "BASH_VERSION: $BASH_VERSION"
	echo "BASE: $BASE"
	echo "OPERATING_SYSTEM: $OPERATING_SYSTEM"
	echo "OPERATING_SYSTEM_TYPE: $OPERATING_SYSTEM_TYPE"
	echo "MY_INSTALLER: $MY_INSTALLER"
	echo "PACKAGES_LIST: $PACKAGES_LIST"
	echo "SUDO_USER: $SUDO_USER"
}




#####################################################
# Main
####################################################

detect_operating_system
detect_installer
check_if_root_or_die

# Set script scources
PACKAGE_SOURCES=(
    "$BASE/package.list"
)


set_packages_list
# Create a list of packages to install
build_script "${PACKAGE_SOURCES[@]}" "$PACKAGES_LIST"

#debug_variables

echo_title " INSTALL Good Luck :) "
if [ -f "$PACKAGES_LIST" ]; then
    echo_step "Install packages"; echo
	# IFS='' (or IFS=) prevents leading/trailing whitespace from being trimmed.
	# -r prevents backslash escapes from being interpreted.
	# || [[ -n $line ]] prevents the last line from being ignored if it doesn't end with a \n (since read returns a non-zero exit code when it encounters EOF).
	while IFS='' read -r PACKAGE || [[ -n "$PACKAGE" ]]; do
	    if [[ "$PACKAGE" == [a-z]* ]] || [[ "$PACKAGE" == [A-Z]* ]]; then
		echo_step "  $PACKAGE"; echo
              
		$MY_INSTALLER $MY_INSTALL "$PACKAGE" 
		
		if [ "$?" -ne 0 ]; then
		    echo_warning "Failed to install, will attempt to continue"
		else
		    echo_success
		fi
	    fi
	done < "$PACKAGES_LIST"
else
	exit_with_failure "'$PACKAGES_LIST' not found."
fi

echo_title "Done :)"
