# system-manage
These are my system management files (mainly bash and C) that I have customised for my own use. I have decided to put them up on internet for the following reasons:

1. For job applications.
2. To keep a record.

I will try to keep updating more routines that I have played in the past. Most of them will need code quality improvements before push so they can make sense to the public.

The first commit consists of two scripts:

1. autoinstall.sh 

This script detects distro and installer. Then it grabs the pre-determined package.list and install the listed packages. Again, it was written for my own use, so 
currently only supports REHL family and Debian.

2. backup.sh

This scripts takes snapshot on the root based on ZFS. I use crontab to invoke this script on pre-set schedule. 

More to come.
