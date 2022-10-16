//
//  UtilityView.swift
//  mugunghwa
//
//  Created by Soongyu Kwon on 9/17/22.
//

import SwiftUI

// Badge Colour Changing
func changeColour(colour: UIColor) {
    var badge: UIImage = getRoundImage(12, 24, 24)!
    
    if UIDevice.current.userInterfaceIdiom == .pad {
        badge = getRoundImage(24, 48, 48)!
    }
    
    badge = changeImageColour(badge, colour)!
    
    let savePath = "/var/mobile/SBIconBadgeView.BadgeBackground:26:26.cpbitmap"
    let targetPath = "/var/mobile/Library/Caches/MappedImageCache/Persistent/SBIconBadgeView.BadgeBackground:26:26.cpbitmap"
    
    let helper = ObjcHelper.init()
    helper.image(toCPBitmap: badge, path: savePath)
    
    let fileManager = FileManager.default
    do {
        try fileManager.removeItem(atPath: targetPath)
    } catch {
        print("Failed to revert changes")
    }
    do {
        try fileManager.moveItem(atPath: savePath, toPath: targetPath)
    } catch {
        print("Failed to move item")
    }
}

func changeImageColour(_ src_image: UIImage?, _ color: UIColor?) -> UIImage? {

    let rect = CGRect(x: 0, y: 0, width: src_image?.size.width ?? 0.0, height: src_image?.size.height ?? 0.0)
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()
    if let CGImage = src_image?.cgImage {
        context?.clip(to: rect, mask: CGImage)
    }
    if let cgColor = color?.cgColor {
        context?.setFillColor(cgColor)
    }
    context?.fill(rect)
    let colorized_image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return colorized_image
}

func getRoundImage(_ radius: Int, _ width: Int, _ height: Int) -> UIImage? {
    
    let rect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()
    context?.setFillColor(UIColor.black.cgColor)
    context?.fill(rect)
    let src_image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    let image_layer = CALayer()
    image_layer.frame = CGRect(x: 0, y: 0, width: src_image?.size.width ?? 0.0, height: src_image?.size.height ?? 0.0)
    image_layer.contents = src_image?.cgImage

    image_layer.masksToBounds = true
    image_layer.cornerRadius = CGFloat(radius)

    UIGraphicsBeginImageContextWithOptions(src_image?.size ?? CGSize.zero, false, 0.0)
    if let aContext = UIGraphicsGetCurrentContext() {
        image_layer.render(in: aContext)
    }
    let rounded_image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return rounded_image
}

func badgeButtonDiabled() -> Bool {
    return checkSandbox()
}

// MARK: - Home Gesture
func applyHomeGuesture(_ enabled: Bool) {
    if enabled {
        // Enable
        let helper = ObjcHelper.init()
        checkAndCreateBackupFolder()
        
        let prefs = MGPreferences.init(identifier: "me.soongyu.mugunghwa")
        if prefs.dictionary["DeviceSubType"] == nil {
            prefs.dictionary.setValue(helper.getDeviceSubType(), forKey: "DeviceSubType")
            prefs.updatePlist()
        }
        
        helper.updateDeviceSubType(2436)
    } else {
        // Disable
        checkAndCreateBackupFolder()
        let helper = ObjcHelper.init()
        let prefs = MGPreferences.init(identifier: "me.soongyu.mugunghwa")
        if prefs.dictionary["DeviceSubType"] != nil {
            helper.updateDeviceSubType(prefs.dictionary["DeviceSubType"] as! Int)
        }
    }
}

func checkAndCreateBackupFolder() {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: "/private/var/mobile/mugunghwa/") {
        try? fileManager.createDirectory(atPath: "/private/var/mobile/mugunghwa", withIntermediateDirectories: true)
    }
    
    if !fileManager.fileExists(atPath: "/private/var/mobile/mugunghwa/Themes") {
        try? fileManager.createDirectory(atPath: "/private/var/mobile/mugunghwa/Themes", withIntermediateDirectories: true)
    }
}

func getCurrentState() -> Bool {
    checkAndCreateBackupFolder()
    let helper = ObjcHelper.init()
    let prefs = MGPreferences.init(identifier: "me.soongyu.mugunghwa")
    
    if prefs.dictionary["DeviceSubType"] != nil {
        if prefs.dictionary["DeviceSubType"] as! Int != helper.getDeviceSubType() as! Int {
            return true
        }
    }
    
    return false
}

func homeGestureToggleDisabled() -> Bool {
    if checkSandbox() {
        return true
    }
    
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
    let unsupported: [String] = ["iPhone10,3", "iPhone10,6", "iPhone11,2", "iPhone11,4", "iPhone11,6", "iPhone11,8", "iPhone12,1", "iPhone12,3", "iPhone12,5", "iPhone13,1", "iPhone13,2", "iPhone13,3", "iPhone13,4", "iPhone14,2", "iPhone14,3", "iPhone14,4", "iPhone14,5"]
    
    if unsupported.contains(identifier) {
        return true
    }
    
    return false
}

