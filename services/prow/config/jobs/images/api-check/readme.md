# API接口检查

## 检查介绍
API接口检查PR中文件是否存在对外接口修改和删除

### 检测到存在对外接口删除和修改

例如评论中显示:
> [!WARNING]
> [API接口检查]
* 检测到存在对外接口删除和修改;
<details>
<summary>详情</summary>

```ruby
	--- CHECK CHANGE IN <test.go> ---
[Chg_exprort_fun] : func circleArea(radius float64) (float64, error) 
[Add_fun] : func circleArea(radius float64) (float64, error)
[Del_export_fun] :  PopupWindowManager(QWidget * parent=nullptr)
```
</details>

详情中是检测日志结果，该日志表示根据当前PR中的变更文件检测到存在对外接口删除和修改，`[Chg_exprort_fun]`和`[Del_export_fun]`信息提示变动的对外接口信息。

当遇到该提示信息，如果确实存在问题，请更正；若果是其他情况，如有必要，请联系系统开发人员liujianqiang-niu审核合并。