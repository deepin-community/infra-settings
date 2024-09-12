# 静态代码检查

## 检查介绍
静态代码检查根据报错提示信息分为5类:
- cppcheck检查失败, 检测到*个error;
- tscancode检查失败, 检测到*个error;
- gosec检查失败, 检测到*个error;
- golangci-lint检查失败, 检测到*个error;
- shellcheck检查失败, 检测到*个error;

### cppcheck检查失败, 检测到*个error
使用静态代码检查工具cppcheck对PR中的文件(*.cpp, *.cxx, *.cc, *.c++, *.c, *.ipp,
*.ixx, *.tpp, 和 *.txx)进行检查，检查发现达到error级别的告警则显示该错误信息。

例如评论中显示:
> [!Note]
> [静态代码检查]
* cppcheck检查失败, 检测到1个error;
<details>
<summary>详情</summary>

```xml
<?xml version="1.0" encoding="UTF-8"?>
<results version="2">
  <cppcheck version="2.8"/>
    <errors>
      <error id="unusedFunction" severity="error" msg="The function &apos;ExportFeedbackLog&apos; is never used." verbose="The function &apos;ExportFeedbackLog&apos; is never used." cwe="561">
        <location file="src/udcp-daemon/udcp-guard/message_hub.cpp" line="209" column="0"/>
        <symbol>ExportFeedbackLog</symbol>
      </error>
      <error id="unusedFunction" severity="style" msg="The function &apos;GetMachineID&apos; is never used." verbose="The function &apos;GetMachineID&apos; is never used." cwe="561">
        <location file="src/udcp-daemon/udcp-guard/message_hub.cpp" line="103" column="0"/>
        <symbol>GetMachineID</symbol>
      </error>
    </errors>
</results>
```
</details>

表示cppcheck检测到当前PR存在1个error级别的告警，详情是检查日志，其中`severity="error"`表示cppcheck检测到的告警级别，`msg=`字段获取具体告警信息，`file=`字段获取存在告警信息的文件路径。

当遇到该提示信息，请根据实际情况酌情更正。

### tscancode检查失败, 检测到*个error
使用静态代码检查工具tscancode对PR中的文件(*.cpp, *.cxx, *.cc, *.c++, *.c,
*.tpp, 和 *.txx)进行检查，检查发现达到error级别的告警则显示该错误信息。

例如评论中显示:
> [!Note]
> [静态代码检查]
* tscancode检查失败, 检测到1个error;
<details>
<summary>详情</summary>

```xml
<?xml version="1.0" encoding="UTF-8"?>
<results>
    <error file="/home/jenkins/workspace/uos-eagle/uos-exprimental/ci-check/gerrit-static-check-review-pipeline/src/common/base/baseutils.cpp" line="666"
 id="memleak" subid="resourceLeak" severity="Serious" msg="Resource leak: fd" web_identify="{&quot;identify&quot;:&quot;fd&quot;}" func_info="" content="
656:     const std::string &amp;pidBuffer = QString(&quot;%1&quot;).arg(getpid()).toStdString();
657:     ftruncate(fd, 0);
"/>
</results>
```
</details>

表示tscancode检测到当前PR存在1个error级别的告警，详情是检查日志，其中`severity="Serious"`表示tscancode检查告警级别，这里设置tscancode检查结果告警级别是Serious和Critical的都达到CI告警error级别，`msg=`字段获取具体告警信息，`file=`字段获取存在告警信息的文件路径, `content=`字段获取告警信息的具体内容。

当遇到该提示信息，请根据实际情况酌情更正。

### gosec检查失败, 检测到*个error
使用静态代码检查工具gosec对PR中的go文件进行检查，检查发现error级别的告警则显示该错误信息。

例如评论中显示:
> [!Note]
> [静态代码检查]
* gosec检查失败, 检测到1个error;
<details>
<summary>详情</summary>