func homeGestureButtonDisabled(_ enabled: Bool) -> Bool {
    if homeGestureToggleDisabled() || checkSandbox() {
        return true
    }
    
    checkAndCreateBackupFolder()
    let prefs = MGPreferences.init(identifier: "me.soongyu.mugunghwa")
    if prefs.dictionary["DeviceSubType"] == nil && !enabled {
        return true
    }
    
    return false
}

// MARK: - Theme
func getThemesList() -> [String] {
    checkAndCreateBackupFolder()
    
    var tmp = ["Default"]
    
    let list = getList(atPath: URL(string: "/private/var/mobile/mugunghwa/Themes")!)
    for e in list {
        tmp.append(e.lastPathComponent)
    }
    
    return tmp
}

func getThemeSelection() -> Int {
    let prefs = MGPreferences.init(identifier: "me.soongyu.mugunghwa")
    let tmp = prefs.dictionary["selectedTheme"]
    
    var selected = ""
    if (tmp != nil) {
        selected = prefs.dictionary["selectedTheme"] as! String
    }
    
    if (selected == "Mugunghwa/Default") {
        return 0
    }
    
    if (selected != "") {
        let selectedInInt = getThemesList().firstIndex(of: selected)
        if (selectedInInt != nil) {
            return selectedInInt!
        } else {
            return 0
        }
    }
    
    return 0
}

func getBundles() -> [AppBundle] {
    var tmp = [AppBundle]()
    let tmpBundleList = getList(atPath: URL(string: "/private/var/containers/Bundle/Application")!)
    
    for e in tmpBundleList {
        let bundle = AppBundle.init(withPath: e)
        tmp.append(bundle)
    }
    
    return tmp
}

func applyTheme(selection: Int) {
    let bundleList = getBundles()
}


// MARK: - SwiftUI
struct UtilityView: View {
    @State private var dotColour = Color.red
    @State private var homeGesture = getCurrentState()
    @State private var showingAlert = false
    @State private var selectedTheme = getThemeSelection()
    @State private var themesList = getThemesList()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Badge Colour Changer")) {
                    ColorPicker(selection: $dotColour) {
                        Text("Colour")
                    }
                    Button("Apply") {
                        changeColour(colour: UIColor(dotColour))
                        showingAlert.toggle()
                    }.disabled(badgeButtonDiabled())
                    .alert(isPresented: $showingAlert) {
                        Alert(
                            title: Text("Done!"),
                            message: Text("Respring your device to apply changes."),
                            primaryButton: .default(
                                Text("Respring"),
                                action: {
                                    let helper = ObjcHelper.init()
                                    helper.respring()
                                }
                            ),
                            secondaryButton: .cancel(
                                Text("Not Now"),
                                action: {}
                            )
                        )
                    }
                }
                
                Section(header: Text("Home Gesture"), footer: Text("Note: This manipulates device layout to iPhone XS layout. It is totally safe but you may experience some UI glitches and screenshot is not working at the moment.")) {
                    Toggle("Enabled", isOn: $homeGesture)
                        .disabled(homeGestureToggleDisabled())
                    Button("Apply") {
                        applyHomeGuesture(homeGesture)
                        showingAlert.toggle()
                    }.disabled(homeGestureButtonDisabled(homeGesture))
                }
                
                Section(header: Text("Passcode Theming")) {
                    NavigationLink(destination: PasscodeThemeView(), label: {
                        Text("Configuration")
                    }).disabled(checkSandbox())
                }
                
                Section(header: Text("Icon Theming"), footer: Text("Place icon images at /var/mobile/mugunghwa/Themes/(theme name)/\nYou can also import iconpack from Havoc by sharing it to Mugunghwa")) {
                    Picker("Selected Theme", selection: $selectedTheme) {
                        ForEach(0..<themesList.count, id: \.self) { num in
                            Text("\(themesList[num])").tag(num)
                        }
                    }.onChange(of: selectedTheme) { tag in
                        let prefs = MGPreferences.init(identifier: "me.soongyu.mugunghwa")
                        prefs.dictionary.setValue(themesList[tag], forKey: "selectedTheme")
                        if tag == 0 {
                            prefs.dictionary.setValue("Mugunghwa/Default", forKey: "selectedTheme")
                        }
                        prefs.updatePlist()
                    }
                    NavigationLink(destination: ThemesManageView(), label: {
                        Text("Manage Themes")
                    }).disabled(checkSandbox())
                    Button("Apply") {
                        applyTheme(selection: selectedTheme)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Utilities")
        }
    }
}

struct UtilityView_Previews: PreviewProvider {
    static var previews: some View {
        UtilityView()
    }
}
