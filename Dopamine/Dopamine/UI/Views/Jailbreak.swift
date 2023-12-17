//
//  Jailbreak.swift
//  Fugu15
//
//  Created by exerhythm on 03.04.2023.
//

import UIKit
import Fugu15KernelExploit
import CBindings
import Foundation

var fakeRootPath: String? = nil
public func rootifyPath(path: String) -> String? {
    if fakeRootPath == nil {
        fakeRootPath = Bootstrapper.locateExistingFakeRoot()
    }
    if fakeRootPath == nil {
        return nil
    }
    return fakeRootPath! + "/procursus/" + path
}

func getBootInfoValue(key: String) -> Any? {
    guard let bootInfoPath = rootifyPath(path: "/basebin/boot_info.plist") else {
        return nil
    }
    guard let bootInfo = NSDictionary(contentsOfFile: bootInfoPath) else {
        return nil
    }
    return bootInfo[key]
}

func respring() {
    guard let sbreloadPath = rootifyPath(path: "/usr/bin/sbreload") else {
        return
    }
    _ = execCmd(args: [sbreloadPath])
}

func userspaceReboot() {
    _ = execCmd(args: [rootifyPath(path: "/basebin/jbctl")!, "reboot_userspace"])
}

func reboot() {
    _ = execCmd(args: [CommandLine.arguments[0], "reboot"])
}

func isJailbroken() -> Bool {
    if isSandboxed() { return false } // ui debugging
    
    var jbdPid: pid_t = 0
    jbdGetStatus(nil, nil, &jbdPid)
    return jbdPid != 0
}

func isBootstrapped() -> Bool {
    if isSandboxed() { return false } // ui debugging
    
    return Bootstrapper.isBootstrapped()
}

func jailbreak(completion: @escaping (Error?) -> ()) {
    do {
        handleWifiFixBeforeJailbreak {message in 
            Logger.log(message, isStatus: true)
        }

        Logger.log("Launching kexploitd", isStatus: true)

        try Fugu15.launchKernelExploit(oobPCI: Bundle.main.bundleURL.appendingPathComponent("oobPCI")) { msg in
            DispatchQueue.main.async {
                var toPrint: String
                let verbose = !msg.hasPrefix("Status: ")
                if !verbose {
                    toPrint = String(msg.dropFirst("Status: ".count))
                }
                else {
                    toPrint = msg
                }

                Logger.log(toPrint, isStatus: !verbose)
            }
        }
        
        try Fugu15.startEnvironment()
        
        DispatchQueue.main.async {
            Logger.log(NSLocalizedString("Jailbreak_Done", comment: ""), type: .success, isStatus: true)
            completion(nil)
        }
    } catch {
        DispatchQueue.main.async {
            Logger.log("\(error.localizedDescription)", type: .error, isStatus: true)
            completion(error)
            NSLog("Fugu15 error: \(error)")
        }
    }
}

func removeJailbreak() {
    dopamineDefaults().removeObject(forKey: "selectedPackageManagers")
    _ = execCmd(args: [CommandLine.arguments[0], "uninstall_environment"])
    if isJailbroken() {
        reboot()
    }
}

func jailbrokenUpdateTweakInjectionPreference() {
    _ = execCmd(args: [CommandLine.arguments[0], "update_tweak_injection"])
}

func jailbrokenUpdateIDownloadEnabled() {
    let iDownloadEnabled = dopamineDefaults().bool(forKey: "iDownloadEnabled")
    _ = execCmd(args: [rootifyPath(path: "basebin/jbinit")!, iDownloadEnabled ? "start_idownload" : "stop_idownload"])
}

func changeMobilePassword(newPassword: String) {
    guard let dashPath = rootifyPath(path: "/usr/bin/dash") else {
        return;
    }
    guard let pwPath = rootifyPath(path: "/usr/sbin/pw") else {
        return;
    }
    _ = execCmd(args: [dashPath, "-c", String(format: "printf \"%%s\\n\" \"\(newPassword)\" | \(pwPath) usermod 501 -h 0")])
}

func update(tipaURL: URL) {
    DispatchQueue.global(qos: .userInitiated).async {
        jbdUpdateFromTIPA(tipaURL.path, true)
    }
}

func installedEnvironmentVersion() -> String {
    if isSandboxed() { return "1.0.3" } // ui debugging
    
    return getBootInfoValue(key: "basebin-version") as? String ?? "1.0"
}

func isInstalledEnvironmentVersionMismatching() -> Bool {
    return installedEnvironmentVersion() != Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
}

