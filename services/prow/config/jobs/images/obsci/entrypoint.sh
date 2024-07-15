#!/bin/sh
#set -x

# 导入yq命令
command -v yq >/dev/null 2>&1 || { echo >&2 "yq命令未找到，请先安装yq命令"; exit 1; }
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

if [ -z "$OBS_HOST" ]; then
    echo "OBS Host missing, exit"
    exit -1
fi

# 定义YAML文件路径
if [ -z "$CONFIG_YAML_FILE" ]; then
    yaml_file="test.yml"
else
    yaml_file="$CONFIG_YAML_FILE"
fi

if [ -z "$REPO_OWNER" ]; then
    export REPO_OWNER="linuxdeepin"
fi

if [ -z "$REPO_NAME" ]; then
    export REPO_NAME="dtk"
fi

if [ -z "$PULL_NUMBER" ]; then
    export PULL_NUMBER="1"
fi

if [ -z "$PULL_PULL_SHA" ]; then
    export PULL_PULL_SHA="test1234"
fi

if [ -z "$PULL_HEAD_REF" ]; then
    export PULL_HEAD_REF="master"
fi

export full_repo_name="$REPO_OWNER/$REPO_NAME"

# 获取配置
echo "Getting settings..."
excluded=$(yq -e '.obscijobs' $yaml_file | yq --arg owner $REPO_OWNER '.[] as $repos | select($repos.repos[] == $owner) | $repos.excluderepos[]' |grep $full_repo_name)
if [  -n "${excluded}" ]; then
    echo "$full_repo_name obs ci config excluded, skip and exit"
    exit 0
fi

projectconfig=$(yq -e '.obscijobs' $yaml_file | yq --arg repo $full_repo_name '.[] as $repos | select($repos.repos[] == $repo) | $repos.project_config')
if [ -z "$projectconfig" ]; then
    projectconfig=$(yq -e '.obscijobs' $yaml_file | yq --arg repo $REPO_OWNER '.[] as $repos | select($repos.repos[] == $repo) | $repos.project_config')
    echo "$full_repo_name obs ci project config isn't existed, using ${REPO_OWNER}'s config"
    # exit 0
fi

if [ -z "$projectconfig" ]; then
    echo "$REPO_OWNER obs ci project config isn't existed, using ${REPO_OWNER}'s config "
    # exit 0
fi
#echo "projectconfig: $projectconfig"

metaconfig=$(yq -e '.obscijobs' $yaml_file | yq --arg repo $full_repo_name '.[] as $repos | select($repos.repos[] == $repo) | $repos.project_meta_tpl')
if [ -z "$metaconfig" ]; then
    metaconfig=$(yq -e '.obscijobs' $yaml_file | yq --arg repo $REPO_OWNER '.[] as $repos | select($repos.repos[] == $repo) | $repos.project_meta_tpl')
    echo "$full_repo_name obs ci meta config isn't existed, using ${REPO_OWNER}'s config"
    # exit 0
fi

if [ -z "$metaconfig" ]; then
    echo "$REPO_OWNER obs ci meta config isn't existed, skip and exit"
    exit -1
fi
#echo "metaconfig: $metaconfig"

packageconfig=$(yq -e '.obscijobs' $yaml_file | yq --arg repo $full_repo_name '.[] as $repos | select($repos.repos[] == $repo) | $repos.package_meta_tpl')
if [ -z "$packageconfig" ]; then
    packageconfig=$(yq -e '.obscijobs' $yaml_file | yq --arg repo $REPO_OWNER '.[] as $repos | select($repos.repos[] == $repo) | $repos.package_meta_tpl')
    echo "$full_repo_name obs ci package config isn't existed, using ${REPO_OWNER}'s config"
    # exit 0
fi

if [ -z "$packageconfig" ]; then
    echo "$REPO_OWNER obs ci package config isn't existed, skip and exit"
    exit -1
fi
#echo "packageconfig: $packageconfig"

brconfig=$(yq -e '.obscijobs' $yaml_file | yq --arg repo $full_repo_name '.[] as $repos | select($repos.repos[] == $repo) | $repos.project_br_tpl')
if [ -z "$brconfig" ]; then
    brconfig=$(yq -e '.obscijobs' $yaml_file | yq --arg repo $REPO_OWNER '.[] as $repos | select($repos.repos[] == $repo) | $repos.project_br_tpl')
    echo "$full_repo_name obs ci _branch_request config isn't existed, using ${REPO_OWNER}'s config"
    # exit 0
