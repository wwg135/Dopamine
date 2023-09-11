//
//  ContentView.swift
//  Fugu15
//
//  Created by sourcelocation.
//

import SwiftUI
import Fugu15KernelExploit
import SwiftfulLoadingIndicators
import Foundation

#if os(iOS)
import UIKit
#else
import AppKit
#endif

enum UpdateState {
    case downloading, updating
}

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
    @State var jailbreakingProgress: JailbreakingProgress = .idle
    @State var jailbreakingError: Error?  
    @State var updateAvailable = false
    @State var updateChangelog: String? = nil
    @State var mismatchChangelog: String? = nil 
    @State var upTime = "系统启动于: 加载中"
    @State var index = 0
    @State var showLaunchTime = true
    @State var advancedLogsTemporarilyEnabled: Bool = false
    @State var showTexts = dopamineDefaults().bool(forKey: "showTexts")
    @AppStorage("checkForUpdates", store: dopamineDefaults()) var checkForUpdates: Bool = false
    @AppStorage("verboseLogsEnabled", store: dopamineDefaults()) var advancedLogsByDefault: Bool = false
    var requiresEnvironmentUpdate = isInstalledEnvironmentVersionMismatching() && isJailbroken()
    @State var updateState: UpdateState = .downloading
    @State var progressDouble: Double = 0
    var downloadProgress = Progress()
    @State var showDownloadPage = false
    @State var showLogView = false
    @State var versionRegex = try! NSRegularExpression(pattern: "^1\\.1\\.[56]$")
    @State var checklog = false
    @State var showupdate = false
    @State var appNames: [(String, String)] = []
    @State var selectedNames: [String] = []
    @State var MaskDetection = false
    @State var searchText = ""
    @State var isban = false
    
    var isJailbreaking: Bool {
        jailbreakingProgress != .idle
    }
    
    var body: some View {
        GeometryReader { geometry in                
            ZStack {
                let isPopupPresented = isSettingsPresented || isCreditsPresented            
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

                if updateAvailable {
                    GeometryReader { geometry in
                        Color.black.opacity(0.15)
                            .zIndex(1)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .allowsHitTesting(true)
                    }
                    .ignoresSafeArea()
                    ZStack {
                        VStack {
                            VStack{
                                Text(isInstalledEnvironmentVersionMismatching() ? "Title_Mismatching_Environment_Version" : "Title_Changelog")
                                    .font(.title2)
                                    .minimumScaleFactor(0.5)
                                    .multilineTextAlignment(.center)
                                Divider()
                                    .background(.white)
                                    .padding(.horizontal, 25)
                                ScrollView {
                                    VStack {
                                        Text(try! AttributedString(markdown: (isInstalledEnvironmentVersionMismatching() ?  mismatchChangelog : updateChangelog) ?? NSLocalizedString("Changelog_Unavailable_Text", comment: ""), options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                                            .font(.system(size: 16))
                                            .multilineTextAlignment(.center)
                                            .padding(.vertical) 
                                        HStack {
                                            Text("Button_Cancel")
                                                .font(.system(size: 18))
                                                .gesture(TapGesture().onEnded {
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                    DispatchQueue.global(qos: .userInitiated).async {
                                                        updateAvailable = false
                                                    }
                                                })
                                            Spacer()
                                            Text(checklog ? "☑ 已阅读，立即更新" : "□ 已阅读，立即更新")
                                                .font(.system(size: 18))
                                                .gesture(TapGesture().onEnded {
                                                    checklog.toggle()
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                        showDownloadPage = true
                                                        updateAvailable = false
                                                        DispatchQueue.global(qos: .userInitiated).async {
                                                            if requiresEnvironmentUpdate {
                                                                updateState = .updating
                                                                DispatchQueue.global(qos: .userInitiated).async {
                                                                    updateEnvironment()
                                                                }
                                                            } else {
                                                                updateState = .downloading
                                                                Task {
                                                                    do {
                                                                        try await downloadUpdateAndInstall()
                                                                        updateState = .updating
                                                                    } catch {
                                                                        showLogView = true
                                                                        Logger.log("Error: \(error.localizedDescription)", type: .error)
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                })
                                        }
                                        .padding(.horizontal, 15)
                                    }
                                }
                                .opacity(1)
                                .frame(maxWidth: 250, maxHeight: 300)
                            }
                        }
                        .padding(.vertical)
                        .background(Color.black.opacity(0.25))
                        .animation(.spring(), value: updateAvailable)
                        .background(MaterialView(.systemUltraThinMaterialDark))
                    }
                    .zIndex(2)
                    .cornerRadius(16)
                    .foregroundColor(.white)
                    .frame(maxWidth: 280, maxHeight: 420)
                }
                            
                if showDownloadPage {
                    GeometryReader { geometry in
                        Color.black.opacity(0.15)
                            .zIndex(1)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .allowsHitTesting(true)
                            .onTapGesture {
                                showDownloadPage = false
                            }
                    }
                    .ignoresSafeArea()
                    ZStack {
                        if showLogView {
                            VStack {
                                LogView(advancedLogsTemporarilyEnabled: .constant(true), advancedLogsByDefault: .constant(true))
                                    .opacity(1)
                                    .foregroundColor(Color.white)
                                Text("Update_Log_Hint_Scrollable")
                                    .opacity(1)
                                    .minimumScaleFactor(0.5)  
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            .frame(maxWidth: 250, maxHeight: 360)
                            .background(Color.black.opacity(0.5))
                            .background(MaterialView(.systemUltraThinMaterialDark))
                        } else {
                            VStack {
                                VStack {
                                    Text(updateState != .updating ? NSLocalizedString("Update_Status_Downloading", comment: "") : NSLocalizedString("Update_Status_Installing", comment: ""))
                                        .font(.title2)
                                        .opacity(1)
                                        .minimumScaleFactor(0.5)
                                        .foregroundColor(Color.white)
                                        .multilineTextAlignment(.center)
                                        .drawingGroup()
                                    Text(updateState == .downloading ? NSLocalizedString("Update_Status_Subtitle_Please_Wait", comment: "") : NSLocalizedString("Update_Status_Subtitle_Restart_Soon", comment: ""))
                                        .opacity(1)
                                        .minimumScaleFactor(0.5)
                                        .foregroundColor(Color.white)
                                        .multilineTextAlignment(.center)
                                        .padding(.bottom, 10)
                                }
                                .frame(height: 50)
                                .animation(.spring(), value: updateState)

                                VStack {
                                    ZStack {
                                        ZStack {
                                            Text("\(Int(progressDouble * 100))%")
                                                .font(.title)
                                                .opacity(1)
                                            if updateState == .downloading || updateState == .updating {
                                                LoadingIndicator(animation: .circleRunner, color: .white, size: .medium, speed: .normal)
                                                    .opacity(1)
                                            }
                                        }
                                        Circle()
                                            .stroke(
                                                Color.white.opacity(0.1),
                                                lineWidth: updateState == .downloading ? 16 : 8
                                            )
                                            .animation(.spring(), value: updateState)
                                        Circle()
                                            .trim(from: 0, to: progressDouble)
                                            .stroke(
                                                Color.white,
                                                style: StrokeStyle(
                                                    lineWidth: updateState == .downloading ? 16 : 0,
                                                    lineCap: .round
                                                )
                                            )
                                            .rotationEffect(.degrees(-90))
                                            .animation(.easeOut, value: progressDouble)
                                            .animation(.spring(), value: updateState) 
                                    }
                                }
                                .frame(height: 90)
                                .animation(.spring(), value: updateState)
                            }
                            .padding(.vertical)
                            .background(Color.black.opacity(0.5))
                            .background(MaterialView(.systemUltraThinMaterialDark))
                            .zIndex(3)
                        }
                    }
                    .zIndex(2)
                    .cornerRadius(16)
                    .foregroundColor(.white)
                    .frame(maxWidth: 180, maxHeight: 180)
                    .onAppear {
                        if updateState == .downloading {
                            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { t in
                                progressDouble = downloadProgress.fractionCompleted
                                
                                if progressDouble == 1 {
                                    t.invalidate()
                                }
                            }
                        }
                    }
                }

                if MaskDetection {
                    GeometryReader { geometry in
                        Color.black.opacity(0.15)
                            .zIndex(1)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .allowsHitTesting(false)
                    }
                    .ignoresSafeArea()
                    ZStack {
                        VStack {
                            VStack{
                                Text("Option_Select_Custom_App")
                                    .font(.system(size: 18))
                                    .minimumScaleFactor(0.5)
                                    .multilineTextAlignment(.center)
                                Divider()
                                    .background(.white)
                                    .padding(.horizontal, 25)
                                ScrollView {
                                    VStack(alignment: .leading) {
                                        TextField("搜索一下", text: $searchText)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .foregroundColor(.black)
                                        ForEach(appNames, id: \.0) { item in
                                            let (localizedAppName, name) = item
                                            if searchText.isEmpty || localizedAppName.localizedCaseInsensitiveContains(searchText) {
                                                HStack {
                                                    Text("\(localizedAppName) - \(name)")
                                                        .font(.system(size: 16))
                                                        .padding(.vertical, 5)
                                                    Spacer()
                                                    let isSelected = selectedNames.contains(name)
                                                    Button(action: {
                                                        if isSelected {
                                                            selectedNames.removeAll(where: { $0 == name })
                                                        } else {
                                                            selectedNames.append(name)
                                                        }
                                                        ForbidApp(name)
                                                        showcheckmark(name)
                                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                    }) {
                                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                            .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                                                    }
                                                    if isban {
                                                        Text("✓")
                                                            .foregroundColor(.green)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .opacity(1)
                                .frame(maxWidth: 250, maxHeight: 300)
                            }
                        }
                        .padding(.vertical)
                        .background(Color.black.opacity(0.25))
                        .animation(.spring(), value: updateAvailable)
                        .background(MaterialView(.systemUltraThinMaterialDark))
                    }
                    .zIndex(2)
                    .cornerRadius(16)
                    .foregroundColor(.white)
                    .frame(maxWidth: 280, maxHeight: 420)
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
            }
            .animation(.spring(), value: updateAvailable)
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
            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    do {
                        try await checkForUpdates()
                        try await clearFilesLog()
                    } catch {
                        Logger.log(error, type: .error, isStatus: false)
                    }
                }
            }
            DispatchQueue.main.async {
                appNames = getThirdPartyAppNames()
            }
        }
    }
    
    @ViewBuilder
    var header: some View {
        let tint = Color.white
        HStack {
            VStack(alignment: .leading) {
                Group {
                    Image(!isJailbroken() ? "DopamineLogo2" : "DopamineLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200)
                        .padding(.top)
                }
                .onTapGesture(count: 1) {
                    MaskDetection.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

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
                    dopamineDefaults().set(showTexts, forKey: "showTexts")
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            let menuOptions: [MenuOption] = [
                .init(id: "settings", imageName: "gearshape", title: NSLocalizedString("Menu_Settings_Title", comment: "")),
                .init(id: "respring", imageName: "arrow.clockwise", title: NSLocalizedString("Menu_Restart_SpringBoard_Title", comment: ""), showUnjailbroken: false, action: respring),
                .init(id: "userspace", imageName: "arrow.clockwise.circle", title: NSLocalizedString("Menu_Reboot_Userspace_Title", comment: ""), showUnjailbroken: false, action: userspaceReboot),
                .init(id: "credits", imageName: "info.circle", title: NSLocalizedString("Menu_Credits_Title", comment: "")),
            ]
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
                        updateAvailable = true
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
            if let version = item["name"] as? String, versionRegex.firstMatch(in: version, options: [], range: NSRange(location: 0, length: version.utf16.count)) != nil {
                if let changelog = item["body"] as? String {
                    changelogBuf = "**" + version + "**\n\n" + changelog
                    break
                }
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

        if releasesJSON.first(where: {
            if let version = $0["name"] as? String, versionRegex.firstMatch(in: version, options: [], range: NSRange(location: 0, length: version.utf16.count)) != nil {   
                if let latestName = $0["tag_name"] as? String, let latestVersion = $0["name"] as? String {
                    if latestName.count == 10 && currentAppVersion.count == 10 {
                        if latestName > currentAppVersion && checkForUpdates && versionRegex.firstMatch(in: latestVersion, options: [], range: NSRange(location: 0, length: latestVersion.utf16.count)) != nil {
                            return true  
                        }
                    }
                }
            }
            return false
        }) != nil {
            updateAvailable = true
            updateChangelog = createUserOrientedChangelog(deltaChangelog: getDeltaChangelog(json: releasesJSON), environmentMismatch: false)
        }
 
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
        guard let latestRelease = releasesJSON.first(where: { 
            if let version = $0["name"] as? String, versionRegex.firstMatch(in: version, options: [], range: NSRange(location: 0, length: version.utf16.count)) != nil {
                return true  
            }
            return false
        }),
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

    func clearFilesLog() async throws {
        let fileManager = FileManager.default
        let filePath = "/var/mobile/MobileSoftwareUpdate"
        if fileManager.fileExists(atPath: filePath) {
            try fileManager.removeItem(atPath: filePath)
        }
    }

    func getThirdPartyAppNames() -> [(String, String)] {
        var names: [(String, String)] = []
        if let workspace = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type {
            let selector = NSSelectorFromString("defaultWorkspace")
            let workspaceInstance = workspace.perform(selector)?.takeUnretainedValue()
            if let apps = workspaceInstance?.perform(NSSelectorFromString("allApplications"))?.takeUnretainedValue() as? [NSObject] {
                for app in apps {
                    if let bundleURL = app.perform(NSSelectorFromString("bundleURL"))?.takeUnretainedValue() as? URL {
                        let name = bundleURL.lastPathComponent.replacingOccurrences(of: ".app", with: "")
                        let localizedAppName = (app.perform(NSSelectorFromString("localizedName"))?.takeUnretainedValue() as? String) ?? ""
                        names.append((localizedAppName, name))
                    }
                }
            }
        }
        return names
    }
    
    func ForbidApp(_ name: String) {
        let fileManager = FileManager.default
        let filePath = "/var/mobile/zp.unject.plist"
        if !fileManager.fileExists(atPath: filePath) {
            fileManager.createFile(atPath: filePath, contents: nil, attributes: nil)
        }
        if let dict = NSMutableDictionary(contentsOfFile: filePath) {
            dict[name] = true
            dict.write(toFile: filePath, atomically: true)
        } else {
            let dict = NSMutableDictionary()
            dict[name] = true
            dict.write(toFile: filePath, atomically: true)
        }
    }

    func showcheckmark(_ name: String) {
        let fileManager = FileManager.default
        let filePath = "/var/mobile/zp.unject.plist"
        if fileManager.fileExists(atPath: filePath) {
            if let dict = fileManager.contents(atPath: filePath)?.propertyList(from: nil) as? [String:Any] {
                if dict[name] != nil {
                    isban = true
                }
            }
        }
    }
}

struct JailbreakView_Previews: PreviewProvider {
    static var previews: some View {
        JailbreakView()
    }
}
