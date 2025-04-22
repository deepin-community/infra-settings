#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import os
import sys
import json
import logging
import requests
import subprocess
from datetime import datetime
import xml.etree.ElementTree as ET

# --- 配置 ---
GIT_BOT_NAME = "deepin-ci-robot"
GIT_BOT_EMAIL = "packages@deepin.org" # 使用一个明确的机器人邮箱
COMMIT_MESSAGE = "chore: Automatically translate updated .desktop files"
PR_TITLE = "Automatic Translation: Update .desktop files"
PR_BODY = "This PR was automatically generated to update translations for modified .desktop files."
PERL_SCRIPT_PATH = "/usr/bin/deepin-desktop-ts-convert"

# --- 日志配置 ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# --- Prow 环境变量 (Postsubmit) ---
# 参考: https://github.com/kubernetes/test-infra/blob/master/prow/jobs.md#job-environment-variables
REPO_OWNER = os.environ.get("REPO_OWNER", "peeweep-test")
REPO_NAME = os.environ.get("REPO_NAME", "dde-file-manager")
PULL_BASE_REF = os.environ.get("PULL_BASE_REF", "hudeng-go-patch-1") # 推送的目标分支 (e.g., 'main', 'master')
# PULL_REFS 格式通常是 'base_ref:base_sha,pull_sha:pull_ref' 或 'base_sha..head_sha'
# 对于 postsubmit, 它可能只包含 head_sha 或 base_sha..head_sha
# 我们需要解析出 base_sha 和 head_sha
PULL_REFS = os.environ.get("PULL_REFS", "526ce7df2654560e43aac05fdcf4507b583ded74:86ec1ce2a8c4f23e2bd8e4eb6e79b47b1dd21bb2")
PULL_BASE_SHA = os.environ.get("PULL_BASE_SHA", "526ce7df2654560e43aac05fdcf4507b583ded74") # 推送的 commit SHA
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN") # Prow 注入的 Token

# 源码目录
REPO_PATH = os.getcwd() #"dde-file-manager"

def run_command(command: list, check=True, cwd=None, shell=False, capture_output=False, text=True, env=None, quiet=False):
    """执行 shell 命令并记录日志"""
    cmd_str = ' '.join(str(x) for x in command) if isinstance(command, list) else command
    if not quiet:
        logging.info(f"Running command: {cmd_str} in {cwd or REPO_PATH}")
    try:
        process = subprocess.run(
            command,
            check=check,
            cwd=cwd or REPO_PATH,
            shell=shell,
            capture_output=capture_output,
            text=text,
            env=dict(os.environ, **(env or {})) # 合并环境变量
        )
        if capture_output:
            logging.info(f"Command output: \n{process.stdout}")
            if process.stderr:
                logging.warning(f"Command error output: \n{process.stderr}")
        return process
    except subprocess.CalledProcessError as e:
        if not quiet:
            logging.error(f"Command failed: {cmd_str}")
        logging.error(f"Error code: {e.returncode}")
        if capture_output:
            logging.error(f"Stdout: {e.stdout}")
            logging.error(f"Stderr: {e.stderr}")
        raise # 重新抛出异常，让主程序处理

def get_filtered_files_by_commit(owner: str, repo: str, commit_sha: str):
    """
    根据 Commit ID 获取关联 PR 中匹配 */desktop*.ts 的文件列表
    返回格式：["desktop.ts", "desktop_zh_CN.ts", ...]
    """


    headers = {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json"
    }
    file_pattern = re.compile(r'.*/desktop.*\.ts$')  # 正则过滤规则
    filtered_files = []

    try:
        # 步骤 1: 获取关联的 PR 列表
        prs_url = f"https://api.github.com/repos/{owner}/{repo}/commits/{commit_sha}/pulls"
        prs_response = requests.get(prs_url, headers=headers)
        prs_response.raise_for_status()
        pr_list = prs_response.json()

        if not pr_list:
            logging.info("该 Commit 未关联任何 PR")
            return []

        # 步骤 2: 遍历每个 PR 获取文件并过滤
        for pr in pr_list:
            pr_number = pr["number"]
            files_url = f"https://api.github.com/repos/{owner}/{repo}/pulls/{pr_number}/files"

            files_response = requests.get(files_url, headers=headers)
            files_response.raise_for_status()

            # 提取文件名并过滤
            files = [f["filename"] for f in files_response.json()]
            logging.info(f"PR #{pr_number} 关联的文件: {files}")
            matched = [f for f in files if file_pattern.match(f)]
            filtered_files.extend(matched)

    except requests.exceptions.HTTPError as e:
        logging.error(f"API 请求失败: {e.response.text}")
    except Exception as e:
        logging.error(f"发生异常: {str(e)}")

    # 返回去重后的结果（如果需要保留重复文件可移除 set()）
    logging.info(f"匹配到的文件: {filtered_files}")
    return filtered_files

