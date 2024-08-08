#!/bin/sh
set +x

# 导入yq命令
command -v git >/dev/null 2>&1 || { echo >&2 "git命令未找到，请先安装git命令"; exit 1; }


if [ -z "$REPO_OWNER" ]; then
    export REPO_OWNER="peeweep-test"
fi

if [ -z "$REPO_NAME" ]; then
    export REPO_NAME="test-ci-check"
fi

if [ -z "$PULL_BASE_REF" ]; then
    export PULL_BASE_REF="main"
fi

if [ -z "$PULL_NUMBER" ]; then
    export PULL_NUMBER="1"
fi

# 1. 下载代码
downloadLatestCode(){
    [ -d "baseCodeDir" ] && rm -rf baseCodeDir
    mkdir baseCodeDir && cd baseCodeDir
    git clone https://github.com/${REPO_OWNER}/${REPO_NAME}.git -b ${PULL_BASE_REF} --depth=1 . 
    if [ -d "debian/patches" ];then
        if [ "`ls -A debian/patches`" != "" ];then
            cp debian/patches . -fr
            quilt push -a || true
        fi
    fi
    cd -
}

# 1. 下载代码
downloadDeveloperCode(){
    [ -d "currentCodeDir" ] && rm -rf currentCodeDir
    mkdir currentCodeDir && cd currentCodeDir
    git init .
    git fetch https://github.com/${REPO_OWNER}/${REPO_NAME}.git pull/${PULL_NUMBER}/head:pr-${PULL_NUMBER} --no-tags  --depth=10
    git checkout pr-${PULL_NUMBER}
    if [ -d "debian/patches" ];then
        if [ "`ls -A debian/patches`" != "" ];then
            cp debian/patches . -fr
            quilt push -a  || true
        fi
    fi
    cd -
}

# 2 运行
startRun(){
    ! [ -d "baseCodeDir" ] && echo "base code not exist" && exit 1
    ! [ -d "currentCodeDir" ] && echo "current code not exist" && exit 1
    deepin-abigail -c fastFilesCompare.json | tee api_check.txt || true
}

# 3. 分析结果
getResult(){
    if [ -e "api_check.txt" ];then
        apiCheckResult=$(egrep "\[Chg_exprort_fun\]|\[Del_export_fun\]" api_check.txt | wc -l)
        echo "$apiCheckResult"
        if [ "$apiCheckResult" != "0" ];then
            echo "API接口检查失败"
            sed -i '1i 检测到存在对外接口删除或修改:' api_check.txt
            # 4. 添加评论
            python3 -c "from postAction import createPRComment; createPRComment('api-check')"
            exit 1
        fi
        echo "API接口检查成功"
    fi
}

downloadLatestCode
downloadDeveloperCode
startRun
getResult
