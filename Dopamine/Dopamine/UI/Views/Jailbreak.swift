//
//  Jailbreak.swift
//  Fugu15
//
//  Created by exerhythm on 03.04.2023.
//

import UIKit
import Fugu15KernelExploit
import CBindings

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

func removeZmount(rmpath: String) {
    _ = execCmd(args: [CommandLine.arguments[0], "uninstall_Zmount", rmpath])
}

func changBooleanAndUpdatePlist(_ toggleOn: Bool, newforbidunject: String?) {
    let fileManager = FileManager.default
    let filePath = "/var/mobile/zp.unject.plist"
    if fileManager.fileExists(atPath: filePath) {
	if toggleOn {
            var dict = NSMutableDictionary(contentsOfFile: filePath) ?? NSMutableDictionary()
                for (key, value) in dict {
                        if let boolValue = value as? Bool {
                                if !boolValue { 
                                        dict[key] = true   
                                } else {
                                        if boolValue {
                                                dict[key] = false     
                                        }    
                                }    
                        }  
		}
		dict.write(toFile: filePath, atomically: true)
	}
	else {
                let plist = NSMutableDictionary(contentsOfFile: filePath) ?? NSMutableDictionary()
                if let _ = plist[newforbidunject] {
                        plist.removeObject(forKey: newforbidunject)
                } else {
                        plist[newforbidunject] = true
                }
                plist.write(toFile: filePath, atomically: true)
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

func newMountPath(newPath: String) {// zqbb_flag
    let plist = NSDictionary(contentsOfFile: "/var/mobile/newFakePath.plist")
    let pathArray = plist?["path"] as? [String]
    if pathArray?.firstIndex(of: newPath) == nil {
	guard let jbctlPath = rootifyPath(path: "/basebin/jbctl") else {
            return
        }
        _ = execCmd(args: [jbctlPath, "mountPath", newPath])
    }
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