def create_pull_request(repo_owner, repo_name, pull_base_ref, new_branch_name, pr_title, pr_body):
    """
    使用 GitHub API 创建 Pull Request
    :param repo_owner: 仓库所有者
    :param repo_name: 仓库名称
    :param pull_base_ref: 目标分支（PR 要合并到的分支）
    :param new_branch_name: 源分支（要合并的分支）
    :param pr_title: PR 标题
    :param pr_body: PR 描述
    """

    # API 配置
    url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/pulls"
    headers = {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json"
    }
    data = {
        "title": pr_title,
        "body": pr_body,
        "base": pull_base_ref,
        "head": new_branch_name  # 格式为分支名（同仓库）或 user:branch（跨仓库）
    }

    try:
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()  # 检查 HTTP 错误
        pr_info = response.json()
        logging.info(f"PR 创建成功: {pr_info['html_url']}")
        return pr_info
    except requests.exceptions.HTTPError as err:
        # 解析错误详情
        error_msg = response.json().get("message", "未知错误")
        logging.error(f"创建 PR 失败 - 状态码 {response.status_code}: {error_msg}")
        sys.exit(1)
    except Exception as err:
        logging.error(f"请求异常: {err}")
        sys.exit(1)

def get_commit_range(refs_string):
    """从 PULL_REFS 解析 base_sha 和 head_sha"""
    if not refs_string:
        logging.error("PULL_REFS environment variable is not set.")
        return None, None

    # 尝试匹配 'base_sha..head_sha' 格式
    match_range = re.match(r"([a-f0-9]+)\.\.([a-f0-9]+)", refs_string)
    if match_range:
        logging.info(f"Parsed commit range: {match_range.group(1)}..{match_range.group(2)}")
        return match_range.group(2), match_range.group(1)

    # 尝试匹配 'base_ref:base_sha,head_sha:head_ref' 或类似格式
    # 注意：Prow 的具体格式可能变化，这里做一些常见假设
    parts = refs_string.split(',')
    base_sha = None
    head_sha = None
    for part in parts:
        # 尝试通过分割':'取出head_sha和base_sha
        if ':' in part:
            head_sha = part.split(':')[0] # 取冒号前的部分作为 sha
            if len(part.split(':')) > 1:
                base_sha = part.split(':')[1]
            break

    # 如果只解析出一个 sha，通常是 head_sha，我们需要 base_sha
    # 尝试获取 head_sha 的父提交作为 base_sha
    if head_sha and not base_sha:
        try:
            result = run_command(['git', 'rev-parse', f'{head_sha}^'], capture_output=True)
            base_sha = result.stdout.strip()
            logging.info(f"Derived base_sha as parent of head_sha: {base_sha}")
        except subprocess.CalledProcessError:
             logging.warning(f"Could not determine parent of {head_sha}. Cannot determine commit range accurately.")
             return None, head_sha # 返回 head_sha，让后续逻辑处理单个 commit

    if base_sha and head_sha:
        logging.info(f"Parsed commit range: {base_sha}..{head_sha}")
        return base_sha, head_sha
    elif head_sha:
         logging.warning(f"Could only parse head_sha: {head_sha}. Will check files in this commit.")
         return None, head_sha # 无法确定范围，只检查 head_sha
    else:
        logging.error(f"Could not parse commit range from PULL_REFS: {refs_string}")
        return None, None

