############### configure script settings ##########
 # Absolute path to directory where duplicates might exist. May contain trailing slash. Folders paths only.
$startingdir = "D:\duplicatesfolder" 

# Mode: action to take for duplicates found
# 0 - List duplicates only. will not move or delete duplicates.
# 1 - Delete files to recycle bin.
# 2 - Move duped files to $dupdir that will be created.  
# Default: 0
$mode = 0

# The name of the directory name where duplicates will be moved. Cannot contain the following characters:/ \ : * ? < > |
# NOTE: Applies only to mode 2. Edit between the quotes
# Default: "!dup"
$dupdir = "!dup" 

# Whether to output a transcript of the console output
# 0 - Off
# 1 - On
# Default: 1
$mode_output_cli = 1

# File name of the console transcript. File will be created in same directory as powershell script.
# NOTE: Edit between the quotes. May not contain characters: / \ : * ? < > |
# Default: "output.txt"
$output_cli_file = "output.txt"

# Whether to write the duplicates as .csv file for review.
# 0 - Off
# 1 - On
# Default: 1
$mode_output_duplicates = 1

# File name of the duplicates .csv file. File will be created in same directory as powershell script.
# NOTE: Edit between the quotes. May not contain characters: / \ : * ? < > |
# Default: "duplicates.csv"
$output_dup_file = "duplicates.csv"

# Debug mode
# 0 - Off
# 1 - On
# Default: 0
$debug = 0
############################################################# 
# Get script directory, set as cd
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Set-Location $scriptDir
Write-Host "Script directory: $scriptDir" -ForegroundColor Green

# Check parameters' argument validity
if ($startingdir -match '[\*\"\?\<\>\|]'){
	Write-Host 'Invalid starting directory! May not contain characters: : * ? < > | ' -ForegroundColor Yellow
	pause; exit
}elseif(!$(Test-Path $startingdir -PathType Container)) {
	Write-Host 'Invalid starting directory! Must be a folder. ' -ForegroundColor Yellow
	pause; exit
}elseif(($mode -gt 2) -or ($mode -lt 0)) { 
	Write-Host "Invalid mode! Use integer values from 0 to 2." -ForegroundColor Yellow
	pause; exit
}elseif ( ($dupdir -match '[\/\\\:\*\"\?\<\>\|]') -and ($mode -eq 2) ){
	Write-Host 'Invalid duplicates directory! May not contain characters: / \ : * ? < > | ' -ForegroundColor Yellow
	pause; exit
}elseif(($mode_output_cli -gt 1) -or ($mode_output_cli -lt 0)) { 
	Write-Host "Invalid console output mode! Use integer values from 0 to 1." -ForegroundColor Yellow
	pause; exit
}elseif($output_cli_file -match '[\/\\\:\*\"\?\<\>\|]') { 
	Write-Host "Invalid output file name of console session! May not contain characters: / \ : * ? < > | " -ForegroundColor Yellow
	pause; exit
}elseif(($mode_output_duplicates -gt 1) -or ($mode_output_duplicates -lt 0)) { 
	Write-Host "Invalid duplicates output mode! Use integer values from 0 to 1." -ForegroundColor Yellow
	pause; exit
}elseif($output_dup_file -match '[\/\\\:\*\"\?\<\>\|]') { 
	Write-Host "Invalid output file name of duplicates! May not contain characters: / \ : * ? < > | " -ForegroundColor Yellow
	pause; exit
}elseif(($debug -gt 1) -or ($debug -lt 0)) { 
	Write-Host "Invalid debug mode! Use integer values from 0 to 1." -ForegroundColor Yellow
	pause; exit
}

# Check for write permissions in script directory
if ($mode_output_cli -eq 1) {
	# check for write permissions 
	Try { [io.file]::OpenWrite($output_cli_file).close() }
	Catch { Write-Warning "Script directory has to be writeable to output the cli session!" }
}

# Begin output of cli 
if($mode_output_cli -eq 1) {
	$ErrorActionPreference="SilentlyContinue"
	Stop-Transcript | out-null
	$ErrorActionPreference = "Continue"
	Start-Transcript -path $output_cli_file -append
}

# Prepare duplicates output
if ($mode_output_duplicates -eq 1) {
	$output = @( '"Duplicate File","Duplicate File Size","Duplicate File Hash","Original File","Original File Size","Original File Hash"' | Out-File $output_dup_file -Encoding utf8 )
}

# Show configuration options to user
Write-Host "Checking configuration options...Configuation options are valid" -ForegroundColor Green

# Begin prompts to user to confirm
Write-Host "`nAre you sure you want to run the script?" -ForegroundColor Yellow
if($mode -eq 1) { Write-Host "`tNOTE: You have configured the script to delete files to the recycle bin." -ForegroundColor Yellow} 
Write-Host "Press x to exit the script now. Press ENTER to continue." -ForegroundColor Yellow
$continue = Read-Host; If ($continue -eq "x" -or $continue -eq "X") {exit}

