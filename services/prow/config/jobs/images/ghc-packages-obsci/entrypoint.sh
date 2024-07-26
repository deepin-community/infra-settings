#!/bin/sh
#set -x

# 导入yq命令
command -v curl >/dev/null 2>&1 || { echo >&2 "curl命令未找到，请先安装curl命令"; exit 1; }
command -v git >/dev/null 2>&1 || { echo >&2 "git命令未找到，请先安装git命令"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "jq命令未找到，请先安装jq命令"; exit 1; }
command -v dht >/dev/null 2>&1 || { echo >&2 "dht命令未找到，请先安装dht命令"; exit 1; }

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

if [ -z "$REPO_OWNER" ]; then
    export REPO_OWNER="deepin-community"
fi

if [ -z "$REPO_NAME" ]; then
    export REPO_NAME="GHC_packages"
fi

if [ -z "$PULL_NUMBER" ]; then
    export PULL_NUMBER="1"
fi

if [ -z "$PULL_PULL_SHA" ]; then
    export PULL_PULL_SHA="ce334a4f31b85af6ca85bc1e1819dc89a6bd51fc"
fi

if [ -z "$PULL_HEAD_REF" ]; then
    export PULL_HEAD_REF="deepin-main"
fi

export full_repo_name="$REPO_OWNER/$REPO_NAME"

PROJECT_NAME="$REPO_OWNER:$REPO_NAME:PR-$PULL_NUMBER"
if [[ "$PULL_HEAD_REF" == "topic-"* ]]; then
    prefix="topic-"
    topic=${PULL_HEAD_REF#$prefix}
    echo "Add to topic to $topic"
    PROJECT_NAME="topics:$topic"
fi

# 创建obs pr project
cat > ${PROJECT_NAME}.xml << EOF
<project name="deepin:CI:${PROJECT_NAME}">
  <title/>
  <description/>
  <person userid="deepin-obs" role="maintainer"/>
  <repository name="deepin_develop">
    <path project="deepin:CI" repository="ghc"/>
    <arch>aarch64</arch>
    <arch>riscv64</arch>
    <arch>x86_64</arch>
    <arch>i386</arch>
    <arch>loong64</arch>
  </repository>
</project>
EOF
osc api -X PUT -f ${PROJECT_NAME}.xml /source/deepin:CI:${PROJECT_NAME}/_meta

# 获取pr的文件列表
packages=$(curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$full_repo_name/pulls/$PULL_NUMBER/files \
  | jq '.[] | .filename' | grep p/ | awk -F '/' '{print $2}'|sort|uniq)

# git clone ghc packages debian目录管理项目
git clone --filter=blob:none --no-checkout https://github.com/$full_repo_name
cd $REPO_NAME

for p in $packages
do
    echo ${p} updating
    git checkout $PULL_PULL_SHA -- p/${p}
    dht debian2dsc -o p/${p} p/${p}/debian
    osc api -X PUT -f ${p}.xml /source/deepin:CI:${PROJECT_NAME}/${p}/_meta
    for d in $(osc ls deepin:CI:${PROJECT_NAME}/${p})
    do
        echo "delete ${p}'s ${d}"
        osc api -X DELETE /source/deepin:CI:${PROJECT_NAME}/${p}/${d}
    done
    for f in $(ls p/${p})
    do
        cat > ${p}.xml << EOF
<package name="${p}" project="deepin:CI:${PROJECT_NAME}">
  <title/>
  <description/>
</package>
EOF
        if [ "$f" != "debian" ];then
            osc api -X PUT -f p/${p}/${f} /source/deepin:CI:${PROJECT_NAME}/${p}/${f}
        fi
    done

    # 添加pending状态
    for arch in $(echo 'aarch64 x86_64 loong64 i386 riscv64')
    do
        echo "{\"state\":\"pending\", \"context\":\"OBS: ${p}/${arch}\", \"target_url\":\"https://build.deepin.com/package/live_build_log/deepin:CI:${PROJECT_NAME}/${p}/deepin_develop/${arch}\"}" > status.data
        curl -X POST -H "Accept: application/vnd.github+json" -H "Authorization: token $GITHUB_TOKEN" -d @status.data https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/statuses/${PULL_PULL_SHA}
    done
done
