#!/bin/bash
set -o errexit

ABSOLUTE_PATH=$(cd ${0%/*} && pwd -P)

APPLICATION_NAME="LockMeNow"
DOWNLOAD_BASE_URL="http://downloads.igrsoft.com/lockmenow/"
RELEASENOTES_BASE_URL="http://igrsoft.com/wp-content/lockmenow/info"

VERSION=$(/usr/libexec/plistbuddy -c Print:CFBundleShortVersionString: "$APPLICATION_NAME".app/Contents/Info.plist)
VERSION_SHORT=$(/usr/libexec/plistbuddy -c Print:CFBundleVersion: "$APPLICATION_NAME".app/Contents/Info.plist)

UNDERSCORE="_"
ARCHIVE_FILENAME="$APPLICATION_NAME$UNDERSCORE$VERSION_SHORT.zip"
DOWNLOAD_URL="$DOWNLOAD_BASE_URL$ARCHIVE_FILENAME"
RELEASENOTES_URL="$RELEASENOTES_BASE_URL$UNDERSCORE$VERSION_SHORT.html"

WD=$PWD
rm -f "$ABSOLUTE_PATH/$ARCHIVE_FILENAME"
ditto -ck --keepParent "$ABSOLUTE_PATH/$APPLICATION_NAME.app" "$ABSOLUTE_PATH/$ARCHIVE_FILENAME"
BUILD=$(git rev-parse HEAD)
SIZE=$(stat -f %z "$ABSOLUTE_PATH/$ARCHIVE_FILENAME")
PUBDATE=$(date +"%a, %d %b %G %T %z")

SIGNATURE=$(ruby "$ABSOLUTE_PATH/sign_update.rb" "$ABSOLUTE_PATH/$ARCHIVE_FILENAME" "$ABSOLUTE_PATH/dsa_priv.pem")

clear

cat <<EOF     
		<item>
			<title>Version $VERSION, Build $BUILD</title>
			<sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
			<sparkle:releaseNotesLink>$RELEASENOTES_URL</sparkle:releaseNotesLink>
			<pubDate>$PUBDATE</pubDate>
			<enclosure url="$DOWNLOAD_URL" sparkle:version="$VERSION_SHORT" length="$SIZE" type="application/octet-stream" sparkle:dsaSignature="$SIGNATURE" />
		</item>
EOF