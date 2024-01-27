Batch script to setup Windows 10 and 11

INSTRUCTIONS:
1) Install Windows with your default user as administrator (the only user you create during windows first setup)
2) Copy this folder do a permanent location (C:\ is a good sugestion)
3) Execute setup.cmd
4) If the script prompts you to rename the computer it'll will reboot and if conected to AC adapter it'll automatically execute the script a minute after logon
5) If any app install via winget fails, a file named fix-setup.cmd will be created. Check the file content to see with install failed and deal with those software accordingly. (The most common issue is security hash verification fails, so using "winget install" with the flag --ignore-security-hash might solve the issue - this can't be executed as admin)
6) When finished the execution of the script, check for errors. An error log can be found in the file errorlog.txt

config folder:
- configuration files - edit them according to your needs

Files folder
- Files in this folder with .exe or .msi extensions will be automatically launched, but possibly still in interactive mode
- Files with .url extension will be copied to Desktop and Start Menu
- The image intended to be used as wallpaper and/or lockscreen should be in this folder