#!/bin/bash
# 1. Change paths for mount and log file
# 2. Create mountcheck file in destination.
# 3. Add to crontab -e (paste the line below, without # in front)
# * * * * *  $HOME/bin/rclone-mount-check.sh >/dev/null 2>&1
# Make script executable with: chmod a+x $HOME/bin/rclone-mount-check.sh

LOGFILE=$HOME"/mounts/rclone-mount-check.log"
RCLONEREMOTE="rcloneRemote:CryptDirectory"
MPOINT=$HOME"/mounts/MPointDirectory"
CHECKFILE="SomeFileToTestForExistance.txt"

if pidof -o %PPID -x "$0"; then
    echo "$(date "+%d.%m.%Y %T") EXIT: Already running." | tee -a "$LOGFILE"
    exit 1
fi

if [[ -f "$MPOINT/$CHECKFILE" ]]; then
    echo "$(date "+%d.%m.%Y %T") INFO: Check successful, $MPOINT mounted." | tee -a "$LOGFILE"
    exit
else
    echo "$(date "+%d.%m.%Y %T") ERROR: $MPOINT not mounted, remount in progress." | tee -a "$LOGFILE"
    # Unmount before remounting
    while mount | grep "on ${MPOINT} type" > /dev/null
    do
        echo "($wi) Unmounting $mount"
        fusermount -uz $MPOINT | tee -a "$LOGFILE"
        cu=$(($cu + 1))
        if [ "$cu" -ge 5 ];then
            echo "$(date "+%d.%m.%Y %T") ERROR: Folder could not be unmounted exit" | tee -a "$LOGFILE"
            exit 1
            break
        fi
        sleep 1
    done
    rclone mount \
		--buffer-size 1G \
		--allow-other \
		--fast-list \
		--dir-cache-time 96h \
		--vfs-cache-poll-interval 12h \
		--vfs-cache-mode writes \
		--size-only \
		--uid 1017 \
		--gid 1017 \
		--timeout 1h \
		--umask 000 \
        $RCLONEREMOTE $MPOINT &

    while ! mount | grep "on ${MPOINT} type" > /dev/null
    do
        echo "($wi) Waiting for mount $mount"
        c=$(($c + 1))
        if [ "$c" -ge 4 ] ; then break ; fi
        sleep 1
    done
    if [[ -f "$MPOINT/$CHECKFILE" ]]; then
        echo "$(date "+%d.%m.%Y %T") INFO: Remount successful." | tee -a "$LOGFILE"
    else
      echo "$(date "+%d.%m.%Y %T") CRITICAL: Remount failed." | tee -a "$LOGFILE"
    fi
fi
exit