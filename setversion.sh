#!/bin/sh

set -u

usage ()
{
    cat >&2 << EOF
Usage: ${0##*/} New_Marketing_Version

Bumps the bundle version, and sets the new marketing version. Then adds a commit to Git.

EOF
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

MARKETING_VERSION=$1

agvtool bump -all
NEW_VERSION=`agvtool what-version -terse`
agvtool new-marketing-version ${MARKETING_VERSION}
git add SimDeploy.xcodeproj/project.pbxproj SimDeploy/SimDeploy-Info.plist
git commit -m "Bump bundle version to: ${NEW_VERSION}, marketing version to: ${MARKETING_VERSION}"