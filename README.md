# Remove-Duplicates - Documentation
A simple Powershell script that can be used to list / move / remove duplicate files (contained in the same folder) on Windows systems. 
- It performs a search of a folder and all subfolders, finding duplicate files within each folder, and depending on the mode, can either list, move, or delete (to recycle bin) those duplicate files.
- NOTE: It's duplicate search scope is <b>within-folders</b> rather than across-folder. If you prefer a across-folder scope of search for duplicates, use <a href="https://github.com/theohbrothers/Remove-Duplicates-across-folders">this instead</a>.

## Features:
- Searches through a folder and all decendent folders (i.e. subfolders) for duplicates that exist WITHIN a folder. 
	- The process is as follows: It begins in one folder, searches for duplicates within this folder, and then does whatever it has to with those duplicate files based on the configuration. The process then repeats on another folder.
	- e.g. <code>D:\folder_with_dups\1.txt</code> and <code>D:\folder_with_dups\2.txt</code> are identical in content, file size, and in the same folder. The script marks this as duplicates.
- Choose a mode for one of the following:
	- list duplicates 
	- move duplicates to a newly created folder within the folder where duplicates exist, leaving the original file intact (shortest named file)
	- delete duplicates to the recycle bin, leaving the original file intact (shortest named file)
- Outputs all duplicates to a csv file (duplicates.csv) for your review.
- Logs the entire console session (output.txt) to the script's directory for you to review any duplicates. 

## Requirements:
- Powershell v4
- Windows environment
- User with read/write/modify permissions on script and searched directories.

## Installation/usage:
- Open the <code>Remove-Duplicates.ps1</code> in your favourite text editor and configure the script settings at the top of the script (instructions are included).
- Right click on the script in explorer and select <code>Run with Powershell</code>. (should be present on Windows 7 and up)
- Alternatively, open command prompt in the script directory, and run <code>Powershell .\Remove-Duplicates.ps1</code>

## NOTE:
- By default, script directory (where you run the script) needs <b>write permission</b> for session logging (output.txt). If you prefer not to, turn off session logging in script configuration.
- If using mode 1 or 2, ensure directories searched have <b>read,write,execute,modify permissions</b>.

## FAQ
What is a <b>duplicate file</b>?:
- Has separate file[s] with:
	- Same container folder
	- Same file contents (file hash)
	- Same file size
	
What is the<b> original file</b>?:
- A duplicate file but with the shortest name among all duplicates found.

Q: Help! I am getting an error <code>'File C:\Users\User\Remove-Duplicates\Remove-Duplicates.ps1 cannot be loaded because the execution of scripts is disabled on this system. Please see "get-help about_signing" for more details.'</code>
- You need to allow the execution of unverified scripts. Open Powershell as administrator, type <code>Set-ExecutionPolicy Unrestricted -Force</code> and press ENTER. Try running the script again. You can easily restore the security setting back by using <code>Set-ExecutionPolicy Undefined -Force</code>

## Background:
- Most people create duplicate files within a specific folder either <i>accidentally</i>, or <i>forgetfully</i>, or <i>obliviously</i>
	- Accidentally: For instance, you create a file, and accidentally press Ctrl-C and Ctrl-V in the wrong place - a possible scenario, in explorer while highlighting on a file or a bunch of files, until you notice a bunch of copied files with appended '-Copy' or '- Copy 1' or '1 - Copy - Copy (1)'.
	- Forgetfully: You are working on a .doc, saving it once. Then a minute later you forgot you saved it, and save it again in another name. Now you have two identical files in a certain folder.
	- Obliviously: You restore files from Onedrive Web App (e.g. onedrive.com). Then later the same file from Recycle bin. You now have a duplicate in the same folder probably with suffix 'Copy 1' or some sort.


