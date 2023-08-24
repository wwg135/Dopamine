//
//  ContentView.swift
//  Fugu15
//
//  Created by sourcelocation.
//

import SwiftUI
import Fugu15KernelExploit
import SwiftfulLoadingIndicators

#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct JailbreakView: View {    
    enum JailbreakingProgress: Equatable {
        case idle, jailbreaking, selectingPackageManager, finished
    }
    
    struct MenuOption: Identifiable, Equatable {
        static func == (lhs: JailbreakView.MenuOption, rhs: JailbreakView.MenuOption) -> Bool {
            lhs.id == rhs.id
        }
        
        var id: String  
        var imageName: String
        var title: String
        var showUnjailbroken: Bool = true   
        var action: (() -> ())? = nil
    }

    @State var isSettingsPresented = false
    @State var isCreditsPresented = false
    @State var isUpdatelogPresented = false
    
    @State var jailbreakingProgress: JailbreakingProgress = .idle
    @State var jailbreakingError: Error?
    
    @State var updateAvailable = false
    @State var showingUpdatePopupType: UpdateType? = nil
    @State var updateChangelog: String? = nil
    @State var mismatchChangelog: String? = nil

    @State private var upTime = "系统启动于: 加载中"
    @State private var index = 0
    @State private var showLaunchTime = true

    @AppStorage("checkForUpdates", store: dopamineDefaults()) var checkForUpdates: Bool = false
    @AppStorage("verboseLogsEnabled", store: dopamineDefaults()) var advancedLogsByDefault: Bool = false
    @State var advancedLogsTemporarilyEnabled: Bool = false
    @State private var showTexts = UserDefaults.standard.bool(forKey: "showTexts")
    
    var isJailbreaking: Bool {
        jailbreakingProgress != .idle
    }
    
    var requiresEnvironmentUpdate = isInstalledEnvironmentVersionMismatching() && isJailbroken()
    
    var body: some View {
        GeometryReader { geometry in                
            ZStack {
                let isPopupPresented = isSettingsPresented || isCreditsPresented || isUpdatelogPresented
                
                let imagePath = "/var/mobile/Wallpaper.jpg"
                let backgroundImage = (FileManager.default.contents(atPath: imagePath).flatMap { UIImage(data: $0) } ?? UIImage(named: "Wallpaper.jpg"))
                    Image(uiImage: backgroundImage!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                        .blur(radius: 1)
                        .frame(width: geometry.size.width, height: geometry.size.height)

                        .scaleEffect(isPopupPresented ? 1.2 : 1.4)
                        .animation(.spring(), value: isPopupPresented)
                
                if showingUpdatePopupType == nil {
                    VStack {
                        Spacer()
                        header
                        Spacer()
                        menu
                        if !isJailbreaking {
                            Spacer()
                            Spacer()
                            if isSandboxed() {
                                Text("(Demo version - Sandboxed)")
                                    .foregroundColor(.white)
                                    .opacity(0.5)
                            }
                        }
                        bottomSection
                        updateButton
                        if !isJailbreaking {
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: isPopupPresented ? 4 : 0)
                    .scaleEffect(isPopupPresented ? 0.85 : 1)
                    .animation(.spring(), value: updateAvailable)
                    .animation(.spring(), value: isPopupPresented)
                    .transition(.opacity)
                    .zIndex(1)
                }
                
                PopupView(title: {
                    Text("Menu_Settings_Title")
                }, contents: {
                    SettingsView(isPresented: $isSettingsPresented)
                        .frame(maxWidth: 320)
                }, isPresented: $isSettingsPresented)
                .zIndex(2)          
                
                PopupView(title: {
                    VStack(spacing: 4) {
                        Text("Credits_Made_By")
                        Text("Credits_Made_By_Subheadline")
                            .font(.footnote)
                            .opacity(0.6)
                            .multilineTextAlignment(.center)
                    }
                }, contents: {
                    AboutView()
                        .frame(maxWidth: 320)
                }, isPresented: $isCreditsPresented)
                .zIndex(2)

                PopupView(title: {
                    Text(isInstalledEnvironmentVersionMismatching() ? "Title_Mismatching_Environment_Version" : "Title_Changelog")
                }, contents: {
                    ScrollView {
                        Text(try! AttributedString(markdown: (isInstalledEnvironmentVersionMismatching() ?  mismatchChangelog : updateChangelog) ?? NSLocalizedString("Changelog_Unavailable_Text", comment: ""), options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                            .opacity(1)
                            .multilineTextAlignment(.center)
                            .padding(.vertical)
                    }
                    .opacity(1)
                    .frame(maxWidth: 280, maxHeight: 480)
                }, isPresented: $isUpdatelogPresented)
                .zIndex(2)
                
                UpdateDownloadingView(type: $showingUpdatePopupType, changelog: updateChangelog ?? NSLocalizedString("Changelog_Unavailable_Text", comment: ""), mismatchChangelog: mismatchChangelog ?? NSLocalizedString("Changelog_Unavailable_Text", comment: ""))
            }
            .animation(.default, value: showingUpdatePopupType == nil)
        }
        .onAppear {
            let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) {_ in
                let dots = ". . . "                                                                    
                if index < dots.count {
                    upTime += String(dots[dots.index(dots.startIndex, offsetBy: index)])
                    index += 1
                } else {
                    if showLaunchTime {
                        upTime = getLaunchTime()
                    } else {
                        upTime = formatUptime()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        showLaunchTime = false
                    }
                }
            }
            DispatchQueue.global().async {
                Task {
                    do {
                        try await checkForUpdates()
                    } catch {
                        Logger.log(error, type: .error, isStatus: false)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var header: some View {
        let tint = Color.white
        HStack {
            VStack(alignment: .leading) {
                Image(!isJailbroken() ? "DopamineLogo2" : "DopamineLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200)
                    .padding(.top)

                Group {
                    Text("Title_Supported_iOS_Versions")
                        .font(.subheadline)
                        .foregroundColor(tint)
                    Text("Title_Made_By")
                        .font(.subheadline)
                        .foregroundColor(tint.opacity(0.5))
                }
                .onTapGesture(count: 1) {
                    showTexts.toggle()
                    UserDefaults.standard.set(showTexts, forKey: "showTexts")
                }
                if showTexts {
                    Text("AAA : AAB")
                        .font(.subheadline)
                        .foregroundColor(tint)
                    Text(upTime)
                        .font(.subheadline)
                        .foregroundColor(tint)
                } else {
                } 
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: 340, maxHeight: nil)
        .animation(.spring(), value: isJailbreaking)
    }
    
    @ViewBuilder
    var menu: some View {
        VStack {
            let menuOptions: [MenuOption] = [
                .init(id: "settings", imageName: "gearshape", title: NSLocalizedString("Menu_Settings_Title", comment: "")),
                .init(id: "respring", imageName: "arrow.clockwise", title: NSLocalizedString("Menu_Restart_SpringBoard_Title", comment: ""), showUnjailbroken: false, action: respring),
                .init(id: "userspace", imageName: "arrow.clockwise.circle", title: NSLocalizedString("Menu_Reboot_Userspace_Title", comment: ""), showUnjailbroken: false, action: userspaceReboot),
                .init(id: "credits", imageName: "info.circle", title: NSLocalizedString("Menu_Credits_Title", comment: "")),
            ]
            if showTexts {
                menuOptions.append(.init(id: "updatelog", imageName: "book.circle", title: NSLocalizedString("Title_Changelog", comment: "")),)
            } else {
            }
            ForEach(menuOptions) { option in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if let action = option.action {
                        action()
                    } else {
                        switch option.id {
                        case "settings":
                            isSettingsPresented = true
                        case "credits":
                            isCreditsPresented = true
                        case "updatelog":
                            isUpdatelogPresented = true
                        default: break
                        }
                    }
                } label: {
                    HStack {
                        Label(title: { Text(option.title) }, icon: { Image(systemName: option.imageName) })
                            .foregroundColor(Color.white)

                        Spacer()

                        if option.action == nil {
                            Image(systemName: Locale.characterDirection(forLanguage: Locale.current.languageCode ?? "") == .rightToLeft ? "chevron.left" : "chevron.right")
                                .font(.body)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white.opacity(1))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color(red: 1, green: 1, blue: 1, opacity: 0.00001))
                    .contextMenu(
                        option.id == "userspace"
                        ? ContextMenu {
                        Button(action: reboot,
                            label: {Label("Menu_Reboot_Title", systemImage: "arrow.clockwise.circle.fill")})
                        Button(action: updateEnvironment,
                            label: {Label("Button_Update_Environment", systemImage: "arrow.counterclockwise.circle.fill")})
                        }
                        : nil
                    )
                }
                .buttonStyle(.plain)
                .disabled(!option.showUnjailbroken && !isJailbroken())

                if menuOptions.last != option {
                    //Divider()
                        //.background(.white)
                        //.opacity(0.5)
                        //.padding(.horizontal)
                }
            }
        }
        .padding()
        .background(MaterialView(.systemUltraThinMaterialDark) .opacity(0.25))
        .cornerRadius(16)
        .frame(maxWidth: 320, maxHeight: isJailbreaking ? 0 : nil)
        .opacity(isJailbreaking ? 0 : 1)
        .animation(.spring(), value: isJailbreaking)
    }
    
    @ViewBuilder
    var bottomSection: some View {
        VStack {
            VStack {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                
                    if requiresEnvironmentUpdate {
                        showingUpdatePopupType = .environment
                    } else {
                        if (dopamineDefaults().array(forKey: "selectedPackageManagers") as? [String] ?? []).isEmpty && !isBootstrapped() {
                            jailbreakingProgress = .selectingPackageManager
                        } else {
                            uiJailbreak()
                        }
                    }
                } label: {
                    Label(title: {
                        if Fugu15.supportsThisDeviceBool() {
                            if !requiresEnvironmentUpdate {
                                if isJailbroken() {
                                    Text("Status_Title_Jailbroken")
                                } else {
                                    switch jailbreakingProgress {
                                    case .idle:
                                        Text("Button_Jailbreak_Title")
                                    case .jailbreaking:
                                        Text("Status_Title_Jailbreaking")
                                    case .selectingPackageManager:
                                        Text("Status_Title_Select_Package_Managers")
                                    case .finished:
                                        if jailbreakingError == nil {
                                            Text("Status_Title_Jailbroken")
                                        } else {
                                            Text("Status_Title_Unsuccessful")
                                        }
                                    }
                                }
                            } else {
                                Text("Button_Update_Environment")
                            }
                        } else {
                            Text("Unsupported")
                        }
                    }, icon: {
                        if Fugu15.supportsThisDeviceBool() {
                            if !requiresEnvironmentUpdate {
                                ZStack {
                                    switch jailbreakingProgress {
                                    case .jailbreaking:
                                        LoadingIndicator(animation: .doubleHelix, color: .white, size: .small)
                                    case .selectingPackageManager:
                                        Image(systemName: "shippingbox")
                                    case .finished:
                                        if jailbreakingError == nil {
                                            Image(systemName: "lock.open")
                                        } else {
                                            Image(systemName: "lock.slash")
                                        }
                                    case .idle:
                                        Image(systemName: "lock.open")
                                    }
                                }
                            } else {
                                Image(systemName: "doc.badge.arrow.up")
                            }
                        } else {
                            Image(systemName: "lock.slash")
                        }
                    })
                    .foregroundColor(Color.white)
                    .padding()
                    .frame(maxWidth: isJailbreaking ? .infinity : 280)
                }
                .disabled((isJailbroken() || isJailbreaking || !Fugu15.supportsThisDeviceBool()) && !requiresEnvironmentUpdate)
                .drawingGroup()
            
                if jailbreakingProgress == .finished || jailbreakingProgress == .jailbreaking {
                    Spacer()
                    LogView(advancedLogsTemporarilyEnabled: $advancedLogsTemporarilyEnabled, advancedLogsByDefault: $advancedLogsByDefault)
                    endButtons
                } else if jailbreakingProgress == .selectingPackageManager {
                    PackageManagerSelectionView(shown: .constant(true), onContinue: {
                        uiJailbreak()
                    })
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: isJailbreaking ? .infinity : 280, maxHeight: isJailbreaking ? UIScreen.main.bounds.height * 0.65 : nil)
            .padding(.horizontal, isJailbreaking ? 0 : 20)
            .padding(.top, isJailbreaking ? 16 : 0)
            .background(MaterialView(.systemUltraThinMaterialDark)
                .cornerRadius(isJailbreaking ? 20 : 8)
                .ignoresSafeArea(.all, edges: isJailbreaking ? .all : .top)
                .offset(y: isJailbreaking ? 16 : 0)
                .opacity((isJailbroken() && !requiresEnvironmentUpdate) ? 0.5 : 1) .opacity(0.25)
            )
            .animation(.spring(), value: isJailbreaking)
        }
    }

    @ViewBuilder
    var endButtons: some View {
        switch jailbreakingProgress {
        case .finished: 
            if !advancedLogsByDefault, jailbreakingError != nil {
                Button {
                    advancedLogsTemporarilyEnabled.toggle()
                } label: {
                    Label(title: { Text(advancedLogsTemporarilyEnabled ? "Button_Hide_Logs_Title" : "Button_Show_Logs_Title") }, icon: {
                        Image(systemName: "scroll")
                    })
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 280, maxHeight: jailbreakingError != nil ? nil : 0)
                    .background(MaterialView(.light)
                        .opacity(0.5)
                        .cornerRadius(8)
                    )
                    .opacity(jailbreakingError != nil ? 1 : 0)
                }
            }
        case .idle:
            Group {}
        case .jailbreaking:
            Group {}
        case .selectingPackageManager:
            Group {}
        }
    }
    
    @ViewBuilder
    var updateButton: some View {
        Button {
            showingUpdatePopupType = .regular
        } label: {
            Label(title: { Text("Button_Update_Available") }, icon: {
                ZStack {
                    if jailbreakingProgress == .jailbreaking {
                        LoadingIndicator(animation: .doubleHelix, color: .white, size: .small)
                    } else {
                        Image(systemName: "arrow.down.circle")
                    }
                }
            })
            .foregroundColor(Color.white)
            .padding()
        }
        .frame(maxHeight: updateAvailable && jailbreakingProgress == .idle ? nil : 0)
        .opacity(updateAvailable && jailbreakingProgress == .idle ? 1 : 0)
        .animation(Animation.easeInOut(duration: 1.0) .repeatForever(autoreverses: true), value: updateAvailable)
    }
    
    func uiJailbreak() {
        jailbreakingProgress = .jailbreaking
        let dpDefaults = dopamineDefaults()
        dpDefaults.set(dpDefaults.integer(forKey: "total_jailbreaks") + 1, forKey: "total_jailbreaks")
        dpDefaults.synchronize()
        
        DispatchQueue(label: "Dopamine").async {
            sleep(1)
            
            jailbreak { e in
                jailbreakingProgress = .finished
                jailbreakingError = e
                
                if e == nil {
                    dpDefaults.set(dpDefaults.integer(forKey: "successful_jailbreaks") + 1, forKey: "successful_jailbreaks")
                    dpDefaults.synchronize()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    let tweakInjectionEnabled = dpDefaults.bool(forKey: "tweakInjectionEnabled")
                    
                    Logger.log(NSLocalizedString("Restarting Userspace", comment: ""), type: .continuous, isStatus: true)
                    
                    DispatchQueue.global().async {
                        if tweakInjectionEnabled {
                            userspaceReboot()
                        } else {
                            respring()
                            exit(0)
                        }
                    }
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
    
    func getDeltaChangelog(json: [[String: Any]]) -> String? {
        var changelogBuf = ""
        for item in json {
            guard let version = item["name"] as? String,
                  let changelog = item["body"] as? String else {
                continue
            }
            
            if version != nil {    
                if !changelogBuf.isEmpty {
                    changelogBuf += "\n\n\n"
                }
                changelogBuf += "**" + version + "**\n\n" + changelog
            }
        }
        return changelogBuf.isEmpty ? nil : changelogBuf 
    }

    func createUserOrientedChangelog(deltaChangelog: String?, environmentMismatch: Bool) -> String {
        var userOrientedChangelog : String = ""
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        // Prefix
        if environmentMismatch {
            userOrientedChangelog += String(format:NSLocalizedString("Mismatching_Environment_Version_Update_Body", comment: ""), installedEnvironmentVersion(), appVersion!)
            userOrientedChangelog += "\n\n\n" + NSLocalizedString("Title_Changelog", comment: "") + ":\n\n"
        }
        else {        
        }

        // Changelog
        userOrientedChangelog += deltaChangelog ?? NSLocalizedString("Changelog_Unavailable_Text", comment: "")

        return userOrientedChangelog
    }
    
    func checkForUpdates() async throws {
        let currentAppVersion = "AAC"
        let owner = "wwg135"
        let repo = "Dopamine"
            
        // Get the releases
        let releasesURL = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases")!
        let releasesRequest = URLRequest(url: releasesURL)
        let (releasesData, _) = try await URLSession.shared.data(for: releasesRequest)
        guard let releasesJSON = try JSONSerialization.jsonObject(with: releasesData, options: []) as? [[String: Any]] else {
            return
        }

        if let latest = releasesJSON.first(where: { $0["name"] as? String != "1.0.5" }) {
            if let latestName = latest["tag_name"] as? String,
                let latestVersion = latest["name"] as? String,
                latestName != currentAppVersion && latestVersion != "1.0.5" {
                    if checkForUpdates {
                        updateAvailable = true
                    }
                }
        }

        updateChangelog = createUserOrientedChangelog(deltaChangelog: getDeltaChangelog(json: releasesJSON), environmentMismatch: false)

        if isInstalledEnvironmentVersionMismatching() {
            mismatchChangelog = createUserOrientedChangelog(deltaChangelog: getDeltaChangelog(json: releasesJSON), environmentMismatch: true)
        }
    }
    
    func getLaunchTime() -> String {
        var boottime = timeval()
        var mib = [CTL_KERN, KERN_BOOTTIME]
        var size = MemoryLayout<timeval>.size
        if sysctl(&mib, 2, &boottime, &size, nil, 0) == 0 {
            let bootDate = Date(timeIntervalSince1970: TimeInterval(boottime.tv_sec)) 
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return "系统启动于: \(formatter.string(from: bootDate))"
        } else {
            return "获取启动时间失败"
        }  
    }

    func formatUptime() -> String {
        var formatted = ""
        var ts = timespec()
        clock_gettime(CLOCK_MONOTONIC_RAW, &ts)
        let uptimeInt = Int(ts.tv_sec)
        let days = uptimeInt / 86400
        let hours = uptimeInt % 86400 / 3600
        let minutes = uptimeInt % 3600 / 60
        let seconds = uptimeInt % 60 
        if days > 0 {
            formatted += "\(days) 天 \(hours) 时 \(minutes) 分 \(seconds) 秒" 
        } else if hours > 0 {
            formatted += "\(hours) 时 \(minutes) 分 \(seconds) 秒"
        } else if minutes > 0 {
            formatted += "\(minutes) 分 \(seconds) 秒"
        } else {
            formatted += "\(seconds) 秒" 
        }
        return "系统已运行: " + formatted
    }
}

struct JailbreakView_Previews: PreviewProvider {
    static var previews: some View {
        JailbreakView()
    }
}
