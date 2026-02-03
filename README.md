# Android 命令行工具集

* 项目地址：[Github](https://github.com/getActivity/AndroidCmdTools)

* 文章介绍：[都 2026 了，还有人在手敲命令行？](https://juejin.cn/post/7602411521070825491)

#### 项目简介

* AndroidCmdTools 是基于 Android 开发中常用命令行封装的项目，基本涵盖 Android 开发和测试的方方面面，项目采用 shell 脚本语言编写，提供一键执行的脚本文件，方便开发者和测试人员使用。

#### 项目亮点

* 支持多平台：macOs、Windows、Linux

* 支持多任务执行：批量安装、批量卸载、批量签名、批量授权等

* 支持多设备并行：可指定设备执行任务，也可全部设备执行任务

* 功能非常简单：不需要记命令行，更不需要敲命令行，点击脚本（Windows 提供 bat 脚本，macOs 提供 command 脚本，Linux 提供 sh 脚本）即可运行，输入参数即可完成你想要的任务。

* 功能非常全面：涵盖设备交互、逆向工具、Git 版本管理、包体工具，几乎涵盖 Android 开发的方方面面，你能想到的我都想到了，没有想到的我也帮你想到了

一个跨平台的 Android 命令集合，封装常用开发、测试、打包与逆向工具，提供开箱即用的 .command（macOS）与 .bat（Windows）脚本。覆盖设备交互、签名与包体处理、逆向分析、格式转换、Git 辅助等高频场景，让工程同学与测试同学无需记忆繁杂命令。

#### 项目集成

* 一. 下载项目到本地

    * 克隆项目（推荐，可通过 Git 更新）

    * 下载项目（不推荐，无法通过 Git 更新）

* 二. 为脚本添加执行权限（macOs 或 Linux 系统必须，Windows 可跳过此步骤）

    * 进入项目根目录（xxx 请替换成项目所在路径）
    
    ```bash
    cd xxx/AndroidCmdTools
    ```
    
    * 递归为所有脚本文件添加执行权限
    
    ```bash
    find . -type f -exec chmod +x {} \;
    ```

* 三. 集成 Shell Bash 环境（Windows 系统必须，macOs 或 Linux 系统可跳过此步骤）

    * 下载 Git Bash 工具

        * 由于 Git Bash 是捆绑在 Git 工具中的，所以需要下载 Git 工具

            * [Windows Git 下载](https://git-scm.com/install/windows)

            * [macOs Git 下载](https://git-scm.com/install/mac)

            * [Linux Git 下载](https://git-scm.com/install/linux)

    * 安装 Git Bash 工具

        * 在安装时勾选 “Git Bash Here” 选项，方便后续使用

    * 配置 Git Bash 环境

        * 注意事项：Git 在安装时默认只配置了 Git 环境，没有配置 Git Bash 环境

        * 注意覆盖安装 Git 很可能会导致 Git Bash 环境变量丢失，需要重新配置

    * 配置 Windows 系统环境变量

        * 右击《我的电脑》 —> 点击《属性》 —> 点击《高级系统设置》
    
        * 在系统环境变量找到 Path 中，添加 Git Bash 所处的路径，例如 `C:\Program Files\Git\bin`
    
        * 在《编辑系统变量》窗口中保存修改，点击《确定》按钮
    
        * 在《系统变量》窗口也要保存修改，点击《确定》按钮
    
        * 在《系统属性》窗口也要保存修改，点击《确定》按钮
    
    * 验证 Git Bash 环境是否配置成功

        * 关闭已打开的所有命令行窗口

        * 在桌面右击空白处，选择《Git Bash Here》，打开 Git Bash 终端，执行命令 `bash --version`，如果输出版本信息，则表示配置成功

        * 若你无法通过《Git Bash Here》打开 Git Bash 终端，则证明你前面安装的 Git Bash 和当前 Windows 系统版本可能存在兼容问题，解决方法如下：

            * 去系统环境变量配置中，移除刚刚给 Git Bash 配置的环境变量

            * 下载 [WindowsBash](https://pan.baidu.com/s/14qZiU9BWvJae_JwyzHiR1w?pwd=6666)

            * 解压 WindowsBash 压缩包，推荐解压到 `C:\Program Files\WindowsBash` 这个目录下

            * 然后尝试打开 `C:\Program Files\WindowsBash\bin\bash.exe` 看看是否能正常打开 Bash 终端，如果能正常打开，则说明 WindowsBash 兼容当前 Windows 系统

            * 在系统环境变量 Path 中，添加 WindowsBash 所在的路径，例如 `C:\Program Files\WindowsBash\bin`，然后保存修改

            * 关闭已打开的所有命令行窗口，然后同时按下 `Windows 键 + R 键`，输入 `cmd` 打开《命令行提示符》，执行命令 `bash --version`，如果输出版本信息，则表示配置成功

#### 项目内容

* 《设备交互》

    * 《刷机相关》

        * 判断设备是否有锁

        * 重启到 fastboot 模式

        * 重启到 recovery 模式

        * 加载临时的 recovery

        * 刷入新的 recovery

        * 查看设备机型代号

    * 《模拟相关》

        * 模拟文本输入

        * 模拟按下电源键

        * 模拟按下返回键

        * 模拟按下主页键

        * 模拟按下多任务键

        * 模拟按下菜单键

        * 模拟屏幕点击

    * 《环境相关》

        * 重启 adb 进程

        * 杀死 adb 进程

        * 获取当前电脑环境的 adb 版本

        * 获取当前电脑环境的 fastboot 版本

    * 《硬件相关》

        * 设备关机

        * 设备重启

    * 《跳转相关》

        * 跳转到指定的 URL

        * 跳转到指定的 Activity

        * 跳转到开发者选项

        * 跳转到关于本机

        * 跳转到微信主界面

    * 《其他设备操作》

        * 安装应用

        * 卸载应用

        * 设置全局代理

        * 清除全局代理

        * 管理设备文件

        * 保存截图到电脑

        * 保存录屏到电脑

        * 开启无线调试

        * 断开无线调试

        * 获取栈顶 Activity 包名

        * 获取栈顶 Activity 内容

        * 导出应用 apk

        * 导出 ANR 日志

        * 清除应用数据

        * 杀死应用进程

        * 冻结特定应用

        * 解冻特定应用

        * 授予应用权限

        * 撤销应用权限

        * 查看屏幕参数

        * 查看系统属性

        * 查看设备序列号

        * 获取设备 CPU 架构

        * 跑 MonkeyTest

        * 查看设备 Logcat

* 《逆向工具》

    * 《apktool》

        * 用 apktool 反编译 apk

        * 用 apktool 回编译 apk

    * 《jadx》

        * 用 jadx 查看包体

    * 《jd-gui》

        * 用 jd-gui 查看包体

    * 《格式转换》

        * 《dex 和 class 互转》

            * dex 转 class

            * class 转 dex

        * 《dex 和 smali 互转》

            * dex 转 smali

            * smali 转 dex

        * 《jar 和 dex 互转》

            * jar 转 dex

            * dex 转 jar

* 《Git 工具》

    * 《推送相关》

        * 强制推送本地分支到远端

        * 强制推送本地标签到远端

    * 《提交相关》

        * 《修改提交》

            * 修改最后一次提交的消息

            * 修改最后一次提交的时间

            * 修改最后一次提交的用户名和邮箱

            * 修改某一个用户所有已提交的用户名和邮箱

        * 《回滚提交》

            * 回退到指定的提交上

            * 撤销某一个提交的内容

    * 《配置相关》

        * 打开 Git 配置文件

        * 一键设置 Git 最佳配置

        * 设置 Git 用户名和邮箱

        * 设置 Git 文本编码配置

        * 设置 Git 文本换行符配置

        * 设置 Git 文件权限配置

    * 拉取远端 Git 项目到本地

    * 为某个目录创建 Git 版本管理

    * 用 Git 对比两个文件之间的差异

* 《包体工具》

    * 对 apk 进行签名

    * 获取 apk 签名信息

    * support 转 androidx

    * androidx 转 support

    * apk aar jar aab 包体比较

* 《秘钥工具》

    * 查看已有 SSH 公钥

    * 创建新的 SSH 密钥

    * 删除已有 SSH 密钥

    * 打开 SSH 秘钥文件所在的目录

#### 作者的其他开源项目

* 安卓技术中台：[AndroidProject](https://github.com/getActivity/AndroidProject) ![](https://img.shields.io/github/stars/getActivity/AndroidProject.svg) ![](https://img.shields.io/github/forks/getActivity/AndroidProject.svg)

* 安卓技术中台 Kt 版：[AndroidProject-Kotlin](https://github.com/getActivity/AndroidProject-Kotlin) ![](https://img.shields.io/github/stars/getActivity/AndroidProject-Kotlin.svg) ![](https://img.shields.io/github/forks/getActivity/AndroidProject-Kotlin.svg)

* 权限框架：[XXPermissions](https://github.com/getActivity/XXPermissions) ![](https://img.shields.io/github/stars/getActivity/XXPermissions.svg) ![](https://img.shields.io/github/forks/getActivity/XXPermissions.svg)

* 吐司框架：[Toaster](https://github.com/getActivity/Toaster) ![](https://img.shields.io/github/stars/getActivity/Toaster.svg) ![](https://img.shields.io/github/forks/getActivity/Toaster.svg)

* 网络框架：[EasyHttp](https://github.com/getActivity/EasyHttp) ![](https://img.shields.io/github/stars/getActivity/EasyHttp.svg) ![](https://img.shields.io/github/forks/getActivity/EasyHttp.svg)

* 标题栏框架：[TitleBar](https://github.com/getActivity/TitleBar) ![](https://img.shields.io/github/stars/getActivity/TitleBar.svg) ![](https://img.shields.io/github/forks/getActivity/TitleBar.svg)

* 悬浮窗框架：[EasyWindow](https://github.com/getActivity/EasyWindow) ![](https://img.shields.io/github/stars/getActivity/EasyWindow.svg) ![](https://img.shields.io/github/forks/getActivity/EasyWindow.svg)

* 设备兼容框架：[DeviceCompat](https://github.com/getActivity/DeviceCompat) ![](https://img.shields.io/github/stars/getActivity/DeviceCompat.svg) ![](https://img.shields.io/github/forks/getActivity/DeviceCompat.svg)

* ShapeView 框架：[ShapeView](https://github.com/getActivity/ShapeView) ![](https://img.shields.io/github/stars/getActivity/ShapeView.svg) ![](https://img.shields.io/github/forks/getActivity/ShapeView.svg)

* ShapeDrawable 框架：[ShapeDrawable](https://github.com/getActivity/ShapeDrawable) ![](https://img.shields.io/github/stars/getActivity/ShapeDrawable.svg) ![](https://img.shields.io/github/forks/getActivity/ShapeDrawable.svg)

* 语种切换框架：[MultiLanguages](https://github.com/getActivity/MultiLanguages) ![](https://img.shields.io/github/stars/getActivity/MultiLanguages.svg) ![](https://img.shields.io/github/forks/getActivity/MultiLanguages.svg)

* Gson 解析容错：[GsonFactory](https://github.com/getActivity/GsonFactory) ![](https://img.shields.io/github/stars/getActivity/GsonFactory.svg) ![](https://img.shields.io/github/forks/getActivity/GsonFactory.svg)

* 日志查看框架：[Logcat](https://github.com/getActivity/Logcat) ![](https://img.shields.io/github/stars/getActivity/Logcat.svg) ![](https://img.shields.io/github/forks/getActivity/Logcat.svg)

* 嵌套滚动布局框架：[NestedScrollLayout](https://github.com/getActivity/NestedScrollLayout) ![](https://img.shields.io/github/stars/getActivity/NestedScrollLayout.svg) ![](https://img.shields.io/github/forks/getActivity/NestedScrollLayout.svg)

* Android 版本适配：[AndroidVersionAdapter](https://github.com/getActivity/AndroidVersionAdapter) ![](https://img.shields.io/github/stars/getActivity/AndroidVersionAdapter.svg) ![](https://img.shields.io/github/forks/getActivity/AndroidVersionAdapter.svg)

* Android 代码规范：[AndroidCodeStandard](https://github.com/getActivity/AndroidCodeStandard) ![](https://img.shields.io/github/stars/getActivity/AndroidCodeStandard.svg) ![](https://img.shields.io/github/forks/getActivity/AndroidCodeStandard.svg)

* Android 资源大汇总：[AndroidIndex](https://github.com/getActivity/AndroidIndex) ![](https://img.shields.io/github/stars/getActivity/AndroidIndex.svg) ![](https://img.shields.io/github/forks/getActivity/AndroidIndex.svg)

* Android 开源排行榜：[AndroidGithubBoss](https://github.com/getActivity/AndroidGithubBoss) ![](https://img.shields.io/github/stars/getActivity/AndroidGithubBoss.svg) ![](https://img.shields.io/github/forks/getActivity/AndroidGithubBoss.svg)

* Studio 精品插件：[StudioPlugins](https://github.com/getActivity/StudioPlugins) ![](https://img.shields.io/github/stars/getActivity/StudioPlugins.svg) ![](https://img.shields.io/github/forks/getActivity/StudioPlugins.svg)

* 表情包大集合：[EmojiPackage](https://github.com/getActivity/EmojiPackage) ![](https://img.shields.io/github/stars/getActivity/EmojiPackage.svg) ![](https://img.shields.io/github/forks/getActivity/EmojiPackage.svg)

* AI 资源大汇总：[AiIndex](https://github.com/getActivity/AiIndex) ![](https://img.shields.io/github/stars/getActivity/AiIndex.svg) ![](https://img.shields.io/github/forks/getActivity/AiIndex.svg)

* 省市区 Json 数据：[ProvinceJson](https://github.com/getActivity/ProvinceJson) ![](https://img.shields.io/github/stars/getActivity/ProvinceJson.svg) ![](https://img.shields.io/github/forks/getActivity/ProvinceJson.svg)

* Markdown 语法文档：[MarkdownDoc](https://github.com/getActivity/MarkdownDoc) ![](https://img.shields.io/github/stars/getActivity/MarkdownDoc.svg) ![](https://img.shields.io/github/forks/getActivity/MarkdownDoc.svg)

#### 微信公众号：Android轮子哥

![](https://raw.githubusercontent.com/getActivity/Donate/master/picture/official_ccount.png)

#### Android 技术 Q 群：10047167

#### 如果您觉得我的开源库帮你节省了大量的开发时间，请扫描下方的二维码随意打赏，要是能打赏个 10.24 :monkey_face:就太:thumbsup:了。您的支持将鼓励我继续创作:octocat:（[点击查看捐赠列表](https://github.com/getActivity/Donate)）

![](https://raw.githubusercontent.com/getActivity/Donate/master/picture/pay_ali.png) ![](https://raw.githubusercontent.com/getActivity/Donate/master/picture/pay_wechat.png)

## License

```text
Copyright 2026 Huang JinQun

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```