fi

if [ -z "$brconfig" ]; then
    echo "$REPO_OWNER obs ci _branch_request config isn't existed, skip and exit"
    exit -1
fi
#echo "brconfig: $brconfig"

serviceconfig=$(yq -e '.obscijobs' $yaml_file | yq --arg repo $full_repo_name '.[] as $repos | select($repos.repos[] == $repo) | $repos.project_service_tpl')
if [ -z "$serviceconfig" ]; then
    serviceconfig=$(yq -e '.obscijobs' $yaml_file | yq --arg repo $REPO_OWNER '.[] as $repos | select($repos.repos[] == $repo) | $repos.project_service_tpl')
    echo "$full_repo_name obs ci service config isn't existed, using ${REPO_OWNER}'s config"
    # exit 0
fi

if [ -z "$serviceconfig" ]; then
    echo "$REPO_OWNER obs ci service config isn't existed, skip and exit"
    exit -1
fi
#echo "serviceconfig: $serviceconfig"

buildscript=$(yq -e '.obscijobs' $yaml_file | yq --arg repo $full_repo_name '.[] as $repos | select($repos.repos[] == $repo) | $repos.build_script')
if [ -z "$buildscript" ]; then
    buildscript=$(yq -e '.obscijobs' $yaml_file | yq --arg repo $REPO_OWNER '.[] as $repos | select($repos.repos[] == $repo) | $repos.build_script')
    echo "$full_repo_name obs ci build script config isn't existed, using ${REPO_OWNER}'s config"
fi

