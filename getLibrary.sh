#!/bin/bash

# SCRIPT: getLibrary.sh
# AUTHOR: Udo Schochtert
# E-MAIL: u.schochtert@gmail.com
# DATE:   15.10.2009
# REV:    not tracked...
#
# PLATFORM: Linux

# PURPOSE: Script shell to automatically download, extract & symlink a specific version of libraries like ZF, doctrine, etc.
#          Supported libraries:
#            + Zend Framework
#            + Doctrine

# IMPORTANT!!!
# the library directory has to be writable for the user which is executing this script! Otherwise the download will fail because writing permissions are missing.

# Default library path:
#   /usr/local/lib/<library>/stable/

# USAGE:
#   ./getLibrary.sh <library> <version>
#   <library>
#     zf  - Zend Framework
#     doc - Doctrine
#   <version>
#     check the website of the library for the available versions

###############################
#          FUNCTIONS          #
###############################
function fctDebug {
  echo "***** Debug Mode Enabled *****"
  echo "Archive: $ARCHIVE"
  echo "Source: $SOURCE"
  echo $PATHDEST
  echo "Working Dir: " & pwd
  
  echo "***** Debug Mode Disabled (Script stopped) *****"
  exit 0
}

###############################
#          MAIN               #
###############################
# check if the user (which launched this script) belongs to group root
# note: '>/dev/null' redirects the output so user do not see it
if ! groups | grep -co 'root' >/dev/null
then
  # user does not belong to group root -> stop script
  echo "ERROR: You do not belong to group 'root'. Please log in as root and relaunch script. Stopping script..."
  exit 1
fi

# default library path
PATHBASE="/usr/local/lib/"

# check if default library path exists
if [ ! -d $PATHBASE ]
then
  # lib path does not exist
  echo "ERROR: Directory $PATHBASE does not exist. Stopping script..."
  echo "  Please create the directory path manually."
  echo "  Restart the script."
  exit 1
fi

# supported libs variable (for error messages)
LIBSSUPPORTED="ZF, doctrine"

# check if 1st argument was passed
if [ -z $1 ]
then
  echo "ERROR: Please provide the library name (e.g. $LIBSSUPPORTED). Stopping script..."
  exit 1
fi

# verify user requested library
case $1 in
  ZF | zf)
    # library name
    LIB="ZF"
  ;;
  doctrine | doc | Doctrine)
    # library name
    LIB="Doctrine"
  ;;
  *)
    echo "ERROR: requested library '$1' not supported. Only the libraries $LIBSSUPPORTED are supported at the moment. Stopping script..."
    exit 1
esac


# final path in function of the requested library
PATHDEST="$PATHBASE$LIB/stable/"


# check if the path exists
if [ ! -d $PATHDEST ]
then
  # path does not exist
  echo "NOTICE: Directory $PATHDEST does not exist. Creating directory..."
  mkdir -pv $PATHDEST
fi



# check if 2nd argument was passed
if [ -z $2 ]
then
  echo "ERROR: Please provide the version number. Stopping script..."
  exit 1
else
  # library version (2nd parameter passed)
  VERSION=$2
fi

# change directory (to use directories relative to this dir path)
cd $PATHDEST
# debugging: uncomment the following line if you are unsure in which directory the script is...
#fctDebug

# check if version directory already exists
if [ -d $VERSION ]
then
  echo "WARNING: The version directory $VERSION already exists."

  #define options as array
  declare -a options

  #set first empty position with new value
  options[${#options[*]}]="remove directory $VERSION";
  options[${#options[*]}]="quit";
  
  #expand to quoted elements:
  select opt in "${options[@]}"; do
    case ${opt} in
      ${options[0]})
        rm -r $VERSION
        echo "Directory $VERSION deleted."
        break
        ;;
      (quit)
        echo "Stopping script."
        exit 1
        ;;
      (*)
        echo "You entered a non-valid option ${opt}"; ;;
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
  Doctrine)
    ARCHIVENAME="Doctrine-$VERSION"
    ARCHIVEEXT=".tgz"
    ARCHIVE=$ARCHIVENAME$ARCHIVEEXT
    SOURCE="http://www.doctrine-project.org/downloads/$ARCHIVE"
  ;;
esac

# check if archive already exists
if [ -e "$ARCHIVE" ]
then
  echo "WARNING: The archive $ARCHIVE already exists."
  
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
        echo "Archive $ARCHIVE deleted."
        break
        ;;
      (quit)
        echo "Stopping script."
        exit 1
        ;;
      (*)
        echo "You entered a non-valid option ${opt}"; ;;
    esac;
  done

else
  # download archive
  wget $SOURCE
  # $? is <> 0 if previous command produced an error
  if [ "$?" -ne "0" ]
  then
    echo "ERROR (wget): The url $SOURCE produced an error. Probably the submitted parameter $2 is not correct."
    exit 1
  fi
fi

#untar the archive
tar -xvzf $ARCHIVE
# remove archive
rm $ARCHIVE
# rename untared directory
mv $ARCHIVENAME $VERSION

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

echo "MESSAGE: Script $0 terminated successfully. :)"
exit 0
# end of script