# Get only directories recursively (i.e. directories and sub-directories and sub-sub-directories etc.)
Write-Host "`n[Retrieving all folders and sub-folders in $startingdir ...]" -ForegroundColor Cyan
$containers = @( Get-Item -Path $startingdir | ? {$_.psIscontainer} )
$containers += Get-ChildItem -Directory -Path $startingdir -Recurse -Exclude $dupdir #| ? {$_.psIscontainer}  # exclude $dupdirs

# Get all files recursively (i.e. files in starting directory and sub-directories and sub-sub-directories etc.)
Write-Host "`n[Retrieving all files in $startingdir and its subfolders...]" -ForegroundColor Cyan
$files = Get-ChildItem -Path $startingdir -File -Recurse #| Select-Object FullName, @{Name="FolderDepth";Expression={$_.DirectoryName.Split('\').Count}} | Sort-Object FolderDepth, Extension, Name # Ascending

# Get md5 hashes for all files
Write-Host "`n[Calculating files' hashes ... this might take some time ...]" -ForegroundColor Cyan
$files_hashes = @{} # format: fullpathStr => md5Str
$files | foreach {
	$fullpath = $_.FullName
	$md5 = (Get-FileHash $fullpath -Algorithm MD5).Hash # md5 hash of this file
	if (!$files_hashes.ContainsKey($fullpath)) {
		$files_hashes.Add($fullpath, $md5)
	}else {
		# Duplicate!
		$files
	}
}
if($debug){$str = $files_hashes | Out-String ; Write-Host $str}

