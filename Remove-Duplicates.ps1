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

$output_csv = ''
& { Get-Item $startingdir; Get-ChildItem -Directory -Path $startingdir -Recurse -Exclude $dupdir } | ForEach-Object {
	$container = $_
	$cd = $_.FullName # Current directory's full path
	Write-Host "`nFolder: $cd" -ForegroundColor Cyan
	
	$f = 0 # File count
	$hashes_unique = @{} # format: md5str => FileInfo
	$hashes_duplicates = @{} # format: md5str => FileInfo[]
	# Get all files found only within this directory
	Get-ChildItem -Path $container.Fullname -File | Sort-Object Name, Extension | ForEach-Object {
		$f++

		$md5 = (Get-FileHash -LiteralPath $_.FullName -Algorithm MD5).Hash # md5 hash of this file
		if ( ! $hashes_unique.ContainsKey($md5) ) {
			$hashes_unique[$md5] = $_
		}else {
			# Duplicate!
			if (!$hashes_duplicates.ContainsKey($md5)) {
				$hashes_duplicates[$md5] = [System.Collections.Arraylist]@()
				$hashes_duplicates[$md5].Add($hashes_unique[$md5]) > $null
			}
			$hashes_duplicates[$md5].Add($_) > $null
		}
	}

	# The first object will be the Original object.
	@($hashes_duplicates.Keys) | ForEach-Object {
		$key = $_
		$hashes_duplicates[$key] = $hashes_duplicates[$key] | Sort-Object { $_.Name.Length }
	}

	# Calculate duplicates count (excludes original file)
	$d = 0
	$hashes_duplicates.GetEnumerator() | ForEach-Object { $d += $_.Value.Count - 1; }

	# Tell user no dups found in this folder 
	if($d -eq 0) { 
		Write-Host "`tNo duplicates in: $cd" -ForegroundColor Green 
	}else {
		# Show summary only if dups exist
		if($d) { Write-Host "- original file count:$($f-$d) `n- duplicate file count:$d `n- total files: $f" -ForegroundColor Green }

		# Do the Task based on mode
		if($mode -eq 0) {
			Write-Host "Mode: $mode - Listing duplicate files, and their original file ..." -ForegroundColor Green
			Write-Host "`tdup file`t`t`t`t`toriginal file`n`t----------`t`t`t`t`t--------------"

			# List duplicates
			$hashes_duplicates.GetEnumerator() | ForEach-Object {
				$duplicates = $_.Value
				$duplicates[1..$($duplicates.Count - 1)] | ForEach-Object {
					Write-Host "`t$($_.FullName)`t`t`t`t`t$($duplicates[0].FullName)"  
				}
			}
		}elseif($mode -eq 1) {
			Write-Host "Mode: $mode - Deleting duplicate files, keeping original file(shortest name among them) ..." -ForegroundColor Cyan
			Write-Host "`tdup file`t`t`t`t`toriginal file`n`t----------`t`t`t`t`t--------------"

			# Delete files to recycle bin
			$hashes_duplicates.GetEnumerator() | ForEach-Object {
				$duplicates = $_.Value
				$duplicates[1..$($duplicates.Count)] | ForEach-Object {
					$duplicateFile = $_
					$originalFile = $duplicates[0]

					# This method does not prompt the user 
					Add-Type -AssemblyName Microsoft.VisualBasic
					[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($duplicateFile.FullName,'OnlyErrorDialogs','SendToRecycleBin')

					# No longer using this method because each delete will prompt the user.
					#$shell = New-Object -comobject "Shell.Application"
					#$item = $shell.Namespace(0).ParseName($duplicateFile.FullName)
					#$item.InvokeVerb("delete")

					# Dont use Remove-item, it permanently deletes
					#Remove-item $duplicateFile.FullName -Force

					Write-Host "`tDeleting:`t$($duplicateFile.FullName)`t`t`t`t`tOriginal:`t$($originalFile.FullName)"

				}
			}
			Write-Host "`tDeleting duplicates successful. Original files are left intact." -ForegroundColor Green
		}elseif($mode -eq 2) {
			Write-Host "Mode: $mode - Moving duplicate files to $dupdir, leaving intact original file..." -ForegroundColor Green 
			$hashes_duplicates.GetEnumerator() | ForEach-Object {
				$duplicates = $_.Value
				$duplicates[1..$($duplicates.Count - 1)] | ForEach-Object {
					$duplicateFile = $_
					
					# Create dup directory if not existing
					$destinationDir = Join-Path $cd $dupdir
					$destination = Join-Path $destinationDir $duplicateFile.Name
					
					if(!$(Test-Path $destinationDir -PathType Container)) {
						New-Item -ItemType Directory -Force -Path $destinationDir > $null
					}
					# Move files
					Write-Host "`tMoving dup file from $($duplicateFile.FullName) to $destination" -ForegroundColor Green
					#Move-Item $duplicateFile.FullName $destination
				}
			}
		}
	}

	# Collect content for the csv
	$hashes_duplicates.GetEnumerator() | ForEach-Object {
		$md5 = $_.Key
		$duplicates = $_.Value
		$duplicates[1..$($duplicates.Count - 1)] | ForEach-Object {
			$duplicateFile = $_
			$originalFile = $duplicates[0]
			
			$duplicateFile_size_in_kB = "$($duplicateFile.Length/1000) kB"
			$originalFile_size_in_kB = "$($originalFile.Length/1000) kB"

			$output_csv += "`n`"$($duplicateFile.FullName)`",`"$duplicateFile_size_in_kB`",`"$md5`",`"$($originalFile.FullName)`",`"$originalFile_size_in_kB`",`"$md5`""
		}
	}
}

# Export duplicates .csv
if ($output_csv) {
	if ($mode_output_duplicates -eq 1) {
		$output_csv = '"Duplicate File","Duplicate File Size","Duplicate File Hash","Original File","Original File Size","Original File Hash' + $output_csv
		$output_csv | Out-File $output_dup_file -Encoding utf8
	}
}

# Stop transcript
if($mode_output_cli -eq 1) {
	Stop-Transcript
}