def get_desktop_file_path_from_ts_path(desktop_ts_path):
    """
    根据 desktop_ts_path 文件中 Desktop Entry 的 Name 字段，
    匹配源码仓库目录下的 .desktop 文件。

    :param desktop_ts_path: .ts 文件的路径
    :return: 匹配的 .desktop 文件路径
    """
    desktop_entry_name = None

    # 解析 desktop.ts 文件 (XML 格式)
    try:
        tree = ET.parse(os.path.join(desktop_ts_path, "desktop.ts"))
        root = tree.getroot()

        # 查找 Desktop Entry]Name 的内容
        for message in root.findall(".//message"):
            location = message.findall("location")
            source = message.find("source")
            for loc in location:
                if "Desktop Entry]Name" in loc.attrib.get("filename", ""):
                    if source is not None and source.text:
                        desktop_entry_name = source.text.strip()
                        break
    except FileNotFoundError:
        logging.error(f"File desktop.ts not found: {desktop_ts_path}")
        return None
    except ET.ParseError as e:
        logging.error(f"Failed to parse XML in {desktop_ts_path}: {e}")
        return None

    if not desktop_entry_name:
        logging.warning(f"No 'Desktop Entry]Name' field found in {desktop_ts_path}.")
        return None

    # 在源码仓库中查找 .desktop 文件
    ignore_dirs = [".git", ".github"]  # 忽略的目录
    for root, dirs, files in os.walk(REPO_PATH):
        # 从 dirs 中移除需要忽略的目录
        dirs[:] = [d for d in dirs if d not in ignore_dirs]
        for file in files:
            if file.endswith(".desktop"):
                desktop_file_path = os.path.join(root, file)
                try:
                    # 读取 .desktop 文件内容
                    with open(desktop_file_path, 'r', encoding='utf-8') as desktop_file:
                        for line in desktop_file:
                            # 假设 .desktop 文件中 Name 字段格式为：Name=some_name
                            match = re.match(r'^Name\s*=\s*(.+)$', line.strip())
                            if match and match.group(1).strip() == desktop_entry_name:
                                return os.path.abspath(desktop_file_path)
                except FileNotFoundError:
                    logging.warning(f"File not found: {desktop_file_path}")
                except Exception as e:
                    logging.warning(f"Error reading {desktop_file_path}: {e}")

    logging.warning(f"No matching .desktop file found for name '{desktop_entry_name}'.")
    return None

