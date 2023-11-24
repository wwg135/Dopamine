# 当前更新日志如下：

> - 1.同步官方1.1.11正式版更新。
> - 2.合并普通版、KFD版、挂载版一起发布，后续分开接收对应版本的OTA升级，互不干扰。
> - 3.普通版为Dopamine.ipa，kfd版为KFDDopamine.ipa，挂载版为Dopamine_mount.ipa。下载对应版本，后续就收到对应版本OTA升级，不会跨版本。
> - 4.当前版本必须手动下载安装，因为改变了OTA升级逻辑。

# 官方更新日志如下：
> - 修复“内核堆栈指针无效”随机崩溃
> - 将 forkfix 应用于 和 函数的分叉daemon()forkpty()
> - 修复了 codesign 绕过中的一个 bug，即在极少数情况下，错误的切片可能会被信任缓存，从而导致二进制文件无法生成
> - 修复了系统范围钩子中的一个小错误execve
> - 此更新的所有更改均由roothide贡献

KFDopamine-BETA.tipa：
使用 kfd 而不是 oobPCI 的多巴胺实验性测试版，目前这是一个辅助版本，因为 PAC 旁路似乎更不可靠，并且 PAC 和 PPL 旁路期间的进度更新和详细日志被破坏。此版本增加了对 iOS 15.5b1 - 15.5b3 的支持，它还消除了对 15.0 - 15.1.1 的 Wi-Fi 修复的需要。即将推出的多巴胺版本将添加一个漏洞利用选择器，此版本只是一个权宜之计，因为该版本还很遥远。越狱后的环境是1：1一样的，稳定性也是一样的，只是利用过程不同。
重要说明：此版本由玩具胶水固定在一起，并不反映带有漏洞选取器的最终版本将具有的漏洞利用可靠性

# M哥修改版的功能

> - 1.普通版为Dopamine.ipa，kfd版为KFDDopamine.ipa，挂载版为Dopamine_mount.ipa（安装对应版本后续支持OTA单独升级版本，不会跨版本升级）.
> - 2.增加真皮底层屏蔽App越狱检测开关（首页点击“Dopamine”即显示/隐藏），感谢真皮大佬.
> - 3.修改app标识符，可与官方版本共存.
> - 4.增加重启、更新环境按钮（长按重启用户空间弹出），感谢liam0205大佬代码.
> - 5.设置增加显示/隐藏式功能（点击设置里面的“成功率”，即可开启显示/隐藏）.
> - 6.增加检查更新功能，以便开启/关闭OTA升级提示.
> - 7.首页增加运行时间显示（点击首页开发者信息，即可显示/隐藏）.
> - 8.增加自定义背景（首页长按背景即可，开关：从相册选择图片或者恢复默认）.
> - 9.改变下载进度条，添加到首页下方.
> - 10.设置增加“一键备份”功能，点击有详细说明。
> - 11.增加“清除越狱”提示，避免越狱状态下清除越狱出现未知问题.
> - 12.增加“映射挂载”功能，越狱前点击设置中的成功率显示、隐藏打开开关，越狱后显示.
> - 13.增加“桥接心浪”功能，以便以 XinA 的模式安装有根插件，感谢liam0205大佬代码.
> - 14.其他优化及新功能开发中，敬请期待...