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
    @AppStorage("tweakInjectionEnabled", store: dopamineDefaults()) var tweakInjection: Bool = true
    @AppStorage("iDownloadEnabled", store: dopamineDefaults()) var enableiDownload: Bool = false

    @Binding var isPresented: Bool

    @AppStorage("rebuildEnvironment", store: dopamineDefaults()) var rebuildEnvironment: Bool = false
    @AppStorage("pathMappingEnabled", store: dopamineDefaults()) var pathMappingEnabled: Bool = true
    @AppStorage("blockDopamineUpdates", store: dopamineDefaults()) var blockDopamineUpdates: Bool = false
    @AppStorage("presetUptimeInDay", store: dopamineDefaults()) var presetUptimeInDay: Int = 0

    @State var pathMappingAlertShown = false
    @State var pathMappingInput = ""
    @State var pathMappingRemoveAlertShown = false
    @State var pathMappingRemoveInput = ""

    @State var mobilePasswordChangeAlertShown = false
    @State var mobilePasswordInput = "alpine"

    @State var rebootRequiredAlertShown = false
    @State var removeJailbreakAlertShown = false
    @State var isSelectingPackageManagers = false
    @State var tweakInjectionToggledAlertShown = false

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
                            if !isJailbroken() {
                                Toggle("Options_Rebuild_Environment", isOn: $rebuildEnvironment)
                                Toggle("Options_Enable_Path_Mapping", isOn: $pathMappingEnabled)
                            }
                            Toggle("Options_Block_Dopamine_Updates", isOn: $blockDopamineUpdates)
                            Toggle("Settings_Tweak_Injection", isOn: $tweakInjection)
                                .onChange(of: tweakInjection) { newValue in
                                    if isJailbroken() {
                                        jailbrokenUpdateTweakInjectionPreference()
                                        tweakInjectionToggledAlertShown = true
                                    }
                                }
                            Toggle("Settings_iDownload", isOn: $enableiDownload)
                                .onChange(of: enableiDownload) { newValue in
                                    if isJailbroken() {
                                        jailbrokenUpdateIDownloadEnabled()
                                    }
                                }
                            if !isJailbroken() {
                                Toggle("Settings_Verbose_Logs", isOn: $verboseLogs)
                            }
                        }
                        if isBootstrapped() {
                            VStack {
                                if isJailbroken() {
                                    if (isPathMappingEnabled()) {
                                        Button(action: {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            pathMappingAlertShown = true
                                        }) {
                                            HStack {
                                                Image(systemName: "mappin.circle")
                                                Text("Button_Add_Path_Mapping_Source")
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
                                            pathMappingRemoveAlertShown = true
                                        }) {
                                            HStack {
                                                Image(systemName: "mappin.slash.circle")
                                                Text("Button_Remove_Path_Mapping_Source")
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
                                        .padding(.bottom)
                                    }
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
                                    .padding(.bottom)


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
                            .opacity(0.6)
                        Text("Success_Rate \(successRate())% (\(successfulJailbreaks)/\(totalJailbreaks))")
                            .font(.footnote)
                            .opacity(0.6)
                    }
                    .padding(.top, 2)

                    if easterEgg {
                        Image("fr")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: .infinity)
                    }

                    ZStack {}
                        .textFieldAlert(isPresented: $pathMappingAlertShown) { () -> TextFieldAlert in
                            TextFieldAlert(title: NSLocalizedString("Popup_Path_Mapping_Source_Title", comment: ""),
                                         message: NSLocalizedString("Message_Path_Mapping_Source", comment: ""),
                                            text: Binding<String?>($pathMappingInput),
                                        onSubmit: {
                                bindMount(path: pathMappingInput)
                            })
                        }
                        .textFieldAlert(isPresented: $pathMappingRemoveAlertShown) { () -> TextFieldAlert in
                            TextFieldAlert(title: NSLocalizedString("Popup_Remove_Path_Mapping_Source_Title",
                                                                    comment: ""),
                                         message: NSLocalizedString("Message_Remove_Path_Mapping_Source",
                                                                    comment: ""),
                                            text: Binding<String?>($pathMappingRemoveInput),
                                        onSubmit: {
                                    bindUnmount(path: pathMappingRemoveInput)
                            })
                        }
                        .textFieldAlert(isPresented: $mobilePasswordChangeAlertShown) { () -> TextFieldAlert in
                            TextFieldAlert(title: NSLocalizedString("Popup_Change_Mobile_Password_Title", comment: ""), message: NSLocalizedString("Popup_Change_Mobile_Password_Message", comment: ""), text: Binding<String?>($mobilePasswordInput), onSubmit: {
                                changeMobilePassword(newPassword: mobilePasswordInput)
                            })
                        }
                        .alert("Settings_Remove_Jailbreak_Alert_Title", isPresented: $rebootRequiredAlertShown, actions: {
                            Button("OK", role: .none) {
                                reboot();
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
