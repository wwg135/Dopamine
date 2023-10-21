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
import PhotosUI

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
    @State var upTime = "系统已运行: 加载中"
    @State var index = 0
    @State var advancedLogsTemporarilyEnabled: Bool = false
    @State var showTexts = dopamineDefaults().bool(forKey: "showTexts")
    @AppStorage("checkForUpdates", store: dopamineDefaults()) var checkForUpdates: Bool = false
    @AppStorage("verboseLogsEnabled", store: dopamineDefaults()) var advancedLogsByDefault: Bool = false
    @AppStorage("hideMount", store: dopamineDefaults()) var hideMount: Bool = false
    var requiresEnvironmentUpdate = isInstalledEnvironmentVersionMismatching() && isJailbroken()
    @State var updateState: UpdateState = .downloading
    @State var progressDouble: Double = 0
    var downloadProgress = Progress()
    @State var showDownloadPage = false
    @State var showLogView = false
    @State var versionRegex = try! NSRegularExpression(pattern: "^[12]\\.[0-9](\\.[0-9])?$")
    @State var appNames: [(String, String)] = []
    @State var selectedNames: [String] = []
    @State var deletedNames: [String] = []
    @State var MaskDetection = false
    @State var searchText = ""
    @Environment(\.colorScheme) var colorScheme
    @State var backgroundImage: UIImage?
    @State var isShowingPicker = false
    
    var isJailbreaking: Bool {
        jailbreakingProgress != .idle
    }
    
    var body: some View {
        GeometryReader { geometry in                
            ZStack {
                let isPopupPresented = isSettingsPresented || isCreditsPresented            
                Image(uiImage: backgroundImage ?? UIImage(named: "Wallpaper.jpg")!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(isPopupPresented ? 1.2 : 1.4)
                    .animation(.spring(), value: isPopupPresented)
                    .contextMenu {
                        Button(action: {
                            isShowingPicker = true
                        }) {
                            Text("从相册选择图片")
                            Image(systemName: "photo.on.rectangle")
                        }
                        Button(action: {
                            backgroundImage = UIImage(named: "Wallpaper.jpg")
                            saveImage(image: nil)
                        }) {
                            Text("恢复默认")
                            Image(systemName: "arrow.uturn.backward")
                        }
                    }
                    .sheet(isPresented: $isShowingPicker) {
                        ImagePicker(completionHandler: { image in
                            if let image = image {
                                self.backgroundImage = image
                                saveImage(image: image)
                            }
                            isShowingPicker = false
                        })
                    }
                
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
                        Color.clear
                            .zIndex(1)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .allowsHitTesting(true)
                            .onTapGesture {
                                updateAvailable = false
                            }
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
                                    Text(try! AttributedString(markdown: (isInstalledEnvironmentVersionMismatching() ?  mismatchChangelog : updateChangelog) ?? NSLocalizedString("Changelog_Unavailable_Text", comment: ""), options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                                        .font(.system(size: 16))
                                        .multilineTextAlignment(.center)
                                        .padding(.vertical)
                                }
                                .padding(.horizontal, 15)
                            }
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                                        if let downloadURL = extractDownloadURL(from: updateChangelog!, targetText: "点击当前版本下载") {
                                            Task {
                                                do {
                                                    try await downloadUpdateAndInstall(downloadURL)
                                                    updateState = .updating
                                                } catch {
                                                    showLogView = true
                                                    Logger.log("Error: \(error.localizedDescription)", type: .error)
                                                }
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Label(title: { Text("Button_Update")  }, icon: { Image(systemName: "arrow.down") })
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(MaterialView(.light)
                                        .opacity(0.5)
                                        .cornerRadius(8)
                                    )
                            }
                            .fixedSize()
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
                        Color.clear
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
                        Color.clear
                            .zIndex(1)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .allowsHitTesting(true)
                            .onTapGesture {
                                MaskDetection = false
                            }
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
                                        TextField("🔍搜索一下", text: $searchText)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        ForEach(appNames.sorted { (app1, app2) in
                                            let isSelected1 = selectedNames.contains(app1.1)
                                            let isSelected2 = selectedNames.contains(app2.1)
                                            if isSelected1 && !isSelected2 {
                                                return true
                                            } else if !isSelected1 && isSelected2 {
                                                return false
                                            } else {
                                                let localizedNameComparison = app1.0.localizedCompare(app2.0)
                                                if localizedNameComparison == .orderedSame {
                                                    return app1.0 < app2.0
                                                } else {
                                                    return localizedNameComparison == .orderedAscending
                                                }
                                            }
                                        }, id: \.1) { (localizedAppName, name) in
                                            if searchText.isEmpty || localizedAppName.localizedCaseInsensitiveContains(searchText) {
                                                HStack {
                                                    Text("\(localizedAppName)")
                                                        .font(.system(size: 16))
                                                        .padding(.vertical, 5)
                                                    Spacer()
                                                    let isSelected = selectedNames.contains(name)
                                                    let isDeleted = deletedNames.contains(name)
                                                    Toggle(isOn: Binding(
                                                        get: {
                                                            return isSelected
                                                        },
                                                        set: { newValue in
                                                            withAnimation {
                                                                if newValue {
                                                                    if isDeleted {
                                                                        deletedNames.removeAll(where: { $0 == name })
                                                                    }
                                                                    selectedNames.append(name)
                                                                    ForbidApp(name)
                                                                    dopamineDefaults().set(true, forKey: name)
                                                                } else {
                                                                    if isSelected {
                                                                        selectedNames.removeAll(where: { $0 == name })
                                                                    }
                                                                    deletedNames.append(name)
                                                                    removeApp(name)
                                                                    dopamineDefaults().set(false, forKey: name)
                                                                }
                                                                dopamineDefaults().synchronize()
                                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                            }
                                                        }
                                                    )) {
                                                        EmptyView()
                                                    }
                                                    .padding(.trailing, 10)
                                                    .onAppear {
                                                        if let savedState = dopamineDefaults().object(forKey: name) as? Bool {
                                                            if savedState {
                                                                selectedNames.append(name)
                                                                ForbidApp(name)
                                                            } else {
                                                                deletedNames.append(name)
                                                                removeApp(name)
                                                            }
                                                        } else {
                                                            deletedNames.append(name)
                                                            removeApp(name)
                                                            dopamineDefaults().set(false, forKey: name)
                                                        }
                                                        dopamineDefaults().synchronize()
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
                        .onTapGesture(count: 2) {
                            hideMount.toggle()
                        }
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
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {_ in
                let dots = ". . . "                                                                    
                if index < dots.count {
                    upTime += String(dots[dots.index(dots.startIndex, offsetBy: index)])
                    index += 1
                } else {
                    upTime = formatUptime()
                }
            }
            DispatchQueue.global(qos: .userInitiated).async {
                loadImage()
                appNames = getThirdPartyAppNames()
                Task {
                    do {
                        try await checkForUpdates()
                        try await clearFilesLog()
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
                Group {
                    Image("DopamineLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200)
                        .padding(.top)
                }
                .onTapGesture(count: 1) {
                    if isJailbroken() {
                        MaskDetection.toggle()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .disabled(!isJailbroken())

                Group {
                    Text("Title_Supported_iOS_Versions")
                        .font(.subheadline)
                        .foregroundColor(tint)
                    Text("Title_Made_By")
                        .font(.subheadline)
                        .foregroundColor(tint.opacity(0.5))
                }
                .onTapGesture(count: 1) {
                    if !(updateAvailable || showDownloadPage || showLogView || MaskDetection) {
                        showTexts.toggle()
                        dopamineDefaults().set(showTexts, forKey: "showTexts")
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .disabled(updateAvailable || showDownloadPage || showLogView || MaskDetection)
                
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
                .disabled(updateAvailable || showDownloadPage || showLogView || MaskDetection)
                                  
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

    func downloadUpdateAndInstall(_ downloadURL: URL) async throws {
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

    func removeApp(_ name: String) {
        let fileManager = FileManager.default
        let filePath = "/var/mobile/zp.unject.plist"
        if fileManager.fileExists(atPath: filePath),
        let dict = NSMutableDictionary(contentsOfFile: filePath) {
            dict.removeObject(forKey: name)
            if dict.count == 0 {
                do {
                    try fileManager.removeItem(atPath: filePath)
                } catch {
                    print("Failed to remove file: \(error)")
                }
            } else {
                dict.write(toFile: filePath, atomically: true)
            }
        }
    }

    func extractDownloadURL(from text: String, targetText: String) -> URL? {
        let pattern = "\\[.*?\\]\\((.*?)\\)"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            let urlRange = match.range(at: 1)
            if let url = URL(string: (text as NSString).substring(with: urlRange)) {
                return url
            }
        }
        return nil
    }

    func saveImage(image: UIImage?) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("background.jpg")
        if let image = image, let data = image.jpegData(compressionQuality: 1.0) {
            try? data.write(to: fileURL)
        } else {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    func loadImage() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("background.jpg")
        if let data = try? Data(contentsOf: fileURL) {
            backgroundImage = UIImage(data: data)
        }
    }
}

struct JailbreakView_Previews: PreviewProvider {
    static var previews: some View {
        JailbreakView()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    typealias UIViewControllerType = PHPickerViewController
    let completionHandler: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completionHandler: completionHandler)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let completionHandler: (UIImage?) -> Void
        
        init(completionHandler: @escaping (UIImage?) -> Void) {
            self.completionHandler = completionHandler
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else {
                completionHandler(nil)
                return
            }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                    self?.completionHandler(nil)
                } else if let image = image as? UIImage {
                    self?.completionHandler(image)
                } else {
                    self?.completionHandler(nil)
                }
            }
        }
    }
}
