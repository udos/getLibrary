#!/bin/bash

# SCRIPT: getLibrary.sh
# AUTHOR: Udo Schochtert
# E-MAIL: u.schochtert@gmail.com
#
# PLATFORM: Linux
#           Mac
#
# PURPOSE: Script shell to automatically download, extract & symlink a specific version of libraries like ZF, doctrine, etc.
#          Supported libraries:
#            + Zend Framework
#            + Doctrine 2
#
# IMPORTANT!!!
# Make sure that the directory from which the script is executed is writable for the user which is executing the script! Otherwise the download will fail because writing permissions are missing.
#
# Target library path:
#   /usr/local/lib/<library>/stable/
#
# USAGE:
#   ./getLibrary.sh <library> <version>
#   <library>
#     zf  - Zend Framework
#     doc - Doctrine 2
#   <version>
#     check the website of the library for the available versions

###############################
#  	  Variables           #
###############################

### PATHS ###
# default library path
PATHBASE="/usr/local/lib/"

### OTHER ###
# supported libs variable (used in error messages)
LIBSSUPPORTED="Zend Framework (zf), Doctrine2 (doc)"
SCRIPTNAME="getLibrary"

### MESSAGES ###
MESSAGE="$SCRIPTNAME - MESSAGE"
WARNING="$SCRIPTNAME - WARNING"
ERROR="$SCRIPTNAME - ERROR"

###############################
#         Functions           #
###############################

#
# Purpose: Enable debug mode
#
function fctDebug(){
  echo "***** Debug Mode Enabled *****"
  echo "Archive: $ARCHIVE"
  echo "Source: $SOURCE"
  echo $PATHDEST
  echo "Working Dir: " & pwd
  
  echo "***** Debug Mode Disabled (Script stopped) *****"
  exit 0
}

#
# Purpose: Transform string to lower
#
function fctString2Lower(){
  
  # Check if parameter #1 is zero length -> no parameter passed
  if [ -z "$1" ]
  then
    echo "$ERROR: No parameter passed. Stopping script..."
    exit 1
  fi
  
  # Check if parameter #2 was passed -> not allowd -> only parameter #1 allowd
  if [ "$2" ]
  then
    echo "$ERROR: Only 1 parameter allowed (Example: fctString2Lower $1). Stopping script..."
    exit 1
  fi
  
  # convert string to lower case
  echo $1 | tr [:upper:] [:lower:]
  exit 0
}

#################################
# Main Script Logic Starts Here #
#################################

# detect platform
PLATFORM="other"
OS=$(uname)

# determine OS
case $OS in
  Linux)
    # library name
    PLATFORM="linux"
  ;;
  Darwin)
    # library name
    PLATFORM="darwin"
  ;;
  *)
    # unknown OS
    echo "$ERROR: Unknown Operating System. Stopping script..."
    exit 1
esac

# check if the user (which launched this script) belongs to an administrator group (e.g. root, admin, etc.)
# notes:
#   admin groups are OS dependent
#   '>/dev/null' redirects the output so user do not see it
case $OS in
  Linux)
    if ! groups | grep -co 'root' >/dev/null
    then
      # user does not belong to group root -> stop script
      echo "$ERROR: You do not belong to group 'root'. Please log in as root and relaunch script. Stopping script..."
      exit 1
    fi
  ;;
  Darwin)
    if ! groups | grep -co 'admin' >/dev/null
    then
      # user does not belong to group admin -> stop script
      echo "$ERROR: You do not belong to group 'admin'. Please log in as root and relaunch script. Stopping script..."
      exit 1
    fi
  ;;
esac

# check if default library path exists
if [ ! -d $PATHBASE ]
then
  # lib path does not exist
  echo "$ERROR: Directory $PATHBASE does not exist. Stopping script..."
  echo "  Please create the directory path manually."
  echo "  Restart the script."
  exit 1
fi


# check if 1st argument was passed
if [ -z $1 ]
then
  echo "$ERROR: Please provide the library name (e.g. $LIBSSUPPORTED). Stopping script..."
  exit 1
else
  LIB=$(fctString2Lower $1)
fi


# verify user requested library
case $LIB in
  zend | zf)
    # library name
    LIB="ZF"
  ;;
  doctrine | doctrine2 | doc | doc2)
    # library name
    LIB="Doctrine2"
  ;;
  *)
    echo "$ERROR: requested library '$LIB' not supported. Only the libraries $LIBSSUPPORTED are supported at the moment. Stopping script..."
    exit 1
esac

# check if 2nd argument was passed
if [ -z $2 ]
then
  echo "$ERROR: Please provide the version number. Stopping script..."
  exit 1
