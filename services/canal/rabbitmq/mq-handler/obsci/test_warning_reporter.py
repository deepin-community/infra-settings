#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import unittest
from unittest.mock import patch, MagicMock

# 屏蔽未安装 pika 时的导入错误（pika 在容器镜像中安装，仅在 main 中使用）
if 'pika' not in sys.modules:
    sys.modules['pika'] = MagicMock()

from importlib.machinery import SourceFileLoader

# 动态加载无 .py 后缀的 githubreporter 脚本
SCRIPT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "githubreporter")
reporter = SourceFileLoader("githubreporter", SCRIPT_PATH).load_module()


class TestWarningReporter(unittest.TestCase):

    def test_extract_lintian_warnings_ignores_compiler_logs(self):
        # 验证只过滤 Lintian 日志，普通的编译器警告在 Lintian 之前会被直接忽略
        log_sample = """
[   10s] g++ -c -pipe -O2 -Wall -Wextra main.cpp
[   11s] main.cpp:15:9: warning: unused variable 'unused_var' [-Wunused-variable]
[   12s] CMake Warning at CMakeLists.txt:12: test warning
[   13s] dpkg-buildpackage: warning: build-info not found
[   14s] dpkg-shlibdeps: warning: symbol foo found in none
[   15s] DSC_BUILD_CMD: dpkg-buildpackage -us -uc
[   16s] Running lintian
[   17s] + lintian -i /usr/src/packages/DEBS/dtkcore_5.6.0_amd64.changes
[   18s] W: dtkcore: binary-without-manpage usr/bin/dtk-svgc
[   18s] N:
[   18s] N:   Each manual page should document a specific program...
[   18s] N:
[   19s] + test true = true
"""
        count, text = reporter.extract_warnings_from_log(log_sample)
        self.assertEqual(count, 1)
        # Lintian 阶段的警告被捕获，包含 -i 的详细说明
        self.assertIn("W: dtkcore: binary-without-manpage usr/bin/dtk-svgc", text)
        self.assertIn("N:   Each manual page should document a specific program", text)
        # Lintian 之前的常规编译与打包警告不被捕获
        self.assertNotIn("unused variable 'unused_var'", text)
        self.assertNotIn("CMake Warning", text)
        self.assertNotIn("dpkg-buildpackage: warning:", text)
        self.assertNotIn("dpkg-shlibdeps: warning:", text)

    def test_extract_lintian_filters_severity_tags(self):
        # 验证在 Lintian 阶段中，只过滤警告（W:），过滤掉错误（E:）、提示（I:）、琐碎（P:）
        log_sample = """
[  100s] Running lintian
[  101s] + lintian -i /usr/src/packages/DEBS/dtkcore.changes
[  102s] E: dtkcore: source-is-missing some/file.js
[  102s] N:   This is an error explanation and should NOT be captured.
[  103s] W: dtkcore: package-relation-with-self depends: dtkcore
[  103s] N:   This is a warning explanation and SHOULD be captured.
[  104s] I: dtkcore: hardening-no-bindnow usr/bin/dtk-svgc
[  104s] N:   This is an info explanation and should NOT be captured.
[  105s] P: dtkcore: no-upstream-changelog
[  106s] W: libdtkcore: package-name-doesnt-match-soname libdtkcore5.6
[  107s] cleanup_and_exit 0
"""
        count, text = reporter.extract_warnings_from_log(log_sample)
        self.assertEqual(count, 2)
        self.assertIn("W: dtkcore: package-relation-with-self", text)
        self.assertIn("This is a warning explanation and SHOULD be captured.", text)
        self.assertIn("W: libdtkcore: package-name-doesnt-match-soname", text)
        # E:, I:, P: 及其附带的 N: 说明均被排除
        self.assertNotIn("E: dtkcore: source-is-missing", text)
        self.assertNotIn("error explanation", text)
        self.assertNotIn("I: dtkcore: hardening-no-bindnow", text)
        self.assertNotIn("info explanation", text)
        self.assertNotIn("P: dtkcore: no-upstream-changelog", text)

    def test_extract_warnings_no_lintian_run(self):
        # 如果构建日志中未执行 Lintian，则不提取任何警告
        log_sample = """
Build started.
Compiling src/main.c
warning: some compiler warning
Linking build/app
Build successful.
"""
        count, text = reporter.extract_warnings_from_log(log_sample)
        self.assertEqual(count, 0)
        self.assertEqual(text, "")

    def test_extract_warnings_clean_lintian(self):
        # Lintian 执行但未发现 W: 警告
        log_sample = """
[   50s] Running lintian
[   51s] + lintian -i /usr/src/packages/DEBS/pkg.changes
[   52s] I: pkg: hardening-no-bindnow usr/bin/app
[   53s] + test true = true
"""
        count, text = reporter.extract_warnings_from_log(log_sample)
        self.assertEqual(count, 0)
        self.assertEqual(text, "")

    def test_extract_warnings_truncation(self):
        # 产生超过限制数量的 Lintian 警告
        log_lines = ["[   50s] Running lintian"]
        for i in range(400):
            log_lines.append(f"[   51s] W: pkg: lintian-warning-{i}")
        count, text = reporter.extract_warnings_from_log(log_lines, max_warnings=100)
        self.assertGreater(count, 100)
        self.assertIn("警告过多，已截断", text)

    def test_build_section_block(self):
        block = reporter.build_section_block("deepin_develop", "x86_64", 3, "W: pkg: test-warn")
        self.assertIn("<!-- SECTION: deepin_develop/x86_64 -->", block)
        self.assertIn("<!-- END_SECTION: deepin_develop/x86_64 -->", block)
        self.assertIn("<details>", block)
        self.assertNotIn("<details open>", block)  # 默认折叠
        self.assertIn("<summary><b>deepin_develop / x86_64</b> (Lintian 警告: 3 条)</summary>", block)
        self.assertIn("W: pkg: test-warn", block)

    def test_parse_and_generate_comment_sections(self):
        sha = "a1b2c3d4e5f6"
        sec_x86 = reporter.build_section_block("deepin_develop", "x86_64", 2, "W: pkg: warn x86")
        sec_arm = reporter.build_section_block("deepin_develop", "aarch64", 1, "W: pkg: warn arm")

        sections = {
            "deepin_develop/x86_64": sec_x86,
            "deepin_develop/aarch64": sec_arm
        }
        comment_body = reporter.generate_comment_body(sha, sections)
        self.assertIn("<!-- OBS_CI_BUILD_WARNING_REPORT commit: a1b2c3d4e5f6 -->", comment_body)
        self.assertIn("### ⚠️ OBS CI 构建警告日志 (Commit: `a1b2c3d4`)", comment_body)
        self.assertIn("deepin_develop / x86_64", comment_body)
        self.assertIn("deepin_develop / aarch64", comment_body)

        parsed_sections = reporter.parse_comment_sections(comment_body)
        self.assertEqual(len(parsed_sections), 2)
        self.assertIn("deepin_develop/x86_64", parsed_sections)
        self.assertIn("deepin_develop/aarch64", parsed_sections)

    def test_generate_comment_body_empty_sections(self):
        sha = "1234567890ab"
        comment_body = reporter.generate_comment_body(sha, {})
        self.assertIn("### ✅ OBS CI 构建警告日志", comment_body)
        self.assertIn("所有架构构建完成，未发现 Lintian 警告。", comment_body)

    def test_extract_comment_commit_sha(self):
        body = "<!-- OBS_CI_BUILD_WARNING_REPORT commit: 998877665544 -->\nsome content"
        sha = reporter.extract_comment_commit_sha(body)
        self.assertEqual(sha, "998877665544")

        self.assertIsNone(reporter.extract_comment_commit_sha("regular comment"))

    def test_resolve_pr_number(self):
        pr1 = reporter.resolve_pr_number("deepin:CI:linuxdeepin:dtkcore:PR-45", "linuxdeepin/dtkcore", "sha1", "tok")
        self.assertEqual(pr1, 45)

        pr2 = reporter.resolve_pr_number("deepin:CI:peeweep-test:test-pkg:PR-102", "peeweep-test/test-pkg", "sha2", "tok")
        self.assertEqual(pr2, 102)

        # Topic project fallback to GitHub API
        with patch("requests.get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.json.return_value = [{"number": 789}]
            mock_get.return_value = mock_resp

            pr3 = reporter.resolve_pr_number("deepin:CI:topics:some-topic", "linuxdeepin/dtkcore", "sha3", "tok")
            self.assertEqual(pr3, 789)

    @patch("requests.post")
    @patch("requests.patch")
    @patch("requests.get")
    def test_sync_pr_warning_comment_create_new(self, mock_get, mock_patch, mock_post):
        # 模拟没有现有评论
        mock_get_resp = MagicMock()
        mock_get_resp.status_code = 200
        mock_get_resp.json.return_value = []
        mock_get.return_value = mock_get_resp

        mock_post_resp = MagicMock()
        mock_post_resp.status_code = 201
        mock_post.return_value = mock_post_resp

        # 情况 1: 0 警告 -> 不发送评论
        reporter.sync_pr_warning_comment("owner/repo", 12, "sha123456", "repo_dev", "x86_64", 0, "", "token")
        mock_post.assert_not_called()
        mock_patch.assert_not_called()

        # 情况 2: 有警告 -> 发送新评论 (POST)
        reporter.sync_pr_warning_comment("owner/repo", 12, "sha123456", "repo_dev", "x86_64", 2, "warn line", "token")
        mock_post.assert_called_once()
        call_json = mock_post.call_args[1]["json"]
        self.assertIn("repo_dev / x86_64", call_json["body"])
        self.assertIn("<details>", call_json["body"])
        self.assertIn("warn line", call_json["body"])

    @patch("requests.post")
    @patch("requests.patch")
    @patch("requests.get")
    def test_sync_pr_warning_comment_update_existing_same_commit(self, mock_get, mock_patch, mock_post):
        # 已有 x86_64 警告评论
        existing_sec = reporter.build_section_block("repo_dev", "x86_64", 1, "x86 warning")
        existing_body = reporter.generate_comment_body("sha_same_123", {"repo_dev/x86_64": existing_sec})

        mock_get_resp = MagicMock()
        mock_get_resp.status_code = 200
        mock_get_resp.json.return_value = [
            {"id": 8888, "body": existing_body}
        ]
        mock_get.return_value = mock_get_resp

        mock_patch_resp = MagicMock()
        mock_patch_resp.status_code = 200
        mock_patch.return_value = mock_patch_resp

        # 新增 aarch64 架构的警告 -> 更新现有评论 (PATCH)，保留 x86_64 并追加 aarch64
        reporter.sync_pr_warning_comment("owner/repo", 12, "sha_same_123", "repo_dev", "aarch64", 3, "arm warning", "token")

        mock_post.assert_not_called()
        mock_patch.assert_called_once()
        patch_url = mock_patch.call_args[0][0]
        self.assertIn("/issues/comments/8888", patch_url)
        patched_body = mock_patch.call_args[1]["json"]["body"]
        self.assertIn("repo_dev / x86_64", patched_body)
        self.assertIn("repo_dev / aarch64", patched_body)
        self.assertIn("x86 warning", patched_body)
        self.assertIn("arm warning", patched_body)

    @patch("requests.post")
    @patch("requests.patch")
    @patch("requests.get")
    def test_sync_pr_warning_comment_new_commit_resets(self, mock_get, mock_patch, mock_post):
        # 旧 Commit 的评论
        old_sec = reporter.build_section_block("repo_dev", "x86_64", 5, "old commit warning")
        old_body = reporter.generate_comment_body("sha_old_1111", {"repo_dev/x86_64": old_sec})

        mock_get_resp = MagicMock()
        mock_get_resp.status_code = 200
        mock_get_resp.json.return_value = [
            {"id": 9999, "body": old_body}
        ]
        mock_get.return_value = mock_get_resp

        mock_patch_resp = MagicMock()
        mock_patch_resp.status_code = 200
        mock_patch.return_value = mock_patch_resp

        # 新 Commit "sha_new_2222" 到达，新架构有 1 条警告 -> 覆盖重置为新 commit
        reporter.sync_pr_warning_comment("owner/repo", 12, "sha_new_2222", "repo_dev", "x86_64", 1, "new warning", "token")

        mock_post.assert_not_called()
        mock_patch.assert_called_once()
        patched_body = mock_patch.call_args[1]["json"]["body"]
        self.assertIn("sha_new_2222", patched_body)
        self.assertIn("new warning", patched_body)
        self.assertNotIn("old commit warning", patched_body)

    @patch("requests.patch")
    @patch("requests.get")
    def test_sync_pr_warning_comment_warning_resolved(self, mock_get, mock_patch):
        # 原本只有 x86_64 存在警告
        existing_sec = reporter.build_section_block("repo_dev", "x86_64", 1, "x86 warning")
        existing_body = reporter.generate_comment_body("sha_fixed_123", {"repo_dev/x86_64": existing_sec})

        mock_get_resp = MagicMock()
        mock_get_resp.status_code = 200
        mock_get_resp.json.return_value = [{"id": 7777, "body": existing_body}]
        mock_get.return_value = mock_get_resp

        mock_patch_resp = MagicMock()
        mock_patch_resp.status_code = 200
        mock_patch.return_value = mock_patch_resp

        # 重新构建后，x86_64 警告数变为 0 -> 折叠块被移除，评论更新为无警告状态
        reporter.sync_pr_warning_comment("owner/repo", 12, "sha_fixed_123", "repo_dev", "x86_64", 0, "", "token")

        mock_patch.assert_called_once()
        patched_body = mock_patch.call_args[1]["json"]["body"]
        self.assertIn("所有架构构建完成，未发现 Lintian 警告。", patched_body)
        self.assertNotIn("<!-- SECTION: repo_dev/x86_64 -->", patched_body)

    @patch("requests.get")
    def test_fetch_obs_build_log(self, mock_get):
        # 成功获取
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.iter_lines.return_value = [
            "line 1: compiling...",
            "line 2: warning: test",
            "line 3: done"
        ]
        mock_get.return_value = mock_resp

        lines = reporter.fetch_obs_build_log("https://obs.example.com", "user", "pass", "proj", "repo", "x86_64", "pkg")
        self.assertIsNotNone(lines)
        self.assertEqual(len(lines), 3)

        # 404 返回 None
        mock_resp_404 = MagicMock()
        mock_resp_404.status_code = 404
        mock_get.return_value = mock_resp_404
        self.assertIsNone(reporter.fetch_obs_build_log("https://obs.example.com", "user", "pass", "proj", "repo", "x86_64", "pkg"))

        # 网络异常返回 None
        mock_get.side_effect = Exception("network timeout")
        self.assertIsNone(reporter.fetch_obs_build_log("https://obs.example.com", "user", "pass", "proj", "repo", "x86_64", "pkg"))

    def test_generate_comment_body_truncation(self):
        # 测试评论总长度超出限制时的保护截断
        giant_text = "x" * 70000
        sections = {"repo/arch": giant_text}
        body = reporter.generate_comment_body("sha_trunc_123", sections)
        self.assertLessEqual(len(body), reporter.MAX_COMMENT_LENGTH)
        self.assertIn("评论内容过长，已截断", body)


if __name__ == '__main__':
    unittest.main()
