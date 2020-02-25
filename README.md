# Remove-Duplicates

Removes duplicate files from a given folder on Windows / *nix systems.

The file search scope may be **within-folder** or **across-folder**.

Option to perform if duplicates are found:

0. List duplicates
1. Delete duplicates permanently, leaving the original file intact
2. Delete duplicates to the recycle bin, leaving the original file intact (only for Windows)
3. Move duplicates to a newly created folder within the folder where duplicates exist, leaving the original file intact

Option to export all duplicates to a `.json`, or `.csv` file for later review.

Option to export the entire console session (`output.txt`) to the script's directory for later review.

## Prerequisites

- Powershell v3
- `Windows` / `*nix` environment
- Write permissions on the `$pwd` to write any export files

## Dependencies

- [`Get-DuplicateItem`](https://github.com/leojonathanoh/Get-DuplicateItem) module. Install it first:

```powershell
Install-Module Get-DuplicateItem -Repository PSGallery -Scope CurrentUser -Verbose
```

## Install

```powershell
Install-Module Remove-DuplicateItem -Repository PSGallery -Scope CurrentUser -Verbose
```

## Example

```powershell
# List
Remove-Duplicates -Path D:/foo -Scope 'withinFolder'
# Delete
Remove-Duplicates -Path D:/foo -Scope 'withinFolder' -Mode 1
```

## FAQ

Q: What is a **duplicate file**?

A: Has separate file[s] with:

- Same container folder
- Same file contents (file hash)
- Same file size.

Q: What is the **original file**?

A: An original file is a duplicate file but with the shortest name among all duplicates found. For instance:

- Within-folder: `C:\folder_with_duplicates\file.txt` and `C:\folder_with_duplicates\file_with_longer_name.txt` are marked as duplicates. The former `file.txt` has a **shorter** name than the others `file_with_longer_name.txt`. Hence, `file.txt` is chosen to be the original file.

- Across-folder: `C:\folder1\file.txt` and `C:\folder2\file_with_longer_name.txt` are marked as duplicates. The former `file.txt` has a **shorter** name than the others `file_with_longer_name.txt`. Hence, `file.txt` is chosen to be the original file.

Q: Help! I am getting an error `'File C:\Users\User\Remove-Duplicates\Remove-Duplicates.ps1 cannot be loaded because the execution of scripts is disabled on this system. Please see "get-help about_signing" for more details.'`

- You need to allow the execution of unverified scripts. Open Powershell as administrator, type `Set-ExecutionPolicy Unrestricted -Force` and press ENTER. Try running the script again. You can easily restore the security setting back by using `Set-ExecutionPolicy Undefined -Force`

## Background

Most people create duplicate files within a specific folder either *accidentally*, or *forgetfully*, or *obliviously*

- Accidentally: For instance, you create a file, and accidentally press Ctrl-C and Ctrl-V in the wrong place - a possible scenario, in explorer while highlighting on a file or a bunch of files, until you notice a bunch of copied files with appended '-Copy' or '- Copy 1' or '1 - Copy - Copy (1)'.
- Forgetfully: You are working on a .doc, saving it once. Then a minute later you forgot you saved it, and save it again in another name. Now you have two identical files in a certain folder.
- Obliviously: You restore files from Onedrive Web App (e.g. onedrive.com). Then later the same file from Recycle bin. You now have a duplicate in the same folder probably with suffix 'Copy 1' or some sort.