else
  # library version (2nd parameter passed)
  VERSION=$2
fi

# final path in function of the requested library
# ToDo: write function fctSetPath to set the path. Consider alpha, beta, stable versions.
PATHDEST="$PATHBASE$LIB/stable/"

# check if the path exists
if [ ! -d $PATHDEST ]
then
  # path does not exist
  echo "$MESSAGE: Directory $PATHDEST does not exist. Creating directory..."
  mkdir -pv $PATHDEST
fi

# change directory (to use directories relative to this dir path)
cd $PATHDEST
# debugging: uncomment the following line if you are unsure in which directory the script is...
#fctDebug

# check if version directory already exists
if [ -d $VERSION ]
then
  echo "$WARNING: The version directory $VERSION already exists."

  #define options as array
  declare -a options

  #set first empty position with new value
  options[${#options[*]}]="remove directory $VERSION";
  options[${#options[*]}]="quit";
  
  #expand to quoted elements:
  select opt in "${options[@]}"; do
    case ${opt} in
      ${options[0]})
        CURRENT_DIR=$(pwd)
#echo $CURRENT_DIR
        rm -r $VERSION
        echo "$MESSAGE: Directory $CURRENT_DIR/$VERSION (including subdirectories) deleted."
        break
        ;;
      (quit)
        echo "$MESSAGE: Stopping script."
        exit 1
        ;;
      (*)
        echo "$WARNING: You entered a non-valid option ${opt}"; ;;
    esac;
  done

fi

case $LIB in
  ZF)
    # archive name
    ARCHIVENAME="ZendFramework-$VERSION"
    # archive extension
    ARCHIVEEXT=".tar.gz"
    # archive full (name & extension)
    ARCHIVE=$ARCHIVENAME$ARCHIVEEXT
    # source
    SOURCE="http://framework.zend.com/releases/ZendFramework-$VERSION/$ARCHIVE"
  ;;
  Doctrine2)
    ARCHIVENAME="DoctrineORM-$VERSION-full"
    ARCHIVEEXT=".tar.gz"
    ARCHIVE=$ARCHIVENAME$ARCHIVEEXT
    SOURCE="http://www.doctrine-project.org/downloads/$ARCHIVE"
  ;;
esac

# check if archive already exists
if [ -e "$ARCHIVE" ]
then
  echo "$WARNING: The archive $ARCHIVE already exists."
  
  #define options as array
  declare -a options
  
  #set first empty position with new value
  options[${#options[*]}]="remove archive";
  options[${#options[*]}]="quit";
  
  #expand to quoted elements:
  select opt in "${options[@]}"; do
    case ${opt} in
      ${options[0]})
        rm $ARCHIVE
        echo "$MESSAGE: Archive $ARCHIVE deleted."
        break
        ;;
      (quit)
        echo "$MESSAGE: Stopping script."
        exit 1
        ;;
      (*)
        echo "$WARNING: You entered a non-valid option ${opt}"; ;;
    esac;
  done

else
  echo "$MESSAGE: Download archive from: $SOURCE"
  # download archive
  wget $SOURCE
  # $? is <> 0 if previous command produced an error
  if [ "$?" -ne "0" ]
  then
    echo "$ERROR (wget): The url $SOURCE produced an error. Probably the submitted parameter $2 (library version) is not correct."
    exit 1
  fi
fi

#untar the archive
tar -xzf $ARCHIVE
# remove archive
rm $ARCHIVE
# rename untared directory
case $LIB in
  ZF)
    mv $ARCHIVENAME $VERSION
  ;;
  Doctrine2)
    mv doctrine-orm $VERSION
    # move Symfony folder
    mv $VERSION/Doctrine/Symfony $VERSION/
  ;;
esac

# ask user if he wants to change the symbolic link of the latest stable to this version
cat << EOF
Do you want to set the symbolic link of the lastest stable to this version? [y/n]
EOF

read USERINPUT

# transform user input to lowercase
#USERINPUT='echo $USERINPUT | tr A-Z a-z'
#echo "$USERINPUT"

# symlink name
SYMLINKNAME="latest"

# check user input
case $USERINPUT in
  yes | y | YES | Y| Yes)
    # check if symbolic link "latest_test" exists
    if [ -L $SYMLINKNAME ]
    then
      # remove symlink
      rm $SYMLINKNAME
    fi
    
    # set symlink
    ln -s $VERSION $SYMLINKNAME
  ;;
esac

echo "$MESSAGE: Script $0 terminated successfully. :)"
exit 0
# end of script
