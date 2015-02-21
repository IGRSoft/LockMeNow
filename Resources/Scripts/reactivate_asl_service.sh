#!/bin/bash

/bin/launchctl unload /System/Library/LaunchDaemons/com.apple.syslogd.plist
/bin/launchctl load /System/Library/LaunchDaemons/com.apple.syslogd.plist

/usr/sbin/diskutil repairPermissions /
