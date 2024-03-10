# Archlinux 自动打包

## 使用方法

将以下内容添加到 `/etc/pacman.conf`（我自己个人使用添加在`[core]`之上）:

```ini
[auryouth]
SigLevel = Optional TrustAll
Server = https://github.com/auryouth/archbuild/releases/latest/download
```

## 实现

### Job1: Check

* 获取每次提交前后变化的文件
* 判断每个`package`目录下文件是否变化(主要是`PKGBUILD`和一些`source`)，
并结合依云的[nvchecker](https://github.com/lilydjwg/nvchecker)判断`version`是否变化，判断是否需要更新
* 提交`oldver_file`

### Job2: Build (if needs.check.outputs.status = 'true')

* `build action` 通过 `matrix` 分开打包并分开`git commit`
* 上传打包好的 `asset`
* 删除`package release` 下的的旧包

### Job3: Release ( needs: Build )

* 下载上传的 `asset`
* `repo-add action` 更新数据库
* `action-gh-release` 发布
* Telegram 通知打包完成

## 管理

* 添加包
    * 在目录下的`nvchecker.toml`（这是`nvcheck-and-update action`定义的默认值，可以通过输入`nvfile`更改）填写好信息，然后在目录下创建包的文件夹（**注意名称的一致性，否则会失败，目前要求二者的名称与PKGBUILD的pkgname必须一致**）
* 删除包
    * 删除目录(可选)和`nvchecker.toml`的配置文件
    * 删除`release`上的旧包(可选)
    * `oldver_file`下的信息，也可以选择跑一遍`nvchecker`然后`nvtake -c nvchecker.toml --all`自动更新