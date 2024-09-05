#!/bin/bash

# 导入yq命令
command -v git >/dev/null 2>&1 || { echo >&2 "git命令未找到，请先安装git命令"; exit 1; }


if [ -z "$REPO_OWNER" ]; then
    export REPO_OWNER="peeweep-test"
fi

if [ -z "$REPO_NAME" ]; then
    export REPO_NAME="test-ci-check"
    # export REPO_NAME="dde-shell-test"
fi

if [ -z "$PULL_BASE_REF" ]; then
    # export PULL_BASE_REF="master"
    export PULL_BASE_REF="main"
fi

if [ -z "$PULL_NUMBER" ]; then
    export PULL_NUMBER="1"
fi

if [ -z "$PULL_PULL_SHA" ]; then
    export PULL_PULL_SHA="123456"
fi

if [ -z "$BUILD_ID" ]; then
    export BUILD_ID="1"
fi

current_date=$(date +%Y%m%d)
logShowUrl="http://ciossapi-dev.uniontech.com/iso/ci-prow/${current_date}/api-check/${REPO_OWNER}/${REPO_NAME}/${PULL_NUMBER}/${PULL_PULL_SHA}/"
logUploaUrl="s3://iso/ci-prow/${current_date}/api-check/${REPO_OWNER}/${REPO_NAME}/${PULL_NUMBER}/${PULL_PULL_SHA}/"
logMsg1='''
<details>
  <summary>详情</summary>

```ruby
'''
logMsg2='''
``` 
</details>
'''

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
    [ -d "apicheckReport" ] && rm -rf apicheckReport
    mkdir apicheckReport
    commentLog="apicheckReport/${BUILD_ID}-apicheck.txt"
    deepin-abigail -c fastFilesCompare.json | tee ${commentLog} || true
    apiCheckResult=$(egrep "\[Chg_exprort_fun\]|\[Del_export_fun\]" ${commentLog} | wc -l || true)
    if [ "$apiCheckResult" -gt "0" ];then
        echo "API接口检查失败"
        resultInfoMsg=$(cat $commentLog)
        logMsgHead="- 检测到存在对外接口删除和修改;"
        echo "${logMsgHead}${logMsg1}${resultInfoMsg}${logMsg2}" | tee -a comment.txt
        echo -e "请联系系统开发review:\n/assign @liujianqiang-niu\n/hold" | tee -a comment.txt
        # 4. 添加评论
        python3 -c "from postAction import createPRComment; createPRComment('api-check')"
        python3 -c "from postAction import addReviewers; addReviewers()"
        # exit 1
    else
        echo "API接口检查成功"
    fi
    s3cmd put ${commentLog} "${logUploaUrl}${commentLog}" || true
}

downloadLatestCode
downloadDeveloperCode
startRun
