# Remove-Duplicates
A simple Powershell script that can be used to list / move / remove duplicate files on Windows / *nix systems. 
It's duplicate file search scope may be **within-folders** or **across-folder**.

## Features:
- Searches for, starting from a given folder, duplicate files occuring within a descendent folder, or across descendent folders (i.e. regardless of folder).
	- Within-folder of `C:`: e.g. `C:\folder_with_dups\1.txt` and `C:\folder_with_dups\2.txt` are identical in content, file size, and in the same folder. The script marks this as duplicates.
	- Across-folder of `C:`: e.g. `C:\folder_1\1.txt` and `C:\folder_2\2.txt` are identical in content, file size, and in the same folder. The script marks this as duplicates.
- Choose an action to take with the duplicates:
	1. List duplicates 
	2. Delete duplicates to the recycle bin, leaving the original file intact (only for Windows)
	3. Delete duplicates permanently, leaving the original file intact
	4. Move duplicates to a newly created folder within the folder where duplicates exist, leaving the original file intact
- Outputs all duplicates to a .json, or .csv file for laterreview.
- Logs the entire console session (output.txt) to the script's directory for later review.

## Requirements:
- Powershell v3
- `Windows` / `*nix` environment
- User with read/write/modify permissions on script and searched directories.

## Installation/usage:
- Open the `Remove-Duplicates.ps1` in your favourite text editor and configure the script settings at the top of the script (instructions are included).
- Right click on the script in explorer and select `Run with Powershell`. (should be present on Windows 7 and up)
- Alternatively, open command prompt in the script directory, and run `Powershell .\Remove-Duplicates.ps1`

## NOTE:
- By default, script directory (where you run the script) needs **write permission** for session logging (output.txt). If you prefer not to, turn off session logging in script configuration.
- If using mode 1 or 2, ensure directories searched have **read,write,execute,modify permissions**.

## FAQ
What is a **duplicate file**?
- Has separate file[s] with:
	- Same container folder
	- Same file contents (file hash)
	- Same file size.

What is the **original file**?
- An original file is a duplicate file but with the shortest name among all duplicates found. For instance:
	- Within-folder: `C:\folder_with_duplicates\file.txt` and `C:\folder_with_duplicates\file_with_longer_name.txt` are marked as duplicates. The former `file.txt` has a **shorter** name than the others `file_with_longer_name.txt`. Hence, `file.txt` is chosen to be the original file.
	- Across-folder: `C:\folder1\file.txt` and `C:\folder2\file_with_longer_name.txt` are marked as duplicates. The former `file.txt` has a **shorter** name than the others `file_with_longer_name.txt`. Hence, `file.txt` is chosen to be the original file.

Q: Help! I am getting an error `'File C:\Users\User\Remove-Duplicates\Remove-Duplicates.ps1 cannot be loaded because the execution of scripts is disabled on this system. Please see "get-help about_signing" for more details.'`
- You need to allow the execution of unverified scripts. Open Powershell as administrator, type `Set-ExecutionPolicy Unrestricted -Force` and press ENTER. Try running the script again. You can easily restore the security setting back by using `Set-ExecutionPolicy Undefined -Force`

## Background:
- Most people create duplicate files within a specific folder either *accidentally*, or *forgetfully*, or *obliviously*
	- Accidentally: For instance, you create a file, and accidentally press Ctrl-C and Ctrl-V in the wrong place - a possible scenario, in explorer while highlighting on a file or a bunch of files, until you notice a bunch of copied files with appended '-Copy' or '- Copy 1' or '1 - Copy - Copy (1)'.
	- Forgetfully: You are working on a .doc, saving it once. Then a minute later you forgot you saved it, and save it again in another name. Now you have two identical files in a certain folder.
	- Obliviously: You restore files from Onedrive Web App (e.g. onedrive.com). Then later the same file from Recycle bin. You now have a duplicate in the same folder probably with suffix 'Copy 1' or some sort.


