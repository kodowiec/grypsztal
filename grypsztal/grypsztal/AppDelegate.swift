//
//  AppDelegate.swift
//  grypsztal / voltageshiftgui
//
//  Created by kodowiec on 25/07/2022.
//

import Cocoa
import Foundation

public class Box<T> {
    let unbox: T
    init(_ value: T) {
        self.unbox = value
    } }


struct ConfigFile : Codable
{
    var loadonstart : Bool
    var defaultpreset : String
    var presets : Array<Preset>
    var binarypath : String?
    
    struct Preset : Codable
    {
        var name : String
        var icon : String
        var shortcut : String
        var pl1 : Int
        var pl2 : Int
        var turbo : Bool
        var mchbar : Bool
        var offset : VSOffset
        
        struct VSOffset : Codable
        {
            var cpu : Int       // CPU voltage offset
            var gpu : Int       // GPU voltage offset
            var cache : Int     // CPU Cache voltage offset
            var sa : Int        // System Agency offset
            var aio : Int       // Analogy I/O offset
            var dio : Int       // Digital I/O offset
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow!
    
    var currentpresetname = "none"
    
    private var statusItem: NSStatusItem!
    
    public var config: ConfigFile!
    
    private var configFileLocation : URL!
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        NSApp.setActivationPolicy(.accessory)
        return false
        }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        appSupportDirCheck()
        loadConfigFile()
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "g.circle", accessibilityDescription: "grypsztal")
        }
        setupMenus()
    }
    
    func setupMenus() {
        let menu = NSMenu()
        menu.title = "grypsztal"
        
        let label = NSMenuItem()
        label.title = "Current preset: "
        label.isEnabled = false
        menu.addItem(label)
        
        let label2 = NSMenuItem()
        label2.title = currentpresetname
        label2.isEnabled = false
        menu.addItem(label2)

        menu.addItem(NSMenuItem.separator())
        
        for preset in config.presets
        {
            let tempitem = NSMenuItem()
            tempitem.title = preset.name
            tempitem.image = NSImage(systemSymbolName: preset.icon, accessibilityDescription: preset.name)
            tempitem.representedObject = preset
            tempitem.action = #selector(setPreset(_:))
            tempitem.keyEquivalent = preset.shortcut
            menu.addItem(tempitem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(withTitle: "Update MCHBAR", action: #selector(writeMCHBAR), keyEquivalent: "m")
        
        menu.addItem(withTitle: "Run voltageshift info command", action: #selector(printVSInfo), keyEquivalent: "i")
        
        menu.addItem(withTitle: "Preferences", action: #selector(spawnPrefWindow), keyEquivalent: ",")
        
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
        
    }
    
    private func changeStatusBarButton(icon: String, name: String) {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: icon, accessibilityDescription:  name)
        }
    }
    
    private func loadConfigFile()
    {
        let jsonDecoder = JSONDecoder()
        
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do
        {
            if !(FileManager.default.fileExists(atPath: configFileLocation.path))
            {
                var presets = [ConfigFile.Preset]()
                let defaultOffset = ConfigFile.Preset.VSOffset(cpu: 0, gpu: 0, cache: 0, sa: 0, aio: 0, dio: 0)
                
                presets.append(ConfigFile.Preset(name: "preset1", icon: "1.circle", shortcut: "1", pl1: 18, pl2: 26, turbo: true, mchbar: false, offset: defaultOffset))
                
                config = ConfigFile(loadonstart: false, defaultpreset: "preset1", presets: presets)
                
                writeConfigFile()
            }
            try config = jsonDecoder.decode(ConfigFile.self, from: Data(contentsOf: configFileLocation))
        }
        catch { print(error) }
    }
    
    public func writeConfigFile()
    {
        let jsonEncoder = JSONEncoder()
        
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        
        do
        {
            let encoded = try jsonEncoder.encode(config)
            let encodeString = String(data: encoded, encoding: .utf8)
            try encodeString?.write(to: configFileLocation, atomically: true, encoding: .utf8 )
        }
        catch
        {
            print(error)
        }
    }
    
    private func appSupportDirCheck()
    {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "kodowiec.grypsztal"
        let appSupportSubDirectory = applicationSupport.appendingPathComponent(bundleID,isDirectory: true)
        
        if !(FileManager.default.fileExists(atPath: appSupportSubDirectory.path))
        {
            do
            {
                try FileManager.default.createDirectory(at: appSupportSubDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            catch
            {
                print(error)
            }
        }
        
        configFileLocation = appSupportSubDirectory.appendingPathComponent("config.json", isDirectory: false)
        
        print(configFileLocation.path)
    }
    
    @objc func setPreset(_ sender : NSMenuItem) {
        let prestoset : ConfigFile.Preset
        prestoset = sender.representedObject as! ConfigFile.Preset
        if (applyPreset(prestoset))
        {
            currentpresetname = prestoset.name
            changeStatusBarButton(icon: prestoset.icon, name: prestoset.name)
            setupMenus()
        }
    }
    
    @objc func doNothing() { }
    
    @objc func spawnPrefWindow()
    {
        window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 800, height: 400),
                    styleMask: [.miniaturizable, .closable, .resizable, .titled],
                    backing: .buffered, defer: false)
                window.center()
                window.title = "grypsztal preferences"
                window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false
        
        let viewcont = PrefsViewController(nibName: "Preferences", bundle: Bundle.main)
        viewcont.setAppDelegate(AppDelegate: self)
        //viewcont.loadView()
        window.contentViewController = viewcont
        window.contentViewController?.loadView()
        viewcont.setDropdownItems()
        
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        //window.orderFrontRegardless()
    }
    
    func dialogOKCancel(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.icon = nil;
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    func dialogError(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.icon = nil;
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        return alert.runModal() == .alertFirstButtonReturn
    }

    @objc func printVSInfo()
    {
        let binaryPath = (config.binarypath == nil || config.binarypath!.isEmpty) ? "voltageshift" : config.binarypath
        let getInfoASCommand = """
            do shell script \"
            sudo \(binaryPath) info
        \" with administrator privileges
        """
        
        var error: NSDictionary?
        let scriptObject = NSAppleScript(source: getInfoASCommand)!
        let output : NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error)
        
        if (error != nil)
        {
            dialogError(question: "", text: error!.description)
            print(error)
        }
        else
        {
            dialogOKCancel(question: "", text: output.stringValue ?? "")
            print(output)
        }
    }
    
    @objc public func writeMCHBAR()
    {
        let binaryPath = (config.binarypath == nil || config.binarypath!.isEmpty) ? "voltageshift" : config.binarypath
        
        var error: NSDictionary?
        let so610 = NSAppleScript(source: """
            do shell script \"
            sudo \(binaryPath!) read 0x610
             \" with administrator privileges
            """)!
        let get610 : NSAppleEventDescriptor = so610.executeAndReturnError(&error)
        
        if (error != nil)
        {
            dialogError(question: "", text: error!.description)
            print(error)
        }
        else
        {
            var output610 = get610.stringValue!
            print(output610)
            output610 = output610.replacingOccurrences(of: " ", with: "")
            output610 = output610.replacingOccurrences(of: "(", with: "")
            output610 = output610.replacingOccurrences(of: ")", with: "")
            let intfrom610 = UInt64(output610, radix: 2)
            let hexval = String(intfrom610!, radix: 16, uppercase: false)
            print(hexval)
            
            let applyMCHBARASCommand = """
                do shell script \"
                sudo \(binaryPath!) wrmem 0xfed159a0 0x\(hexval)
                sudo \(binaryPath!) wrmem 0xfed159a4 0x\(hexval)
             \" with administrator privileges
            """
            
            var error: NSDictionary?
            let scriptObject = NSAppleScript(source: applyMCHBARASCommand)!
            let output : NSAppleEventDescriptor =  scriptObject.executeAndReturnError(&error)
            
            if (error != nil)
            {
                dialogError(question: "", text: error!.description)
                print(error)
            }
            else { print(output) }
        }
    }
    
    public func applyPreset(_ preset : ConfigFile.Preset) -> Bool
    {
        let binaryPath = (config.binarypath == nil || config.binarypath!.isEmpty) ? "voltageshift" : config.binarypath
        // sudo \(binaryPath) offset \(preset.offset.cpu) \(preset.offset.gpu) \(preset.offset.cache) \(preset.offset.sa) \(preset.offset.aio) \(preset.offset.dio)
        let applyASCommand = """
            do shell script \"
            sudo \(binaryPath!) turbo \(preset.turbo ? "1" : "0")
            sudo \(binaryPath!) power \(preset.pl1) \(preset.pl2)
            sudo \(binaryPath!) offset \(preset.offset.cpu) \(preset.offset.gpu) \(preset.offset.cache)
         \" with administrator privileges
        """
        
        var error: NSDictionary?
        let scriptObject = NSAppleScript(source: applyASCommand)!
        let output : NSAppleEventDescriptor =  scriptObject.executeAndReturnError(&error)
        
        if (error != nil)
        {
            dialogError(question: "", text: error!.description)
            print(error)
            return false
        }
        else
        {
            print(output)
            if (preset.mchbar) { writeMCHBAR() }
            return true
        }
        
    }
}
