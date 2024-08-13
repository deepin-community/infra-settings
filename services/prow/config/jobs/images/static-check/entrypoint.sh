#!/bin/sh

# 导入yq命令
command -v git >/dev/null 2>&1 || { echo >&2 "git命令未找到，请先安装git命令"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 "curl命令未找到，请先安装curl命令"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "jq命令未找到，请先安装jq命令"; exit 1; }

if [ -z "$REPO_OWNER" ]; then
    export REPO_OWNER="peeweep-test"
fi

if [ -z "$REPO_NAME" ]; then
    export REPO_NAME="test-ci-check"
fi


if [ -z "$PULL_NUMBER" ]; then
    export PULL_NUMBER="1"
fi

REPO="${REPO_OWNER}/${REPO_NAME}"

# 下载最新代码
downloadLatestCode(){
    [ -d "latestCodeDir" ] && rm -rf latestCodeDir
    mkdir latestCodeDir && cd latestCodeDir    
    git init .
    git remote add origin https://github.com/${REPO_OWNER}/${REPO_NAME}.git
    git pull origin pull/${PULL_NUMBER}/head --no-tags --depth=2
}


#  获取变动文件
getChangeFiles(){
    # 获取pr的文件列表
    curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/${REPO}/pulls/${PULL_NUMBER}/files \
        | jq '.[] | select(.status != "removed") | .filename' | tee changeFiles.txt || true
    sed -i 's/ /\n/g' changeFiles.txt || true
}

filterCheckFiles(){
    ! [ -e "changeFiles.txt" ] && echo "变动文件未获取，退出!!" && exit 1
    checkTool=$1
    case "${checkTool}" in
        "tscancode")
            egrep "\.c|\.cpp|\.cxx|\.cc|\.c++|\.tpp|\.txx" changeFiles.txt > $checkTool-files.txt
        ;;
        "cppcheck")
            egrep "\.cpp" changeFiles.txt > $checkTool-files.txt
        ;;
        "gosec"|"golangci-lint")
            egrep "\.go" changeFiles.txt > $checkTool-files.txt
        ;;
        "shellcheck")
            egrep "\.bash|\.sh" changeFiles.txt > $checkTool-files.txt
        ;;
        *)
            echo "default (none of above)"
        ;;
    esac
    sed -i ':a;N;s/\n/ /;ta;' $checkTool-files.txt
}

startCppCheck(){
    ! [ -s 'cppcheck-files.txt' ] && echo "无对应文件可供检测, cppcheck检测退出!!" && return 
    [ -d "cppcheckReport" ] && rm -rf cppcheckReport
    mkdir cppcheckReport
    curl -fsSLo qt.cfg https://gitlabwh.uniontech.com/deepin-auto-tools1/gerrit-utp-pipeline/-/raw/dev/autotest/config/cppcheck/qt.cfg || true
    commentLog="cppcheckReport/${REPO_NAME}-cppcheck-report.log"
    cppcheck --enable=all --suppress='*:*3rdparty*' --library=./qt.cfg `cat cppcheck-files.txt` \
        --template="{file},{line},{severity},{id},{message}" 2> $commentLog || true
    errNum=$(awk -F',' '$3 == "error"' ${commentLog} | wc -l)
    if [ "$errNum" -gt "0" ];then
        echo "cppcheck检查失败, 检测到${errNum}个error;" >> comment.txt
        awk -F',' '$3 == "error"' ${commentLog} >> comment.txt
    else
        echo "cppcheck检查成功"
    fi
}

startTscancode(){
    # docker中记得要创建一个tscancode-test文件夹用于存放cfg目录，在该cfg的同层目录下运行扫描
    ! [ -s 'tscancode-files.txt' ] && echo "无对应文件可供检测, tscancode检测退出!!" && return
    ! [ -d "../tscancode-cfg/cfg" ] && echo "tscancode配置文件未配置, 无法检测, 退出!!" && return
    cp ../tscancode-cfg/cfg . -rf
    [ -d "tscancodeReport" ] && rm -rf tscancodeReport
    mkdir tscancodeReport
    commentLog="tscancodeReport/${REPO_NAME}-tscancode-report.log"
    tscancode --enable=all `cat tscancode-files.txt` 2> $commentLog || true
    errNum=$(awk '{ if ($2 == "(Serious)" || $2 == "(Critical)") print $0 }' ${commentLog} | wc -l)
    if [ "$errNum" -gt "0" ];then
        echo "tscancode检查失败, 检测到${errNum}个error;" >> comment.txt
        awk '{ if ($2 == "(Serious)" || $2 == "(Critical)") print $0 }' ${commentLog} >> comment.txt
    else
        echo "tscancode检查成功"
    fi
}

