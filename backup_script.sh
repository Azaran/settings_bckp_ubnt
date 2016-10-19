#!/bin/bash
# script works on Ubuntu 16.04 and requires sudo privileges during runtime
DMYHMS=$(date +"%d_%m_%Y_%H_%M_%S")
BACKUP=bkp_settings_"$DMYHMS"

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" 
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# backs up installed packages from DPKG and saves user profile settings
if [[ $1 == "--help" ]] || [ $# -lt 3 ]; then
    echo "	--help - for help message"
    echo "	-b - for user settings backup"
    echo "	-r <file_name> - for user settings to restoration"
fi

if [[ $1 == "-b" ]]; then 
    echo " Backing up the user SETTINGS!"
    mkdir "$BACKUP"
    dpkg --get-selections > "$DIR"/"$BACKUP"/Package.list
    sudo cp -R /etc/apt/sources.list* "$DIR"/"$BACKUP"/
    sudo apt-key exportall > "$DIR"/"$BACKUP"/Repo.keys
    rsync --progress /home/`whoami` "$DIR"/"$BACKUP"/
    zip -r "$BACKUP".zip "$BACKUP" > /dev/null
    if [ ! -d "./backup" ]; then
	mkdir ./backup
    fi
    mv $BACKUP.zip ./backup/
    sudo rm -rf $BACKUP
fi

##  Restoration process
if [[ $1 == "-r" ]]; then
    echo "Restoring the user SETTINGS!"
    if [ -f $2 ]; then
	file=$(basename "$2")
	FOLDER="${file%.*}"
    else
	exit 1
    fi
    echo "$FOLDER"
    tar -xf $2
    rsync --progress "$DIR"/"$FOLDER" /home/`whoami`
    sudo apt-key add ~/Repo.keys
    sudo cp -R ~/sources.list* /etc/apt/
    sudo apt-get update
    sudo apt-get install dselect
    sudo dpkg --set-selections < ~/Package.list
    sudo dselect
fi