PROJECT_NAME="$REPO_OWNER:$REPO_NAME:PR-$PULL_NUMBER"
if [[ "$PULL_HEAD_REF" == "topic-"* ]]; then
    prefix="topic-"
    topic=${PULL_HEAD_REF#$prefix}
    echo "Add to topic to $topic"
    PROJECT_NAME="topics:$topic"
fi

metaconfig=${metaconfig#\"}
echo -e ${metaconfig%\"} | sed 's/\\"/"/g' > meta.xml
result=$(curl -u $OSCUSER:$OSCPASS "$OBS_HOST/source/deepin:CI:$PROJECT_NAME/_meta"|grep "unknown_project")
if [ "$result" != "" ];then
    echo "Creating Obs CI project..."
    sed -i "s#PROJECT_NAME#${PROJECT_NAME}#g" meta.xml
    curl -X PUT -u "$OSCUSER:$OSCPASS" -H "Content-type: text/xml" -d @meta.xml "$OBS_HOST/source/deepin:CI:$PROJECT_NAME/_meta"
fi

if [ "$projectconfig" != "" ]; then
    echo "Project configuration"
fi

result=$(curl -u $OSCUSER:$OSCPASS "$OBS_HOST/source/deepin:CI:$PROJECT_NAME/$REPO_NAME/_meta"|grep "unknown_package")
#echo "\n********result: $result ********\n"
if [ "$result" != "" ];then
    echo "Creating Obs CI package..."
    packageconfig=${packageconfig#\"}
    echo -e ${packageconfig%\"} | sed 's/\\"/"/g' > meta1.xml
    sed -i "s#PKGNAME#${REPO_NAME}#g" meta1.xml
    sed -i "s#PROJECT_NAME#${PROJECT_NAME}#g" meta1.xml
    curl -X PUT -u "$OSCUSER:$OSCPASS" -H "Content-type: text/xml" -d @meta1.xml "$OBS_HOST/source/deepin:CI:$PROJECT_NAME/$REPO_NAME/_meta"
fi

# __branch_request文件中包含的sha值不变的情况下不重复提交
# 减少source server的源码处理次数，节约有限的带宽
oldsha=$(curl -u $OSCUSER:$OSCPASS "$OBS_HOST/source/deepin:CI:$PROJECT_NAME/$REPO_NAME/_branch_request" | yq -e '.pull_request.head.sha')
oldsha=${oldsha#\"}
oldsha=${oldsha%\"}

if [ "$oldsha" != "$PULL_PULL_SHA" ]; then
    brconfig=${brconfig#\"}
    if [ -n "${brconfig}" -a "${brconfig}" != "" -a "${brconfig}" != null ]; then
        echo "Uploading _branch_request..."
        echo ${brconfig%\"} | sed 's/\\"/"/g' > _branch_request
        sed -i "s#REPO#${REPO_OWNER}/${REPO_NAME}#g" _branch_request
        sed -i "s#TAGSHA#${PULL_PULL_SHA}#g" _branch_request
        curl -X PUT -u "$OSCUSER:$OSCPASS" -d @_branch_request -s "$OBS_HOST/source/deepin:CI:$PROJECT_NAME/$REPO_NAME/_branch_request"
    fi

    # 存在_service文件的情况下不重复提交
    result=$(curl -u $OSCUSER:$OSCPASS "$OBS_HOST/source/deepin:CI:$PROJECT_NAME/$REPO_NAME/_service"|grep "no such file")
    if [ "$result" != "" ]; then
        echo "Uploading _service..."
        serviceconfig=${serviceconfig#\"}
        echo -e ${serviceconfig%\"} | sed 's/\\"/"/g' > _service
        sed -i "s#REPO#${REPO_OWNER}/${REPO_NAME}#g" _service
        if [ -z "${brconfig}" -o "${brconfig}" = "" -o "${brconfig}" = null ]; then
            echo "Using service revision"
            revision="    <param name=\"revision\">${PULL_PULL_SHA}</param>"
            sed -i "3a ${revision}" _service
        fi
        curl -X PUT -u "$OSCUSER:$OSCPASS" -H "Content-type: text/xml" -d @_service -s "$OBS_HOST/source/deepin:CI:$PROJECT_NAME/$REPO_NAME/_service"
    fi
else
    # 如果__branch_request的sha值未发生变化，触发rebuild，这里主要应对github通过'/test github-trigger-obs-ci'命令触发rebuild的场景
    curl -X POST -u "$OSCUSER:$OSCPASS" "$OBS_HOST/build/deepin:CI:$PROJECT_NAME?cmd=rebuild&package=$REPO_NAME"
fi

if [ -n "${buildscript}" -a "${buildscript}" != "" -a "${buildscript}" != null ]; then
    echo ${buildscript} > build.script
    curl -X PUT -u "$OSCUSER:$OSCPASS" -d @build.script -s "$OBS_HOST/source/deepin:CI:$PROJECT_NAME/$REPO_NAME/build.script"
fi

echo "Setting github commit status..."
multirepos="true"
repositories=$(cat meta.xml | xq -e '.project.repository[]."@name"')
if [ $? -ne 0 ]; then
    multirepos="false"
    repositories=$(cat meta.xml | xq -e '.project.repository."@name"')
fi

for reponame in $repositories
do
    reponame=${reponame#\"}
    reponame=${reponame%\"}
    if [ $multirepos = "true" ]; then
        arches=$(cat meta.xml | xq --arg reponame $reponame '.project.repository[] as $repos | select($repos."@name" == $reponame) | $repos.arch[]')
    else
        arches=$(cat meta.xml | xq --arg reponame $reponame '.project.repository as $repos | select($repos."@name" == $reponame) | $repos.arch[]')
    fi
    if [ $? -ne 0 ]; then
        if [ $multirepos = "true" ]; then
            arches=$(cat meta.xml | xq --arg reponame $reponame '.project.repository[] as $repos | select($repos."@name" == $reponame) | $repos.arch')
        else
            arches=$(cat meta.xml | xq --arg reponame $reponame '.project.repository as $repos | select($repos."@name" == $reponame) | $repos.arch')
        fi
    fi
    for arch in $arches
    do
        arch=${arch#\"}
        arch=${arch%\"}
        echo "{\"state\":\"pending\", \"context\":\"OBS: ${reponame}/${arch}\", \"target_url\":\"https://build.deepin.com/package/live_build_log/deepin:CI:${PROJECT_NAME}/${REPO_NAME}/${reponame}/${arch}\"}" > status.data
        curl -X POST -H "Accept: application/vnd.github+json" -H "Authorization: token $GITHUB_TOKEN" -d @status.data https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/statuses/${PULL_PULL_SHA}
    done
done