startgosec(){
    ! [ -s 'gosec-files.txt' ] && echo "无对应文件可供检测, gosec检测退出!!" && return
    [ -d "gosecReport" ] && rm -rf gosecReport
    mkdir gosecReport
    logdir="gosecReport/${REPO_NAME}-gosec-detail.json"
    gosec -fmt=json -out=$logdir `cat gosec-files.txt` || true
    errNum="0"
    if [ $(cat $logdir | jq '.Issues') != "[]" ];then
        errNum=$(cat $logdir | jq '.Issues | select(.severity != "HIGH")' | wc -l)
    fi
    if [ "$errNum" -gt "0" ];then
        echo "gosec检查失败, 检测到${errNum}个error;" >> comment.txt
        cat $logdir
    else
        echo "gosec检查成功"
    fi
}

startGolangciLint(){
    ! [ -s 'golangci-lint-files.txt' ] && echo "无对应文件可供检测, golangci-lint检测退出!!" && return
    # 提前配置go环境
    if [ ! -e 'go.mod' ];then
        go mod init ${REPO_NAME} || true
    fi
    export GOPROXY="https://it.uniontech.com/nexus/repository/go-public/,direct"
    go mod tidy || true
    if [ ! -e '.golangci.yml' ];then
        curl -fsSLo .golangci.yml https://raw.githubusercontent.com/kuchune/check-tools/develop/staticCheck/golangci.yml || true
    fi
    [ -d "golangciLintReport" ] && rm -rf golangciLintReport
    mkdir golangciLintReport
    logdir="golangciLintReport/golangci-${REPO_NAME}.xml"
    golangci-lint run --timeout=10m -c .golangci.yml --new-from-rev=HEAD~1 --out-format junit-xml | tee $logdir || true
    errNum=$(egrep "[[:space:]]+<error .*message=" ${logdir} | wc -l)
    if [ "$errNum" -gt "0" ];then
        echo "golangci-lint检查失败, 检测到${errNum}个error;" >> comment.txt
        cat $logdir
    else
        echo "golangci-lint检查成功"
    fi
}

startShellCheck(){
    ! [ -s 'shellcheck-files.txt' ] && echo "无对应文件可供检测, shellcheck检测退出!!" && return
    [ -d "shellcheckReport" ] && rm -rf shellcheckReport
    mkdir shellcheckReport
    commentLog="shellcheckReport/${REPO_NAME}-shellcheck-report.log"
    cat shellcheck-files.txt | xargs shellcheck -f gcc > $commentLog || true
    errNum=$(awk -F':' '$4 == " error"' ${commentLog} | wc -l)
    if [ "$errNum" -gt "0" ];then
        echo "shellcheck检查失败, 检测到${errNum}个error;" >> comment.txt
        awk -F':' '$4 == " error"' ${commentLog} >> comment.txt
    else
        echo "shellcheck检查成功"
    fi
}

getPrimaryLanguage(){
    reStr=$(curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/${REPO}/languages \
        | jq -r 'to_entries | sort_by(-.value)[0] | .key')
    echo $reStr
}

main(){
    rm -rf comment.txt
    # 1. 下载最新代码
    downloadLatestCode
    # # 2. 获取变动文件
    getChangeFiles

    case "$(getPrimaryLanguage)" in
        'C++'|'C')
            # cppcheck
            filterCheckFiles cppcheck
            startCppCheck
            # tscancode
            filterCheckFiles tscancode
            startTscancode
        ;;
        'Go')
            # gosec
            filterCheckFiles gosec
            startgosec
            # golangci-lint
            filterCheckFiles golangci-lint
            startGolangciLint
        ;;
        *)
            echo "default (none of above)"
        ;;
    esac
    
    # shellcheck
    filterCheckFiles shellcheck
    startShellCheck

    if [ -e comment.txt ];then
        cp ../postAction.py .
        python3 -c "from postAction import createPRComment; createPRComment('static-check')"
        exit 1
    else
        echo "静态代码检测成功"
    fi
}

main