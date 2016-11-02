# rmdups - Powershell script to list/move/remove all duplicate files on Windows systems. 
By default, it logs duplicates in the script directory to file called output.txt for review.

Requirements:
- Powershell v4
- Windows environment

Installation:
-Open the rmdups.ps1 in your favourite text editor and configure the script settings at the top of the script (instructions are included).
-Right click on the script in explorer and select 'Run with Powershell'.

NOTE:
-Script directory (where you save the script) needs write permission by default. This enables the duplicates log to be created by default for your review.
-Directories searched may need read,write,execute,modify permissions (if using mode 1 or 2).


