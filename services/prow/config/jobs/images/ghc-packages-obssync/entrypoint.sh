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

if [ -z "$PULL_BASE_SHA" ]; then
    export PULL_BASE_SHA="ce334a4f31b85af6ca85bc1e1819dc89a6bd51fc"
fi

export full_repo_name="$REPO_OWNER/$REPO_NAME"

# 获取pr number
PULL_NUMBER=$(curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$full_repo_name/commits/$PULL_BASE_SHA/pulls \
  | jq '.[] | .number')

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
    git checkout deepin-main -- p/${p}
    dht debian2dsc -o p/${p} p/${p}/debian
    osc api -X PUT -f ${p}.xml /source/ghc:exp/${p}/_meta
    for d in $(osc ls ghc:exp/${p})
    do
        echo "delete ${p}'s ${d}"
        osc api -X DELETE /source/ghc:exp/${p}/${d}
    done
    for f in $(ls p/${p})
    do
        cat > ${p}.xml << EOF
<package name="${p}" project="ghc:exp">
  <title/>
  <description/>
</package>
EOF
        if [ "$f" != "debian" ];then
            osc api -X PUT -f p/${p}/${f} /source/ghc:exp/${p}/${f}
        fi
    done

    # 添加success状态
    echo "{\"state\":\"success\", \"context\":\"OBS: ${p} sync\", \"target_url\":\"https://build.deepin.com/package/show/ghc:exp/${p}\"}" > status.data
    curl -X POST -H "Accept: application/vnd.github+json" -H "Authorization: token $GITHUB_TOKEN" -d @status.data https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/statuses/${PULL_BASE_SHA}
done
