# grypsztal
A GUI wrapper for voltageshift  
or you can also call it a hackintosh performance manager  
  
just click, edit preset for your liking, and have it easy to switch between performance modes
NOTE: uses [SeptemberHX's voltageshift fork](https://github.com/SeptemberHX/VoltageShift) to write the MCHBAR value so the CPU unlocks its full potential

## features
- multiple presets stored in config file
- easy performance profile switching
- a nice and non intrusive menu bar icon (SF Symbols)
- quickly update MCHBAR if your CPU is limited even after changing PLs
- adjust PL, voltage offsets and also switch turbo mode


## backstory
it so happens that my [hackintosh laptop](https://github.com/kodowiec/HP-Elitebook-x360-1040-G6-Opencore) has some weird quirks in bios/uefi that ain't letting that baby to speed up so easily, and i eventually got tired of manually writing the voltageshift command, and yea, i tried writing scripts in .command files but oh boy, i got bored of entering my sudo password in terminal every time

###

## credits
- sicreative for [voltageshift](https://github.com/sicreative/VoltageShift) -- obviously this project wouldn't be possible without it
- septemberhx for his [hackintosh guide](https://github.com/SeptemberHX/HP-Spectre-X360-13-late-2018-Hackintosh#for-20w-tdp) that showed me it is possible to unlock the tdp with his [modded voltageshift](https://github.com/SeptemberHX/VoltageShift)
