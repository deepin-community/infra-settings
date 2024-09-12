
import os
import requests
import time

# 环境变量中获取参数
REPO_OWNER = os.environ.get("REPO_OWNER", "peeweep-test")
REPO_NAME = os.environ.get("REPO_NAME", "test-ci-check")
# REPO = os.environ.get("REPO", "reviews-team-test/test_jenkins")
PULL_NUMBER = os.environ.get("PULL_NUMBER", "1")
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
reviewers = os.environ.get("reviewers", "liujianqiang-niu")
# reviewers = os.environ.get("reviewers", "ckux")
reviewer_teams = os.environ.get("reviewer_teams", "ckux-team")
comment_path = os.environ.get("comment_path", "./comment.txt")

REPO = REPO_OWNER + '/' + REPO_NAME

# 重试装饰器
def retry(tries=3, delay=1):
    def decorator(func):
        def wrapper(*args, **kwargs):
            for i in range(tries):
                try:
                    return func(*args, **kwargs)
                except:
                    print(f"第{i+1}次尝试失败...")
                    time.sleep(delay)
            print("重试失败...")
            return None
        return wrapper
    return decorator

def getRequest(url):
    response = requests.get(url)
    if response.status_code == 200:
      return response.json()
    else:
      print(response.status_code)
      print(f"获取{url}失败, 错误信息：", response.text)


def getHeaders(token):
    headers = {
        "Authorization": f"Bearer {token}",
        "X-GitHub-Api-Version": "2022-11-28",
        "Accept": "application/vnd.github+json" 
    }
    return headers


@retry(tries=3, delay=1)
def getReviewers():
    url = f'https://api.github.com/repos/{REPO}/pulls/{PULL_NUMBER}/requested_reviewers'
    reviewJson = getRequest(url)
    reviewerLst = [obj['login'] for obj in reviewJson['users']]
    reviewerTeamLst = [obj['name'] for obj in reviewJson['teams']]
    return reviewerLst, reviewerTeamLst


@retry(tries=3, delay=1)
def removeReviewers(reviewerLst, teamReviewerLst):
    url = f'https://api.github.com/repos/{REPO}/pulls/{PULL_NUMBER}/requested_reviewers'
    data = {
        "reviewers": reviewerLst,
        "team_reviewers": teamReviewerLst
    }
    response = requests.delete(url, json=data, headers=getHeaders(GITHUB_TOKEN))
    re = "成功"
    if response.status_code != 200:
        print(f"错误码: {response.status_code}")
        print(f"错误信息: {response.text}")
        # print(f"请求删除reviewers: {reviewerLst}和{teamReviewerLst}失败, 错误信息：{response.text}")
        response.raise_for_status()
        re = "失败"
    return re


@retry(tries=3, delay=1)
def addReviewers():
    # data['team_reviewers'] =  team_reviewers.split(',')
    url = f'https://api.github.com/repos/{REPO}/pulls/{PULL_NUMBER}/requested_reviewers'
    data = {
      'reviewers': reviewers.split(',')
    }
    msg = f"添加reviewers: {reviewers}"
    response = requests.post(url, json=data, headers=getHeaders(GITHUB_TOKEN))
    if response.status_code != 201:
        msg += "失败"
        print(f"错误信息: {response.status_code},{response.text}")
        response.raise_for_status()
    else:
        msg += "成功"
    print(msg)


# 检查人员或是团队是否在reviewer中
# 返回在reviewer中的人员或是团队
def checkExistReviewers(reviewers, team_reviewers):
    existReviewers = []
    existReviewerTeams = []
    reviewerLst, reviewerTeamLst = getReviewers()
    for reviewerName in reviewers.split(','):
        for userLogin in reviewerLst:
            if userLogin == reviewerName:
                existReviewers.append(reviewerName)
                
    for reviewerTeamName in team_reviewers.split(','):
        for teamName in reviewerTeamLst:
            if teamName == reviewerTeamName:
                existReviewerTeams.append(reviewerTeamName)
                    
    return existReviewers, existReviewerTeams

# 检查reviewer添加或是删除操作是否成功
def checkReviewerActionStatus(checkType, reviewersMsg, memberLst, teamList):
    memberLst2, teamList2 = checkExistReviewers(reviewers, reviewer_teams)
    checkResult = "成功"
    if checkType == '添加':
        if reviewers not in memberLst2:
            checkResult = "失败"
    if checkType == '删除':
        for member in memberLst:       
            if member in memberLst2:
                checkResult = "失败"
        for teamMem in teamList:
            if teamMem not in teamList2:
                checkResult = "失败"
    print("检查"+checkType+reviewersMsg+checkResult)

# 检查失败则添加reviewer, 若是检查成功则删除reviewer
def checkReviewer():
    memberLst, teamList = checkExistReviewers(reviewers, reviewer_teams)
    checkType = "添加"
    checkResult = "成功"
    reviewersMsg = ""
    if os.path.isfile(comment_path):
        reviewersMsg = reviewers
        if not memberLst:
            checkResult = addReviewers(reviewers)
    else:
        reviewersMsg = f"{reviewers}和{reviewer_teams}"
        checkType = '删除'
        if memberLst or teamList:
            checkResult = removeReviewers(memberLst, teamList)
    print(checkType+reviewersMsg+str(checkResult))

# 写comment文件第一行run链接
def writeHeadToCommentFile(content, commentFile):
    temp_filename = 'comment.tmp'
    # 写入新内容到临时文件
    with open(temp_filename, 'w', encoding='utf-8') as temp_file:
        temp_file.write(content + '\n')
    # 追加原始文件的内容到临时文件
    with open(commentFile, 'r', encoding='utf-8') as original_file, open(temp_filename, 'a', encoding='utf-8') as temp_file:
        temp_file.writelines(original_file)
    os.replace(temp_filename, commentFile)


# 创建不同类型检查的PR/issue评论
def createIssueComment(commenMsg):
    url = f'https://api.github.com/repos/{REPO}/issues/{PULL_NUMBER}/comments'
    # print(f'apiurl is {url}')
    data = { "body": commenMsg }
    response = requests.post(url, json=data, headers=getHeaders(GITHUB_TOKEN))
    if response.status_code != 200 and response.status_code != 201:
        print("评论失败，错误信息：", response.text)
    else:
        print("评论成功")

def createPRComment(checkType):
    detailUrl = f'https://github.com/reviews-team-test/infra-settings/blob/master/services/prow/config/jobs/images/{checkType}/readme.md'
    if checkType == 'debian-check':
        commenHead = f'> [!WARNING]\n[[Debian检查]]({detailUrl})'      
    if checkType == 'api-check':
        commenHead = f'> [!WARNING]\n[[API接口检查]]({detailUrl})'
    if checkType == 'static-check':
        commenHead = f'> [!NOTE]\n[[静态代码检查]]({detailUrl})'
    commentFile = 'comment.txt'
    writeHeadToCommentFile(commenHead, commentFile)
    commenMsg = ''
    with open(commentFile, 'r', encoding='utf-8') as fp:
      commenMsg = fp.read()
    createIssueComment(commenMsg)