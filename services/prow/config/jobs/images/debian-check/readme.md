# Debian检查

## 检查介绍
Debian检查根据报错提示信息分为3类:
- 检测到debian目录文件有变更
- debian/changelog版本检查失败
- 检测到敏感词**变动

### 检测到debian目录文件有变更
当PR中变更文件(除了"debian/changelog", "debian/copyright", "debian/compat", "debian/source/format")包含debian目录下的文件，则显示该错误信息。

例如评论中显示:
> [!WARNING]
> [Debian检查]
* 检测到debian目录文件有变更: debian/test.log

表示当前PR中存在debian目录下文件"debian/test.log"变更。

当遇到该提示信息，如有必要，需要联系系统开发人员liujianqiang-niu审核该文件变更是否合规。

### debian/changelog版本检查失败
当PR中变更文件包含debian/changelog，则使用`dpkg --compare-versions {newversion} gt {oldversion}`对比检查changelog中最新的2个版本设置，
如最新版本(newversion)大于上个版本(oldversion)，则检查通过，否则检查失败，显示该错误信息。

例如评论中显示:
> [!WARNING]
> [Debian检查]
* debian/changelog版本检查失败:4:5.27.2.201-deepin200-1|4:5.27.2.201-deepin201-1

表示当前PR中存在debian/changelog文件变更，且`4:5.27.2.201-deepin200-1|4:5.27.2.201-deepin201-1`即`newversion|oldversion`,newversion不大于oldversion。

当遇到该提示信息，请仔细检查debian/changelog文件中的最新的2个版本设置并更正。

### 检测到敏感词**变动
按照系统部要求,PR变更文件中不能出现"getcap,setcap,lshw,dmidecode,export,unset"的命令敏感词，如果检测匹配到对应的敏感词则显示该错误信息。

例如评论中显示:
> [!WARNING]
> [Debian检查]
* 检测到敏感词lshw变动;
<details>
<summary>详情</summary>

```json
{
    "lshw": {
        "test.sh": [
            "echo $lshw"
        ]
    }
}
```
</details>

详情表示当前PR变更文件`test.sh`中内容是`"echo $lshw"`的这一行检测匹配到`lshw`命令敏感词。

当遇到该提示信息，如果确实是使用了lshw命令，请更正；若类似上述只是其他引用，如有必要，请联系系统开发人员liujianqiang-niu审核合并。