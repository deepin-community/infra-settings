#!/bin/sh
#set -x

# 导入yq命令
command -v curl >/dev/null 2>&1 || { echo >&2 "curl命令未找到，请先安装curl命令"; exit 1; }

#export

# 检查Obs账户配置
if [ -z "$OSCUSER" ]; then
    echo "OBS User missing, exit"
    exit -1
fi

if [ -z "$OSCPASS" ]; then
    echo "OBS Password missing, exit"
    exit -1
fi

if [ -z "$OBSTOKEN" ]; then
    echo "OBS token missing, exit"
    exit -1
fi

# github pr info
if [ -z "$REPO_OWNER" ]; then
    export REPO_OWNER="linuxdeepin"
fi

if [ -z "$REPO_NAME" ]; then
    export REPO_NAME="dde-dock"
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo: "Github token is missing,exit"
    exit -1
fi

if [ -z "$PULL_BASE_SHA" ]; then
    echo: "Github branch sha is missing,exit"
    exit -1
fi

PROJECT_NAME="deepin:Develop:main"
if [ "$REPO_OWNER" = "linuxdeepin" ]; then
    PROJECT_NAME="deepin:Develop:dde"
else
    result=$(curl -u $OSCUSER:$OSCPASS "https://build.deepin.com/source/$PROJECT_NAME/$REPO_NAME/_service"|grep "unknown_package")
    if [ "$result" != "" ]; then
        PROJECT_NAME="deepin:Develop:community"
        echo "Project override to $PROJECT_NAME"
    fi
fi

echo "Triggering src service..."
curl -X POST -H "Authorization: Token $OBSTOKEN" "https://build.deepin.com/trigger/runservice?project=$PROJECT_NAME&package=$REPO_NAME"

PULL_NUMBER=$(curl -H "Accept: application/vnd.github+json" -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/commits/${PULL_BASE_SHA}/pulls |grep "\"number\":" |awk '{print $2}' |awk -F ',' '{print $1}')
if [ "$PULL_NUMBER" != "" ]; then
    echo "Cleaning obs ci project..."
    CI_PROJECT_NAME="$REPO_OWNER:$REPO_NAME:PR-$PULL_NUMBER"
    if [[ "$PULL_HEAD_REF" == "topic-"* ]]; then
        prefix="topic-"
        topic=${PULL_HEAD_REF#$prefix}
        CI_PROJECT_NAME="topics:$topic"
        echo "Remove obs package $REPO_NAME from topic $topic"
        curl -X DELETE -u "$OSCUSER:$OSCPASS" "https://build.deepin.com/source/deepin:CI:$CI_PROJECT_NAME/$REPO_NAME"
    else
        echo "Remove obs project: deepin:CI:$CI_PROJECT_NAME"
        curl -X DELETE -u "$OSCUSER:$OSCPASS" "https://build.deepin.com/source/deepin:CI:$CI_PROJECT_NAME?force=1"
    fi
fi
