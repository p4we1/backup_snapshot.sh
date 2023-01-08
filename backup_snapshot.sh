# ======================================================
# File name     =   backup_snapshot.sh
# version       =   1.0
# Description   =   Snapshot directory
# 
# ======================================================

#!/bin/bash
set -u
# Variables ============================================

# Name of backup
# Name writed to log file
name="System name"

# logfile - log with script output
lf=/var/log/backup/backup.log

# synclog - log writed with rsync output
synclog=/var/log/backup/backup_sync.log

# srcdata - source folder to snapshot
srcdata=

# destdata - destination folder to store snapshoted data
# use remote storage mounted to local folder
# descdata=/backup/smartsite/daily.00
destdata=

# count_backup - Days to store snapshoted data
# set value of days to store snapshot
# default setting 14 days - set as you wish
count_backup=14

# EXCLUDE files and folder from snapshot
# *.bak
# */temp/*
# Variable not used - use file excluded-list.txt - one line one exclude
exclude=''
# Variables =========================================END

# Function =============================================
function convert1.01 {
 inputNo=$1
 printf -v inputNo "%02d" $inputNo ; echo $inputNo
}

function dt {
    date +%Y-%m-%d-%H:%M:%S
}

# not used, add excluded files and dirs by exclude-list.txt
function exclude {
 all_exclude=""
 for exclude_part in $exclude
 do
  if [ -n $exclude_part ]; then 
  all_exclude+="--exclude '${exclude_part}' " 
  fi
 done;
echo $all_exclude
}
# Function ==========================================END

# Check if variable are set in script. if not exit =====

if [ -z "${srcdata}" ] || [ -z "${destdata}" ];
then
    echo "Please set both srcdata and destdata variables"
    exit 0
fi

if [ ! -d "$srcdata" ];
then
 echo $"Directory srcdata not exist"
 exit 0
fi

if [ ! -d "$destdata" ];
then
 echo $"Directory destdata not exist"
 exit 0
fi



# Check  ============================================END



# Start ================================================
destdataD="${destdata}/daily.00"

echo $"==============================~backup_snapshot.sh~===================" >> $lf
echo $"= $name Snapshot Script" >> $lf
echo $"==============================~backup_snapshot.sh~===================" >> $lf

echo $"[FILE-ROTATE]:`dt`: ROTATE START" >> $lf
if [ -d "$destdata/daily.`convert1.01 $((count_backup-1))`" ] ; then
 echo $"[FILE-SYNC]:`dt`: Delete oldest day" >> $lf
 rm -rf "$destdata/daily.`convert1.01 $((count_backup-1))`" ;
 echo $"[FILE-ROTATE]:`dt`: Removed: daily.$((count_backup-1))" >> $lf
fi ;

echo $"[FILE-ROTATE]:`dt` START moving data" >> $lf
for ((day_before=1;day_before<=$count_backup-2;++day_before)); do
 daily=`convert1.01 $((count_backup-day_before))`
 daily_minus=`convert1.01 $((count_backup-day_before-1))`
 if [ -d "$destdata/daily.$daily_minus" ] ; then
 echo $"[FILE-ROTATE]:`dt`: - start move daily.$daily_minus to daily.$daily" >> $lf
 mv "$destdata/daily.$daily_minus" "$destdata/daily.$daily"
 echo $"[FILE-ROTATE]:`dt`: daily.$daily_minus to daily.$daily movied" >> $lf
 fi
done
echo $"[FILE-ROTATE]:`dt`: Data > 01 - moved" >> $lf
if [ -d "$destdata/daily.00" ] ; then
echo $"[FILE-ROTATE]:`dt`: Start cp -al daily.00 to daily.01" >> $lf
cp -al "$destdata/daily.00" "$destdata/daily.01"
echo $"[FILE-ROTATE]:`dt`: daily.00 to daily.01 - copied" >> $lf
fi;
echo $"[FILE-ROTATE]:`dt`: All data moved" >> $lf


echo $"[FILE-SYNC]:`dt`: FILE SYNC" >>$lf
srcdatadirsize=`du -hs $srcdata`
echo $"[FILE-SYNC]:`dt`: Directory size: $srcdatadirsize" >>$lf
echo $"[FILE-SYNC]:`dt`: SYNC START" >> $lf
# rsync -vah --delete --stats --log-file="$synclog" --exclude '*/temp/*' $srcdata $destdata >> $synclog
#rsync -vah --delete --stats --log-file="$synclog" `exclude` $srcdata $destdataD >> $synclog
rsync -vah --delete --stats --log-file="$synclog" --exclude-from='exclude-list.txt' $srcdata $destdataD >> $synclog
#rsync -vah --delete --stats --log-file="$synclog" $srcdata $destdataD  >> $synclog
#destdirsize=`du -hs $destdata/daily.00`
destdirsize=`du -hs $destdataD`
echo $"[FILE-SYNC]:`dt`: SYNC STOP" >> $lf
echo $"[FILE-SYNC]:FOLDER SIZE: $destdirsize" >> $lf


echo $"[FILE-BAK]:`dt`: $name SNAPSHOT SCRIPT STOP" >> $lf
echo $"------------------------------~backup_snapshot.sh--------------------" >> $lf
touch $destdata/daily.00
# STOP = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =