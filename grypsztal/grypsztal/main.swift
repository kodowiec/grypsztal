//
//  main.swift
//  grypsztal / voltageshiftgui
//
//  Created by kodowiec on 25/07/2022.
//

import Foundation
import Cocoa

// 1
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// 2
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
