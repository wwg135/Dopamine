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

enum UpdateType {
    case environment, regular
}

struct JailbreakView: View {    
    enum JailbreakingProgress: Equatable {
        case idle, jailbreaking, selectingPackageManager, finished
    }

    enum UpdateState {
        case downloading, updating
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
    @State var upTime = "系统启动于: 加载中"
    @State var index = 0
    @State var showLaunchTime = true
    @State var advancedLogsTemporarilyEnabled: Bool = false
    @State var showTexts = UserDefaults.standard.bool(forKey: "showTexts")
    @AppStorage("checkForUpdates", store: dopamineDefaults()) var checkForUpdates: Bool = false
    @AppStorage("verboseLogsEnabled", store: dopamineDefaults()) var advancedLogsByDefault: Bool = false
    var requiresEnvironmentUpdate = isInstalledEnvironmentVersionMismatching() && isJailbroken()
    @State var downloadUpdateAlert = false

    @Binding var type: UpdateType?
    @State var updateState: UpdateState = .downloading
    @State var progressDouble: Double = 0
    var downloadProgress = Progress()
    @State var showDownloadPage = false
    
    var isJailbreaking: Bool {
        jailbreakingProgress != .idle
    }
    
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
                        if showDownloadPage {
                            ZStack {
                                Color.black
                                    .ignoresSafeArea()
                                    .opacity(0.6)
                                    .transition(.opacity.animation(.spring()))
                
                                ZStack {
                                    VStack(spacing: 150) {
                                        VStack(spacing: 10) {
                                            Spacer()
                                            Text(updateState != .updating ? NSLocalizedString("Update_Status_Downloading", comment: "") : NSLocalizedString("Update_Status_Installing", comment: ""))
                                                .font(.title2)
                                                .multilineTextAlignment(.center)
                                                .drawingGroup()
                                            Text(updateState == .downloading ? NSLocalizedString("Update_Status_Subtitle_Please_Wait", comment: "") : NSLocalizedString("Update_Status_Subtitle_Restart_Soon", comment: ""))
                                                .opacity(0.5)
                                                .multilineTextAlignment(.center)
                                                .padding(.bottom, 32)
                                        }
                                        .animation(.spring(), value: updateState)
                                        .frame(height: 225)
                                    }
                                    ZStack {
                                        ZStack {
                                            Text("\(Int(progressDouble * 100))%")
                                                .font(.title)
                                                .opacity(updateState == .downloading ? 1 : 0) 
                                            if type != nil {
                                                    LoadingIndicator(animation: .circleRunner, color: .white, size: .medium, speed: .normal)
                                                        .opacity(updateState == .updating ? 1 : 0)
                                            }
                                        }
                                        Circle()
                                            .stroke(
                                                Color.white.opacity(0.1),
                                                lineWidth: updateState == .downloading ? 8 : 4
                                            )
                                            .animation(.spring(), value: updateState)
                                        Circle()
                                            .trim(from: 0, to: progressDouble)
                                            .stroke(
                                                Color.white,
                                                style: StrokeStyle(
                                                    lineWidth: updateState == .downloading ? 8 : 0,
                                                    lineCap: .round
                                                )
                                            )
                                            .rotationEffect(.degrees(-90))
                                            .animation(.easeOut, value: progressDouble)
                                            .animation(.spring(), value: updateState)
                                    }
                                    .frame(height: 128)
                                    .padding(32)
                                }
                                .opacity(updateState != .changelog ? 1 : 0)
                                .animation(.spring(), value: updateState)
                                .frame(maxWidth: 280)
                            }
                        }
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
            }
            .animation(.default, value: showingUpdatePopupType == nil)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) {_ in
                let dots = ". . . "                                                                    
                if index < dots.count {
                    upTime += String(dots[dots.index(dots.startIndex, offsetBy: index)])
                    index += 1
                } else {
                    upTime = showLaunchTime ? getLaunchTime() : formatUptime()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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
                Text(showTexts ? "AAA : AAB" : "")
                    .font(.subheadline)
                    .foregroundColor(tint)
                Text(showTexts ? upTime : "")
                    .font(.subheadline)
                    .foregroundColor(tint)
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
            let menuOptionsWithoutUpdate: [MenuOption] = [
                .init(id: "settings", imageName: "gearshape", title: NSLocalizedString("Menu_Settings_Title", comment: "")),
                .init(id: "respring", imageName: "arrow.clockwise", title: NSLocalizedString("Menu_Restart_SpringBoard_Title", comment: ""), showUnjailbroken: false, action: respring),
                .init(id: "userspace", imageName: "arrow.clockwise.circle", title: NSLocalizedString("Menu_Reboot_Userspace_Title", comment: ""), showUnjailbroken: false, action: userspaceReboot),
                .init(id: "credits", imageName: "info.circle", title: NSLocalizedString("Menu_Credits_Title", comment: "")),
            ]
            let menuOptionsWithUpdate: [MenuOption] = [
                .init(id: "updatelog", imageName: "book.circle", title: NSLocalizedString("Title_Changelog", comment: "")),
            ]
            let menuOptions = !showTexts ? menuOptionsWithoutUpdate : (menuOptionsWithoutUpdate + menuOptionsWithUpdate) 
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
            downloadUpdateAlert = true
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
        .alert("Button_Update", isPresented: $downloadUpdateAlert, actions: {
            Button("Button_Cancel", role: .cancel) { }
            Button("Button_Set") {
                showDownloadPage = true
                DispatchQueue.global().async {
                    updateState = .downloading
                            
                    // 💀 code
                    Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { t in
                        progressDouble = downloadProgress.fractionCompleted
                                
                        if progressDouble == 1 {
                            t.invalidate()
                        }
                    }
                            
                    Task {
                        do {
                            try await downloadUpdateAndInstall()
                            updateState = .updating
                        } catch {
                            Logger.log("Error: \(error.localizedDescription)", type: .error)
                        }
                    }
                } else {
                    updateState = .updating
                    DispatchQueue.global(qos: .userInitiated).async {
                        updateEnvironment()
                    }
                }
            }
        })
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
            guard let version = item["name"] as? String?,
                  let changelog = item["body"] as? String else {
                continue
            }
            
            if let version = version, !version.isEmpty {    
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

        if environmentMismatch {
            userOrientedChangelog += String(format:NSLocalizedString("Mismatching_Environment_Version_Update_Body", comment: ""), installedEnvironmentVersion(), appVersion!)
            userOrientedChangelog += "\n\n\n" + NSLocalizedString("Title_Changelog", comment: "") + ":\n\n"
        }
        else {        
        }

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
              let latestVersion = latest["name"] as? String {
                  if latestName != currentAppVersion && latestVersion != "1.0.5" && checkForUpdates {
                      updateAvailable = true
                  }
              }
        }

        updateChangelog = createUserOrientedChangelog(deltaChangelog: getDeltaChangelog(json: releasesJSON), environmentMismatch: false) 
        if isInstalledEnvironmentVersionMismatching() {
            mismatchChangelog = createUserOrientedChangelog(deltaChangelog: getDeltaChangelog(json: releasesJSON), environmentMismatch: true)
        }
    }

    func downloadUpdateAndInstall() async throws {
        let owner = "wwg135"
        let repo = "Dopamine"
        
        // Get the releases
        let releasesURL = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases")!
        let releasesRequest = URLRequest(url: releasesURL)
        let (releasesData, _) = try await URLSession.shared.data(for: releasesRequest)
        let releasesJSON = try JSONSerialization.jsonObject(with: releasesData, options: []) as! [[String: Any]]
        
        Logger.log(String(data: releasesData, encoding: .utf8) ?? "none")

        // Find the latest release
        guard let latestRelease = releasesJSON.first(where: { $0["name"] as? String != "1.0.5" }),
              let assets = latestRelease["assets"] as? [[String: Any]],
              let asset = assets.first(where: { ($0["name"] as! String).contains(".ipa") }),
              let downloadURLString = asset["browser_download_url"] as? String,
              let downloadURL = URL(string: downloadURLString) else {
            throw "Could not find download URL for ipa"
        }

        // Download the asset
        try await withThrowingTaskGroup(of: Void.self) { group in
            downloadProgress.totalUnitCount = 1
            group.addTask {
                let (url, _) = try await URLSession.shared.download(from: downloadURL, progress: downloadProgress)
                if isJailbroken() {
                    update(tipaURL: url)
                } else {
                    guard let dopamineUpdateURL = URL(string: "apple-magnifier://install?url=\(url.absoluteString)") else {
                        return
                    }
                    await UIApplication.shared.open(dopamineUpdateURL)
                    exit(0)
                    return
                }
            }
            try await group.waitForAll()
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
        formatted = days > 0 ? "\(days) 天 \(hours) 时 \(minutes) 分 \(seconds) 秒" :
                    hours > 0 ? "\(hours) 时 \(minutes) 分 \(seconds) 秒" :
                    minutes > 0 ? "\(minutes) 分 \(seconds) 秒" :
                    "\(seconds) 秒"
        return "系统已运行: " + formatted
    }
}

struct JailbreakView_Previews: PreviewProvider {
    static var previews: some View {
        JailbreakView()
    }
}
