//
//  SettingsView.swift
//  Fugu15
//
//  Created by exerhythm on 02.04.2023.
//

import SwiftUI
import Fugu15KernelExploit

struct SettingsView: View {    
    @AppStorage("total_jailbreaks", store: dopamineDefaults()) var totalJailbreaks: Int = 0
    @AppStorage("successful_jailbreaks", store: dopamineDefaults()) var successfulJailbreaks: Int = 0  
    @AppStorage("verboseLogsEnabled", store: dopamineDefaults()) var verboseLogs: Bool = false
    @AppStorage("checkForUpdates", store: dopamineDefaults()) var checkForUpdates: Bool = false
    @AppStorage("tweakInjectionEnabled", store: dopamineDefaults()) var tweakInjection: Bool = true
    @AppStorage("iDownloadEnabled", store: dopamineDefaults()) var enableiDownload: Bool = false
    @State var hiddenFunction = dopamineDefaults().bool(forKey: "hiddenFunction")
    @Binding var isPresented: Bool   
    @State var mobilePasswordChangeAlertShown = false
    @State var mobilePasswordInput = "alpine"
    @State var rebootRequiredAlertShown = false
    @State var removeJailbreakAlertShown = false
    @State var isSelectingPackageManagers = false
    @State var tweakInjectionToggledAlertShown = false
    @State var backupAlertShown = false
    @State var completedAlert = false 
    @State var appupdateAlertShown = false
    @State var appInput = ""
    
    init(isPresented: Binding<Bool>?) {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .init(named: "AccentColor")
        self._isPresented = isPresented ?? .constant(true)
    }
    