```json
{
  "Issues": [
    {
      "severity": "HIGH",
      "confidence": "MEDIUM",
      "cwe": {
        "id": "338",
        "url": "https://cwe.mitre.org/data/definitions/338.html"
      },
      "rule_id": "G404",
      "details": "Use of weak random number generator (math/rand instead of crypto/rand)",
      "file": "/home/uos/test/gosec-test/dde-daemon/bluetooth/obex_agent.go",
      "code": "363: \tcharlen := len(charArr)\n364: \tran := rand.New(rand.NewSource(time.Now().Unix()))\n365: \tvar rchar string = \"\"\n",
      "line": "364",
      "column": "9",
      "nosec": false,
      "suppressions": null
    }
  ]
}
```
</details>

表示gosec检测到当前PR存在1个error级别的告警，详情是检查日志，其中Issues部分中`"severity": "HIGH"`表示gosec检查告警级别，这里设置gosec检查结果告警级别是HIGH的都达到CI告警error级别，`"code":`字段获取具体告警信息，`file=`字段获取存在告警信息的文件路径。

当遇到该提示信息，请根据实际情况酌情更正。

### golangci-lint检查失败, 检测到*个error
使用静态代码检查工具golangci-lint对PR中的go文件进行检查，检查发现error级别的告警则显示该错误信息。

例如评论中显示:
> [!Note]
> [静态代码检查]
* golangci-lint检查失败, 检测到1个error;
<details>
<summary>详情</summary>

```xml
<testsuites>
  <testsuite name="dde-daemon/keybinding/manager.go" tests="50" errors="1" failures="1">
    <testcase name="typecheck" classname="dde-daemon/keybinding/manager.go:137:32">
      <error message="dde-daemon/keybinding/manager.go:137:32: undefined: SpecialKeycodeMapKey" type=""><![CDATA[: undefined: SpecialKeycodeMapKey
Category: typecheck
File: dde-daemon/keybinding/manager.go
Line: 137
Details:        specialKeycodeBindingList map[SpecialKeycodeMapKey]func()]]></error>
    </testcase>
    <testcase name="typecheck" classname="dde-daemon/keybinding/manager.go:140:25">
      <failure message="dde-daemon/keybinding/manager.go:140:25: undefined: AudioController" type=""><![CDATA[: undefined: AudioController
Category: typecheck
File: dde-daemon/keybinding/manager.go
Line: 140
Details:        audioController       *AudioController]]></failure>
    </testcase>
  </testsuite>
</testsuites>
</results>
```
</details>

表示golangci-lint检测到当前PR存在1个error级别的告警，详情是检查日志，其中`<testsuite name="dde-daemon/keybinding/manager.go" tests="50" errors="1" failures="1">`是检查检查汇总结果，`<error`所在字段表示error级别的告警信息，其中包含的`message=`字段信息可以获得具体告警信息。

当遇到该提示信息，请根据实际情况酌情更正。

### shellcheck检查失败, 检测到*个error
使用静态代码检查工具shellcheck对PR中的文件(*.sh, *.bash)进行检查，检查发现error级别的告警则显示该错误信息。

例如评论中显示:
> [!Note]
> [静态代码检查]
* shellcheck检查失败, 检测到1个error;
<details>
<summary>详情</summary>

```xml
<?xml version='1.0' encoding='UTF-8'?>
<checkstyle version='4.3'>
<file name='test.sh' >
<error line='1' column='1' severity='error' message='Tips depend on target shell and yours is unknown. Add a shebang or a &#39;shell&#39; directive.' source='ShellCheck.SC2148' />
<error line='3' column='6' severity='warning' message='lshw is referenced but not assigned.' source='ShellCheck.SC2154' />
<error line='3' column='6' severity='info' message='Double quote to prevent globbing and word splitting.' source='ShellCheck.SC2086' />
</file>
</checkstyle>
```
</details>

表示shellcheck检测到当前PR存在1个error级别的告警，详情是检查日志，其中`<file name='test.sh' >`字段获取存在告警信息的文件路径`severity='error`字段表示告警级别，`message=`字段获得具体告警信息，`source=`字段获取告警信息告警编码。

当遇到该提示信息，请根据实际情况酌情更正。