$containers | ForEach-Object {
$cd = $_.FullName # Current directory's full path
$filesmapping = [ordered]@{}  # All files' mapping. duplicate file will point to original file. format: Obj => Obj

# Get all files found only within this directory
$files = Get-ChildItem -Path $cd -File | sort Extension

# For each file, do
:oloop foreach($f in $files) {
	# Skip over files already checked
	if($filesmapping.Contains($f)) {
		if($debug){Write-Host "`t>Skipping(oloop)......." $f} 
		continue oloop;
	}
	if($debug){Write-Host "`n[Looking in] -" $cd}

	# Get md5 for this file.
	$duplicates = [ordered]@{}; # To store matches against this file. format: dupObj => dupObj
	$f_md5 = $files_hashes.($f.FullName)

	# Against this file, search through all files for dups
	:iloop foreach($_ in $files) {		  
		# Skip over dups alrdy stored in hash
		if($filesmapping.Contains($_)) {if($debug){Write-Host "`t>Skipping(iloop)......." $_} continue iloop}

		# Get md5 for file to be compared with
		$_md5 = $files_hashes.($_.FullName)
		if($debug){Write-Host " - f.Name:" $f.Name "`t _Name" $_.Name}
		if($debug){Write-Host " - f.BaseName:" $f.BaseName "`t _BaseName" $_.BaseName}
		if($debug){Write-Host " - f md5:" $f_md5 "`t _md5:" $_md5}

		# A dup is: same file contents (hash), same size, within the same container folder.
		if(($_.Length -eq $f.Length) -and ($f_md5 -eq $_md5)) {
			# store this first dup in hash
			if(!$duplicates.Contains($f)) {
				$duplicates.add($_, $f ); # format: dupObj(key) => thisObj(value)
			}
			# Store subsequent dups in hash
			if(!$duplicates.Contains($_)) {
				$duplicates.add($_, $f ); # format: dupObj(key) => thisObj(value)
			}
			if($debug){Write-Host "`t> Match found. File comparison: `n`t`tname: $f" "`tlast modified:" $f.LastWriteTime "`tsize:" $f.Length " vs `n`t`tname:" $_ "`t`tlast modified:" $_.LastWriteTime "`tsize:" $_.Length;}
		}else {
			if($debug){Write-Host " --- not a dupe ---" }
		}
	}

	# If only 1 match found, file matched itself: no duplicates for this file. add to filesmapping to mark as done, and continue with next file
	if($duplicates.Count -eq 1) { 
		$filesmapping.add($f, $f ); # format: thisObj(key) => thisObj(value)
		if($debug){Write-Host "`t>No dups, Skipping(oloop)......." $_} 
		if($debug){echo "-----#g----"}
		if($debug){echo $filesmapping}
		continue oloop;
	}

	# - dups found - #
	# Get shortest file name among dups. This will be the main/original file.
	$len_shortest = $f.Name.Length;
	$f_shortestName = $f; 
	$duplicates.GetEnumerator() | % { 
		$len = $_.Key.ToString().Length
		if($debug){Write-Host ">key: " $_.key "key length: $len" }
		if($len -lt $len_shortest) {
			$len_shortest = $len
			$f_shortestName = $_.Key
			if($debug){Write-Host "(current) shortest string:" $len_shortest }
		}
	}

	# Debug
	if($debug){Write-Host "----#duplicates(before)-----"}
	if($debug){echo $duplicates}

	# Map all dups to their main/original file with the shortest name
	foreach($key in $($duplicates.keys)){
		# set key's value as shortest name
		$duplicates[$key] = $f_shortestName # format: dupObj(key) => oriObj(value)
		# add new mapping to filesmapping to mark as done
		$filesmapping.Add($key, $duplicates[$key]) # format: dupObj(key) => oriObj(value)
	}

	# debug
	if($debug){Write-Host "----#duplicates(after)-----"}
	if($debug){echo $duplicates}
	if($debug){Write-Host "-----#filesmapping----"}
	if($debug){echo $filesmapping}
}

$j=0 # Total dup count within this directory
if($mode -eq 0) {
	$filesmapping.GetEnumerator() | % {
		if($_.key.FullName -ne $_.value.FullName) { # exclude the original which has key==value
			$j++
			if ($j -eq 1) { Write-Host "`n[Mode: $mode - Listing duplicate files, and their original file]" -ForegroundColor Cyan }
			if ($j -eq 1) { Write-Host "`tdup file`t`t`t`t`toriginal file`n`t----------`t`t`t`t`t--------------" }
			Write-Host "`t" $_.key "`t`t`t`t`t"  $_.value 
		}
	}
}elseif($mode -eq 1) {
	# Delete files to recycle bin
	$filesmapping.GetEnumerator() | % { 
		if($_.key.FullName -ne $_.value.FullName) { # exclude the original which has key==value
			$j++
			if($j -eq 1) { Write-Host "[Mode: $mode - Deleting duplicate files, keeping original file(shortest name among them)] " -ForegroundColor Cyan }
			if($j -eq 1) { Write-Host "`tdup file`t`t`t`t`toriginal file`n`t----------`t`t`t`t`t--------------" }
			$f = $_.key
			$v = $_.value
			$path = $f.FullName
			$shell = new-object -comobject "Shell.Application"
			$item = $shell.Namespace(0).ParseName("$path")
			$item.InvokeVerb("delete")

			Write-Host "`tDeleting:`t" $f.FullName "`t`t`t`t`tOriginal:`t"   $v.FullName
			# Dont use Remove-item, it permanently deletes
			#Remove-item $falses
		}
	}
	if($j) { Write-Host "`tDeleting duplicates successful. Original files are left intact." -ForegroundColor Green }
}elseif($mode -eq 2) {
	$filesmapping.GetEnumerator() | % { 
		if($_.key.FullName -ne $_.value.FullName) { # exclude the original which has key==value
			if($j -eq 1) { Write-Host "`n[Mode: $mode - Moving duplicate files to $dupdir, leaving intact original file] `n`tFolder: $cd" -ForegroundColor Cyan }
			$j++
			$f = $_.key;
			Write-Host "`t`tMoving dup file  to: $dupdir\$f"
			# Create dup directory if not existing
			$duppath = $cd + "\$dupdir"
			if(!$(Test-Path $duppath -PathType Container)) {
				New-Item -ItemType Directory -Force -Path $duppath
			}
			# Move files
			Move-Item "$cd\$f" "$duppath\$f"
		}
	}   
}

# tell user no dups found in this folder 
if($j -eq 0) { Write-Host "`tNo duplicates in: $cd" -ForegroundColor Green }

# show summary only if dups exist
$t = $files.Count # total file count within this directory
if($j) { Write-Host " ---------- `n| summary | `n ---------- `n - original file count:$($t-$j) `n - duplicate file count:$j `n - total files: $t" -ForegroundColor Green }

# output duplicates
$filesmapping.GetEnumerator() | % {
	if($_.key.FullName -ne $_.value.FullName) {
		$k = $_.key
		$v = $_.value
		$k_fullpath = $k.FullName
		$k_size_in_kB = "$($k.Length/1000) kB"
		$k_hash = $files_hashes.($k.FullName)
		$v_fullpath = $v.FullName
		$v_size_in_kB = "$($v.Length/1000) kB"
		$v_hash = $files_hashes.($v.FullName)
		$output += "`"$k_fullpath`",`"$k_size_in_kB`",`"$k_hash`",`"$v_fullpath`",`"$v_size_in_kB`",`"$v_hash`""
	}
}
}

# write all duplicates to file
$output |  Out-File $output_dup_file -Encoding utf8 -Append

# stop transcript
if($mode_output_cli -eq 1) {
	Stop-Transcript
}