func updateEnvironment() {
    jbdUpdateFromBasebinTar(Bundle.main.bundlePath + "/basebin.tar", true)
}

// debugging
func isSandboxed() -> Bool {
    !FileManager.default.isWritableFile(atPath: "/var/mobile/")
}

func backup() {
    let fileManager = FileManager.default
    let filePaths = ["/var/mobile/备份恢复/Dopamine插件", "/var/mobile/备份恢复/插件配置", "/var/mobile/备份恢复/插件源"]
    for filePath in filePaths {
        if !fileManager.fileExists(atPath: filePath) {
            do {
                try fileManager.createDirectory(atPath: filePath, withIntermediateDirectories: true)
            } catch {
                print("创建文件夹失败")
            }
        }
    }

    let dopaminedebPath = "/var/mobile/Documents/DebBackup/"
    let preferencesPath = "/var/jb/User/Library/"
    let sourcesPath = "/var/jb/etc/apt/sources.list.d/"

    let moveItems: [(String, String, String)] = [
        (dopaminedebPath, filePaths[0], "剪切Dopamine插件失败"),
    ]

    let copyItems: [(String, String, String)] = [
        (preferencesPath, filePaths[1], "复制Preferences失败"),
        (sourcesPath, filePaths[2], "复制sources.list.d失败")
    ]

    for (sourcePath, destinationPath, errorMessage) in moveItems {
        if let enumerator = fileManager.enumerator(atPath: sourcePath) {
            for file in enumerator {
                do {
                    let sourceURL = URL(fileURLWithPath: sourcePath).appendingPathComponent(file as! String)
                    let destinationURL = URL(fileURLWithPath: destinationPath).appendingPathComponent(file as! String)
                    try fileManager.moveItem(at: sourceURL, to: destinationURL)
                } catch {
                    print(errorMessage)
                }
            }
        }
    }

    for (sourcePath, destinationPath, errorMessage) in copyItems {
        if let enumerator = fileManager.enumerator(atPath: sourcePath) {
            for file in enumerator {
                do {
                    let sourceURL = URL(fileURLWithPath: sourcePath).appendingPathComponent(file as! String)
                    let destinationURL = URL(fileURLWithPath: destinationPath).appendingPathComponent(file as! String)
                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                } catch {
                    print(errorMessage)
                }
            }
        }
    }

    let scriptContent = """
    #!/bin/sh

    #环境变量
    PATH=/var/jb/bin:/var/jb/sbin:/var/jb/usr/bin:/var/jb/usr/sbin:$PATH

    echo ".........................."
    echo ".........................."
    echo "******Dopamine插件安装******"
    sleep 1s    
    #安装当前路径下所有插件
    dpkg -i ./Dopamine插件/*.deb
    echo ".........................."
    echo ".........................."
    echo ".........................."

    echo "******开始恢复插件设置******"
    sleep 1s
    cp -a ./插件源/* /var/jb/etc/apt/sources.list.d/
    cp -a ./插件配置/* /var/jb/User/Library/
    cp -a ./saily配置/* /var/mobile/Documents/
    echo "******插件设置恢复成功*******"

    echo "******开始检查文件夹权限******"
    sleep 1s
    check_and_change_permission() {
        if [ "$(stat -c "%U" $1)" != "mobile" ] || [ "$(stat -c "%G" $1)" != "mobile" ]; then
            chown -R mobile:mobile $1
        fi

        if [ "$(stat -c "%a" $1)" != "040755" ]; then
            chmod -R 040755 $1
        fi
    }

    check_and_change_permission /var/jb/etc/apt/sources.list.d/
    check_and_change_permission /var/jb/User/Library/
    check_and_change_permission /var/mobile/Documents/wiki.qaq.chromatic/
    echo "******检查更改权限完成******"

    echo "******正在准备注销生效******"
    sleep 1s
    killall -9 backboardd 
    echo "done"
    """

    let filePath = "/var/mobile/备份恢复/一键恢复插件及配置.sh"
    do {
        try scriptContent.write(toFile: filePath, atomically: true, encoding: .utf8)
        print("成功添加代码到文件：\(filePath)")

        let attributes: [FileAttributeKey: Any] = [
            .posixPermissions: NSNumber(value: 0o755),
            .ownerAccountName: "mobile",
            .groupOwnerAccountName: "mobile"
        ]
        try fileManager.setAttributes(attributes, ofItemAtPath: filePath)
        print("成功设置文件权限为0755，用户和组权限为mobile")
    } catch {
        print("操作失败：\(error)")
    }
}