    var body: some View {
        VStack {
            if !isSelectingPackageManagers {
                VStack {
                    VStack(spacing: 20) {
                        VStack(spacing: 10) {
                            (hiddenFunction ? Toggle("Check_For_Updates", isOn: $checkForUpdates) : nil)
                            Toggle("Settings_Tweak_Injection", isOn: $tweakInjection)
                                .onChange(of: tweakInjection) { newValue in
                                    if isJailbroken() {
                                        jailbrokenUpdateTweakInjectionPreference()
                                        tweakInjectionToggledAlertShown = true
                                    }
                                }
                            if !isJailbroken() {
                                Toggle("Settings_iDownload", isOn: $enableiDownload)
                                    .onChange(of: enableiDownload) { newValue in
                                        if isJailbroken() {
                                            jailbrokenUpdateIDownloadEnabled()
                                        }
                                    }
                                Toggle("Settings_Verbose_Logs", isOn: $verboseLogs)
                            }
                        }
                        if isBootstrapped() {
                            VStack {
                                if isJailbroken() {
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        mobilePasswordChangeAlertShown = true
                                    }) {
                                        HStack {
                                            Image(systemName: "key")
                                            Text("Button_Set_Mobile_Password")
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                        }
                                        .padding(8)
                                        .frame(maxWidth: .infinity)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                                        )
                                    }
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        isSelectingPackageManagers = true
                                    }) {
                                        HStack {
                                            Image(systemName: "shippingbox")
                                            Text("Button_Reinstall_Package_Managers")
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                        }
                                        .padding(.horizontal, 4)
                                        .padding(8)
                                        .frame(maxWidth: .infinity)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                                        )
                                    }
                                }
                                VStack {
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        isJailbroken() ? (rebootRequiredAlertShown = true) : (removeJailbreakAlertShown = true)
                                    }) {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Button_Remove_Jailbreak")
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                        }
                                        .padding(.horizontal, 4)
                                        .padding(8)
                                        .frame(maxWidth: .infinity)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                                        )
                                    }
                                }
                                if isJailbroken() {
                                    if hiddenFunction {
                                        Button(action: {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            backupAlertShown = true
                                        }) {
                                            HStack {
                                                Image(systemName: "doc")
                                                Text("Button_Backup")
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.5)
                                            }
                                            .padding(.horizontal, 4)
                                            .padding(8)
                                            .frame(maxWidth: .infinity)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                                            )
                                        }
                                        Button(action: {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            appupdateAlertShown = true
                                        }) {
                                            HStack {
                                                Image(systemName: "doc.update")
                                                Text("Button_App_Update")
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.5)
                                            }
                                            .padding(.horizontal, 4)
                                            .padding(8)
                                            .frame(maxWidth: .infinity)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                                            )
                                        }
                                    } else {
                                    }
                                }
                            }
                        }
                    }
                    .tint(.accentColor)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 32)
                    
                    VStack(spacing: 6) {
                        Group {
                            Text(isBootstrapped() ? "Settings_Footer_Device_Bootstrapped" :  "Settings_Footer_Device_Not_Bootstrapped")
                            Text("Success_Rate \(successRate())% (\(successfulJailbreaks)/\(totalJailbreaks))")
                        }
                        .font(.footnote)
                        .opacity(1)
                        .onTapGesture(count: 1) {
                            hiddenFunction.toggle()
                            dopamineDefaults().set(hiddenFunction, forKey: "hiddenFunction")
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                    .padding(.top, 2)
                    
                    ZStack {}
                        .textFieldAlert(isPresented: $appupdateAlertShown) { () -> TextFieldAlert in
                            TextFieldAlert(title: NSLocalizedString("Button_App_Update", comment: ""), message: NSLocalizedString("Enable_Or_Disable_Update_Message", comment: ""), text: Binding<String?>($appInput), onSubmit: {
                                Button("Button_Cancel", role: .cancel) { }
                                Button("Button_Set") {
                                    specifyAppUpdates(app: appInput)
                                }
                            })
                        }
                        .textFieldAlert(isPresented: $mobilePasswordChangeAlertShown) { () -> TextFieldAlert in
                            TextFieldAlert(title: NSLocalizedString("Popup_Change_Mobile_Password_Title", comment: ""), message: NSLocalizedString("Popup_Change_Mobile_Password_Message", comment: ""), text: Binding<String?>($mobilePasswordInput), onSubmit: {
                                changeMobilePassword(newPassword: mobilePasswordInput)
                            })
                        }
                        .alert("Settings_Remove_Jailbreak_Alert_Title", isPresented: $rebootRequiredAlertShown, actions: {
                            Button("Button_Cancel", role: .cancel) { }
                            Button("Menu_Reboot_Title") {
                                reboot()
                            }
                        }, message: { Text("Jailbroken currently, please reboot the device.") })
                        .alert("Settings_Remove_Jailbreak_Alert_Title", isPresented: $removeJailbreakAlertShown, actions: {
                            Button("Button_Cancel", role: .cancel) { }
                            Button("Alert_Button_Uninstall", role: .destructive) {
                                removeJailbreak()
                            }
                        }, message: { Text("Settings_Remove_Jailbreak_Alert_Body") })
                        .alert("Settings_Tweak_Injection_Toggled_Alert_Title", isPresented: $tweakInjectionToggledAlertShown, actions: {
                            Button("Button_Cancel", role: .cancel) { }
                            Button("Menu_Reboot_Userspace_Title") {
                                userspaceReboot()
                            }
                        }, message: { Text("Alert_Tweak_Injection_Toggled_Body") })
                        .alert("Settings_Backup_Alert_Title", isPresented: $backupAlertShown, actions: {
                            Button("Button_Cancel", role: .cancel) { }
                            Button("Button_Set") {
                                let fileManager = FileManager.default
                                let filePath = "/var/mobile/Documents/DebBackup/"
                                do {
                                    let contents = try fileManager.contentsOfDirectory(atPath: filePath)
                                    if contents.isEmpty {
                                        backupAlertShown = false
                                        showAlert(title: "备份失败", message: "请先使用“DEB备份”app备份插件！！！")
                                    } else {
                                        backup()
                                        completedAlert = true
                                    }
                                } catch {
                                }
                            }
                        }, message: { Text("Settings_One-click_Backup") })
                        .alert("备份成功", isPresented: $completedAlert, actions: {
                            Button("好的") {
                                backupAlertShown = false
                            }
                        }, message: { Text(" ") })
                        .frame(maxHeight: 0)        
                }
                .foregroundColor(.white)              
            } else {
                PackageManagerSelectionView(shown: $isSelectingPackageManagers, reinstall: true) {
                    isSelectingPackageManagers = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                .frame(maxHeight: 250)
                .padding(.horizontal)
                .foregroundColor(.white)
                .onChange(of: isPresented) { newValue in
                    if !newValue {
                        isSelectingPackageManagers = false
                    }
                }
            }
        }
    }
    
    func successRate() -> String {
        if totalJailbreaks == 0 {
            return "-"
        } else {
            return String(format: "%.1f", Double(successfulJailbreaks) / Double(totalJailbreaks) * 100)
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        JailbreakView()
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {            
            ZStack(alignment: alignment) {
                placeholder().opacity(shouldShow ? 1 : 0)
                self
            }
        }
}
