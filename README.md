# rmdups - Documentation
## Description
A simple Powershell script that can be used to list / move / remove duplicate files on Windows systems.
- It performs a search of a folder and all subfolders, finding duplicate files within each folder, and depending on the mode, can either list, move, or delete (to recycle bin) those duplicate files.
- It is not meant to be used on a system-wide scale to remove duplicate files distributed in various folders. (It cannot!)

## Features:
- Searches through a folder and all decendent folders (i.e. subfolders) for duplicates that exist WITHIN a folder. 
	- The process is as follows: It begins in one folder, searches for duplicates within this folder, and then does whatever it has to with those duplicate files based on the configuration. The process then repeats on another folder.
	- e.g. D:\folder_with_dups\1.txt and D:\folder_with_dups\2.txt are identical. The script marks this as identical.

- Choose a mode for one of the following:
	- list duplicates 
	- move duplicates to a newly created folder within the folder where duplicates exist, leaving the original file intact (shortest named file)
	- delete duplicates to the recycle bin, leaving the original file intact (shortest named file)
- Logs the entire search session (output.txt) to the script's directory for you to review any duplicates. 

## Features absent:
- Search is NOT system-wide, but folder-specific : a file in one folder that is identical to an identical file in another folder are not considered duplicates.
	- e.g. D:\folder_with_dups\1.txt and D:\other_folder_with_dups\2.txt are identical. The script does not consider 2.txt as a duplicate of 1.txt.

## Requirements:
- Powershell v4
- Windows environment
- User with read/write/modify permissions on script and searched directories.

## Installation/usage:
- Open the rmdups.ps1 in your favourite text editor and configure the script settings at the top of the script (instructions are included).
- Right click on the script in explorer and select 'Run with Powershell'. (should be present on Windows 7 and up)
- Alternatively, open command prompt, and run <code>Powershell .\rmdups.ps1</code>

## NOTE:
- By default, script directory (where you run the script) needs write permission for session logging (output.txt). If you prefer not to, turn off session logging in script configuration.
- If using mode 1 or 2, ensure directories searched have read,write,execute,modify permissions.

## FAQ
What is a duplicate file?:
- Has separate file[s] with:
	- Same container folder
	- Same file contents (file hash)
	- Same file size
	
What is the original file?:
- A duplicate file but with the shortest name among all duplicates found.

## Background:
- Most people create duplicate files within a specific folder either accidentally, or forgetfully, or obliviously
	- Accidentally: For instance, you create a file, and accidentally press Ctrl-C and Ctrl-V in the wrong place - a possible scenario, in explorer while highlighting on a file or a bunch of files, until you notice a bunch of copied files with appended '-Copy' or '- Copy 1' or '1 - Copy - Copy (1)'.
	- Forgetfully: You are working on a .doc, saving it once. Then a minute later you forgot you saved it, and save it again in another name. Now you have two identical files in a certain folder.
	- Obliviously: You restore files from Onedrive Web App (e.g. onedrive.com). Then later the same file from Recycle bin. You now have a duplicate in the same folder probably with suffix 'Copy 1' or some sort.


