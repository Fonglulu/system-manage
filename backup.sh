#!/usr/bin/bash


function detect_operating_system(){

    OPERATING_SYSTEM_TYPE=$(uname)

    if [ -f /etc/redhat-release ] || [ -f /etc/system-release-cpe ]; then

	echo "REDHEAT"
	return 0

    fi
}




function take_snapshot()

{
    if detect_operating_system = $0; then

	OPERATING_SYSTEM="REDHAT"
	
	DATE=$(date +"%Y%m%d%H%M%S");
	PATH=$(df --output=source /home/${whoami} |tail -n +2)
	BACKUP="backups";


	echo "CREATING NEW SNAPSHOT $PATH@$DATE";

	/sbin/zfs snapshot $PATH@$DATE;
    fi

}


take_snapshot