def main():
    logging.info("Starting desktop file translation process...")

    # --- 检查环境变量 ---
    if not all([REPO_OWNER, REPO_NAME, PULL_BASE_REF, PULL_REFS, GITHUB_TOKEN]):
        logging.error("Missing required environment variables (REPO_OWNER, REPO_NAME, PULL_BASE_REF, PULL_REFS, GITHUB_TOKEN). Exiting.")
        sys.exit(1)

    # --- 配置 Git ---
    logging.info("Configuring Git...")
    run_command(['git', 'config', 'user.name', GIT_BOT_NAME])
    run_command(['git', 'config', 'user.email', GIT_BOT_EMAIL])
    run_command(['git', 'remote', 'add', 'origin', f'https://github.com/{REPO_OWNER}/{REPO_NAME}'])
    # 使用 token 配置 https 认证
    git_credential_url = f"https://{GIT_BOT_NAME}:{GITHUB_TOKEN}@github.com"
    run_command(['git', 'config', f'url.{git_credential_url}.insteadOf', 'https://github.com'], quiet=True)


    # --- 获取 commit 范围并查找变更的 */desktop*.ts 文件 ---
    # base_sha, head_sha = get_commit_range(PULL_REFS)
    #if not head_sha:
    #    logging.error("Could not determine head commit SHA. Exiting.")
    #    sys.exit(1)

    # --- 创建新分支 ---
    head_sha = PULL_BASE_SHA
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    new_branch_name = f"auto-translate-desktop-{timestamp}"
    logging.info(f"Creating new branch '{new_branch_name}' from commit {head_sha}...")
    try:
        # 确保本地仓库是最新的 (Prow 通常会处理，但以防万一)
        # run_command(['git', 'fetch', 'origin']) # 可能不需要，取决于 Prow 环境
        run_command(['git', 'checkout', '-b', new_branch_name, head_sha])
    except subprocess.CalledProcessError:
        logging.error(f"Failed to create branch '{new_branch_name}' from {head_sha}. Exiting.")
        sys.exit(1)

    # --- 执行翻译脚本 ---
    translation_applied = False
    if os.path.exists(os.path.join(REPO_PATH, ".tx/translate_ts2desktop.sh")):
        # 如果源码仓库目录下存在翻译脚本".tx/translate_ts2desktop.sh"，直接使用
        try:
            logging.info("Using existing translation script...")
            run_command(['bash', os.path.join(REPO_PATH, ".tx/translate_ts2desktop.sh")])
            # 检查文件是否有实际更改 (避免空提交)
            status_result = run_command(['git', 'status', '--porcelain'], capture_output=True)
            if status_result.stdout.strip():
                logging.info("Staging translated files...")
                run_command(['git', 'add', '.'])
                translation_applied = True
            else:
                logging.info("No changes detected after running translation script.")
        except subprocess.CalledProcessError:
            logging.error("Failed to run translation script. Skipping translation.")
            sys.exit(1)
    else:
        # 如果翻译脚本不存在，自动查找并翻译
        changed_desktop_ts_files = []
        changed_desktop_ts_files = get_filtered_files_by_commit(REPO_OWNER, REPO_NAME, head_sha)
        logging.info(f"Changed desktop ts files: {changed_desktop_ts_files}")
        logging.info(f"Repo path: {REPO_PATH}")

        # 过滤掉可能为空的条目和不存在的文件
        # 过滤掉可能为空的条目，获取完整路径，并去重
        changed_desktop_ts_pathes = list({
            os.path.dirname(os.path.abspath(os.path.join(REPO_PATH, f)))
            for f in changed_desktop_ts_files
            if f and os.path.exists(os.path.join(REPO_PATH, f))
        })

        if not changed_desktop_ts_pathes:
            logging.info("No modified desktop ts pathes found in this push. Exiting.")
            sys.exit(0)

        logging.info(f"Found modified desktop ts file pathes: {changed_desktop_ts_pathes}")
        for desktop_ts_path in changed_desktop_ts_pathes:
            desktop_file = get_desktop_file_path_from_ts_path(desktop_ts_path)
            if not desktop_file:
                logging.warning(f"No matching .desktop file found for {desktop_ts_path}. Skipping translation.")
                continue
            logging.info(f"Translating {desktop_file}...")
            try:
                # 注意：假设 /usr/bin/deepin-desktop-ts-convert 直接修改文件
                # 如果它输出到 stdout 或需要其他参数，需要调整这里
                run_command([PERL_SCRIPT_PATH, "ts2desktop", desktop_file, desktop_ts_path, str(desktop_file) + ".tmp"])
                run_command(["mv", str(desktop_file) + ".tmp", desktop_file])
                # 检查文件是否有实际更改 (避免空提交)
                # 'git status --porcelain <file>' 会在有修改时输出信息
                status_result = run_command(['git', 'status', '--porcelain', desktop_file], capture_output=True)
                if status_result.stdout.strip():
                    logging.info(f"Staging translated file: {desktop_file}")
                    run_command(['git', 'add', desktop_file])
                    translation_applied = True
                else:
                    logging.info(f"No changes detected in {desktop_file} after translation script.")

            except subprocess.CalledProcessError:
                logging.warning(f"Failed to translate or stage {desktop_file}. Skipping this file.")
            except FileNotFoundError:
                logging.warning(f"Perl script not found at {PERL_SCRIPT_PATH}. Skipping translation.")
                break # 如果脚本不存在，后续文件也无法处理

    # --- 提交和推送 ---
    if not translation_applied:
        logging.info("No files were actually modified by the translation script. Cleaning up branch and exiting.")
        run_command(['git', 'checkout', PULL_BASE_REF]) # 切回原始分支
        run_command(['git', 'branch', '-D', new_branch_name]) # 删除本地分支
        sys.exit(0)

    logging.info("Committing translated files...")
    try:
        run_command(['git', 'commit', '-m', COMMIT_MESSAGE])
    except subprocess.CalledProcessError:
        # 如果 commit 失败 (例如没有更改被 add)，记录日志并退出
        logging.warning("Git commit failed. Maybe no files were successfully translated and staged? Exiting.")
        run_command(['git', 'checkout', PULL_BASE_REF])
        run_command(['git', 'branch', '-D', new_branch_name])
        sys.exit(0)


    logging.info(f"Pushing new branch '{new_branch_name}' to origin...")
    try:
        # 使用 git push origin <branch> 而不是完整的 URL，依赖于之前配置的 insteadOf
        run_command(['git', 'push', 'origin', new_branch_name])
    except subprocess.CalledProcessError:
        logging.error(f"Failed to push branch '{new_branch_name}'. Exiting.")
        # 可能需要清理本地分支？
        run_command(['git', 'checkout', PULL_BASE_REF])
        run_command(['git', 'branch', '-D', new_branch_name])
        sys.exit(1)

    # --- 创建 Pull Request ---
    logging.info(f"Creating Pull Request from '{new_branch_name}' to '{PULL_BASE_REF}'...")
    create_pull_request(REPO_OWNER, REPO_NAME, PULL_BASE_REF, new_branch_name, PR_TITLE, PR_BODY)


    # --- 清理 (可选) ---
    # logging.info(f"Switching back to base ref '{PULL_BASE_REF}'...")
    # run_command(['git', 'checkout', PULL_BASE_REF])
    # 本地分支可能不再需要，但保留也无妨

    logging.info("Desktop file translation process completed successfully.")

if __name__ == "__main__":
    main()
