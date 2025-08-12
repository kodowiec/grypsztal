//
//  ViewController.swift
//  grypsztal / voltageshiftgui
//
//  Created by kodowiec on 25/07/2022.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

class PrefsViewController: NSViewController, NSTextFieldDelegate
{

    var currentPreset: ConfigFile.Preset!
    var appDelegate : AppDelegate!

    @IBOutlet weak var cancelButton: NSButton!

    @IBOutlet weak var presetDropdown : NSPopUpButton!

    @IBOutlet weak var editPresetName : NSTextField!
    @IBOutlet weak var editPresetIcon : NSTextField!
    @IBOutlet weak var editBinaryPath : NSTextField!
    @IBOutlet weak var editPresetShortcut : NSTextField!
    @IBOutlet weak var editPresetPL1 : NSTextField!
    @IBOutlet weak var editPresetPL2 : NSTextField!
    @IBOutlet weak var editPresetCPU : NSTextField!
    @IBOutlet weak var editPresetGPU : NSTextField!
    @IBOutlet weak var editPresetCache : NSTextField!

    @IBOutlet weak var cbTurboBoost : NSButton!
    @IBOutlet weak var cbMCHBAR : NSButton!
    
    @IBOutlet weak var cbRunAsSudo : NSButton!

    @IBOutlet weak var imagePreview : NSImageView!


    override func viewDidLoad()
    {
            super.viewDidLoad()
    }

    func setAppDelegate(AppDelegate: AppDelegate)
    {
        appDelegate = AppDelegate
    }

    func setDropdownItems()
    {
        presetDropdown?.removeAllItems()

        for preset in appDelegate.config.presets
        {
            presetDropdown?.addItem(withTitle: preset.name)
            //presetDropdown.lastItem?.image = NSImage(systemSymbolName: preset.icon, accessibilityDescription: preset.name)
            presetDropdown.lastItem?.representedObject = preset
            presetDropdown.lastItem?.keyEquivalent = preset.shortcut
            presetDropdown.lastItem?.isEnabled = true
        }


        presetDropdown.isEnabled = true

        currentPreset = presetDropdown.selectedItem?.representedObject as? ConfigFile.Preset

        populateEditFields()
    }

    func populateEditFields()
    {
        editPresetName?.stringValue = String(currentPreset.name)
        editPresetShortcut?.stringValue = String(currentPreset.shortcut)
        editPresetIcon?.stringValue = String(currentPreset.icon)
        editPresetIcon.delegate = self
        editPresetPL1?.stringValue = String(currentPreset.pl1)
        editPresetPL2?.stringValue = String(currentPreset.pl2)
        editPresetCPU?.stringValue = String(currentPreset.offset.cpu)
        editPresetGPU?.stringValue = String(currentPreset.offset.gpu)
        editPresetCache?.stringValue = String(currentPreset.offset.cache)
        editBinaryPath?.stringValue = String(appDelegate.config.binarypath ?? "")

        cbTurboBoost?.state = (currentPreset.turbo) ? NSControl.StateValue.on : NSControl.StateValue.off
        cbMCHBAR?.state = (currentPreset.mchbar) ? NSControl.StateValue.on : NSControl.StateValue.off
        
        cbRunAsSudo?.state = (appDelegate.config.runAsAdmin ?? true) ? NSControl.StateValue.on : NSControl.StateValue.off

        imagePreview.image = NSImage(systemSymbolName: currentPreset.icon, accessibilityDescription: "preset icon")

    }

    func controlTextDidChange(_ obj: Notification) {
        let textField = obj.object as! NSTextField
        imagePreview.image = NSImage(systemSymbolName: textField.stringValue, accessibilityDescription: "preset icon")
        textField.stringValue = textField.stringValue
      }

    @IBAction func applyPresetSettings(sender:NSButton)
    {
        var pres = appDelegate.config.presets[presetDropdown.indexOfSelectedItem]
        pres.name = editPresetName.stringValue
        pres.icon = (imagePreview.image != nil) ? editPresetIcon.stringValue : "plus.circle"
        pres.shortcut = editPresetShortcut.stringValue
        pres.pl1 = Int(editPresetPL1.stringValue)!
        pres.pl2 = Int(editPresetPL2.stringValue)!
        pres.turbo = (cbTurboBoost.state == NSControl.StateValue.on)
        pres.mchbar = (cbMCHBAR.state == NSControl.StateValue.on)
        pres.offset.cpu = Int(editPresetCPU.stringValue)!
        pres.offset.gpu = Int(editPresetGPU.stringValue)!
        pres.offset.cache = Int(editPresetCache.stringValue)!
        appDelegate.config.presets[presetDropdown.indexOfSelectedItem] = pres
        appDelegate.config.binarypath = editBinaryPath.stringValue
        appDelegate.config.runAsAdmin = cbRunAsSudo.state == NSControl.StateValue.on
        currentPreset = pres
        setDropdownItems()
        appDelegate.setupMenus()
        appDelegate.writeConfigFile()
        populateEditFields()
    }

    func menuItemClicked(preset: ConfigFile.Preset)
    {
        currentPreset = preset
        populateEditFields()
    }

    @IBAction func cancelButtonAction(sender: NSButton)
    {
        self.view.window?.close()
    }

    @IBAction func popUpButtonUsed(_ sender: NSPopUpButton) {
        menuItemClicked(preset: (sender.selectedItem?.representedObject as? ConfigFile.Preset)!)
    }

    @IBAction func cancelButtonActionWithSender(sender: NSButton)
    {
        cancelButtonAction(sender: sender)
    }

    @IBAction func addPresetAction(sender: NSButton)
    {
        appDelegate.config.presets.append(ConfigFile.Preset(name: "new preset", icon: "plus.circle", shortcut: "0", pl1: 16, pl2: 28, turbo: true, mchbar: false, offset: ConfigFile.Preset.VSOffset(cpu: 0, gpu: 0, cache: 0, sa: 0, aio: 0, dio: 0)))
        setDropdownItems()
        appDelegate.setupMenus()
    }

    @IBAction func removePresetAction(sender: NSButton)
    {
        appDelegate.config.presets.remove(at: presetDropdown.indexOfSelectedItem)
        setDropdownItems()
        appDelegate.setupMenus()
    }
}

