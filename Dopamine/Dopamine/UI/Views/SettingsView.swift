//
//  SettingsView.swift
//  Fugu15
//
//  Created by exerhythm on 02.04.2023.
//

import SwiftUI
import Fugu15KernelExploit

struct SettingsView: View {
    
    @AppStorage("totalJailbreaks", store: dopamineDefaults()) var totalJailbreaks: Int = 0
    @AppStorage("successfulJailbreaks", store: dopamineDefaults()) var successfulJailbreaks: Int = 0
    
    @AppStorage("verboseLogsEnabled", store: dopamineDefaults()) var verboseLogs: Bool = false
    @AppStorage("tweakInjectionEnabled", store: dopamineDefaults()) var tweakInjection: Bool = true
    @AppStorage("iDownloadEnabled", store: dopamineDefaults()) var enableiDownload: Bool = false
    @AppStorage("developmentMode", store: dopamineDefaults()) var developmentMode: Bool = false
    @AppStorage("enableMount", store: dopamineDefaults()) var enableMount: Bool = true
    
    @Binding var isPresented: Bool

    @AppStorage("rebuildEnvironment", store: dopamineDefaults()) var rebuildEnvironment: Bool = false

    @State var rebootRequiredAlertShown = false
    @State var mountPathAlertShown = false
    @State var mountPathInput = ""
    @State var removeZmountAlertShown = false
    @State var removeZmountInput = ""
    @State var mobilePasswordChangeAlertShown = false
    @State var mobilePasswordInput = "alpine"

    @AppStorage("checkForUpdates", store: dopamineDefaults()) var checkForUpdates: Bool = false
    @AppStorage("bridgeToXinA", store: dopamineDefaults()) var bridgeToXinA: Bool = false
    @State var removeJailbreakAlertShown = false
    @State var isSelectingPackageManagers = false
    @State var tweakInjectionToggledAlertShown = false
    @State var removeZplistAlertShown = false
    
    @State var isEnvironmentHiddenState = isEnvironmentHidden()
    
    @State var easterEgg = false
    
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
                            Toggle("Check_For_Updates", isOn: $checkForUpdates)
                            Toggle("Settings_Tweak_Injection", isOn: $tweakInjection)
                                .onChange(of: tweakInjection) { newValue in
                                    if isJailbroken() {
                                        jailbrokenUpdateTweakInjectionPreference()
                                        tweakInjectionToggledAlertShown = true
                                    }
                                }
                            if !isJailbroken() {
                                Toggle("Options_bridgeToXinA", isOn: $bridgeToXinA)
                                Toggle("Options_Enable_Mount_Path", isOn: $enableMount)
                                Toggle("Options_Rebuild_Environment", isOn: $rebuildEnvironment)
                                Toggle("Settings_iDownload", isOn: $enableiDownload)
                                Toggle("Settings_Verbose_Logs", isOn: $verboseLogs)
                            }
                        }
                        if isBootstrapped() {
                            VStack {
                                if isJailbroken() {
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        mountPathAlertShown = true
                                    }) {
                                        HStack {
                                            Image(systemName: "mappin.circle")
                                            Text("Button_Set_Mount_Path")
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
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    removeZmountAlertShown = true
                                }) {
                                    HStack {
                                        Image(systemName: "mappin.slash.circle")
                                        Text("Button_Remove_Zmount")
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
                                    removeZplistAlertShown = true
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Button_Remove_Zplist")
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
                                       isEnvironmentHiddenState.toggle()
                                       changeEnvironmentVisibility(hidden: !isEnvironmentHidden())
                                   }) {
                                       HStack {
                                           Image(systemName: isEnvironmentHiddenState ? "eye" : "eye.slash")
                                           Text(isEnvironmentHiddenState ? "Button_Unhide_Jailbreak" : "Button_Hide_Jailbreak")
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
                                        if isJailbroken() {
                                            rebootRequiredAlertShown = true
                                        } else {
                                            removeJailbreakAlertShown = true
                                        }
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
                                    Text(isJailbroken() ? "Hint_Hide_Jailbreak_Jailbroken" : "Hint_Hide_Jailbreak")
                                        .font(.footnote)
                                        .opacity(0.6)
                                        .padding(.top, 8)
                                        .frame(maxWidth: .infinity)
                                        .multilineTextAlignment(.center)
                                        .onLongPressGesture(minimumDuration: 3, perform: {
                                            easterEgg.toggle()
                                    })  
                                }
                            }
                        }
                    }
                    .tint(.accentColor)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 32)
                    
                    Divider()
                        .background(.white)
                        .padding(.horizontal, 32)
                        .opacity(0.25)
                    VStack(spacing: 6) {
                        Text(isBootstrapped() ? "Settings_Footer_Device_Bootstrapped" :  "Settings_Footer_Device_Not_Bootstrapped")
                            .font(.footnote)
                            .opacity(1)
                        if isJailbroken() {
                            Text("Success_Rate \(successRate())% (\(successfulJailbreaks)/\(totalJailbreaks))")
                                .font(.footnote)
                                .opacity(1)
                        }
                    }
                    .padding(.top, 2)
                    
                    if easterEgg {
                        Image("fr")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: .infinity)
                    }
                    
                    ZStack {}
                        .textFieldAlert(isPresented: $mountPathAlertShown) { () -> TextFieldAlert in
                            TextFieldAlert(title: NSLocalizedString("Set_Mount_Path_Alert_Shown_Title", comment: ""), message: NSLocalizedString("Set_Mount_Path_Message", comment: ""), text: Binding<String?>($mountPathInput), onSubmit: {
                                if mountPathInput.count > 1 {
                                    newMountPath(newPath: mountPathInput)
                                }
                            })
                        }
                        .textFieldAlert(isPresented: $removeZmountAlertShown) { () -> TextFieldAlert in
                            TextFieldAlert(title: NSLocalizedString("Remove_Zmount_Alert_Shown_Title", comment: ""), message: NSLocalizedString("Remove_Zmount_Message", comment: ""), text: Binding<String?>($removeZmountInput), onSubmit: {
                                if removeZmountInput.count > 1 {
                                    removeZmount(rmpath: removeZmountInput)
                                }
                            })
                        }
                        .alert("Settings_Remove_Jailbreak_Alert_Title", isPresented: $rebootRequiredAlertShown, actions: {
                            Button("Button_Cancel", role: .cancel) { }
                            Button("Menu_Reboot_Title") {
                                reboot()
                            }
                        }, message: { Text("Jailbroken currently, please reboot the device.") })
                        .alert("Settings_Remove_Zplist_Alert_Title", isPresented: $removeZplistAlertShown, actions: {
                            Button("Button_Cancel", role: .cancel) { }
                            Button("Button_Set", role: .destructive) {
                                removeZplist()
                            }
                        }, message: { Text("Settings_Remove_Zplist_Alert_Body") })
                        .textFieldAlert(isPresented: $mobilePasswordChangeAlertShown) { () -> TextFieldAlert in
                            TextFieldAlert(title: NSLocalizedString("Popup_Change_Mobile_Password_Title", comment: ""), message: NSLocalizedString("Popup_Change_Mobile_Password_Message", comment: ""), text: Binding<String?>($mobilePasswordInput), onSubmit: {
                                changeMobilePassword(newPassword: mobilePasswordInput)
                            })
                        }
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
