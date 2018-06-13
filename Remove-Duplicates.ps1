############### configure script settings ##########
 # Absolute path to directory where duplicates might exist. May contain trailing slash. Folders paths only.
 $startingdir = "D:\duplicatesfolder" 

 # Mode: action to take for duplicates found
 # 0 - List only.
 # 1 - Delete permanently.
 # 2 - Delete to recycle bin (Only on Windows systems).
 # 3 - Move to $dupdir that will be created.  
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

# Check parameters' argument validity
try {
	$ErrorActionPreference = "Stop"

	if ($startingdir -match '[\*\"\?\<\>\|]'){
		throw "Invalid starting directory! $startingdir may not contain characters: : * ? < > | "
	}elseif(!$(Test-Path $startingdir -PathType Container)) {
		throw "Invalid starting directory! $startingdir must be an existing folder. "
	}elseif(($mode -gt 2) -or ($mode -lt 0)) { 
		throw "Invalid mode! Use integer values from 0 to 2."
	}elseif ( ($dupdir -match '[\/\\\:\*\"\?\<\>\|]') -and ($mode -eq 2) ){
		throw "Invalid duplicates directory! $dupdir may not contain characters: / \ : * ? < > | "
	}elseif(($mode_output_cli -gt 1) -or ($mode_output_cli -lt 0)) { 
		throw "Invalid console output mode! Use integer values from 0 to 1."
	}elseif($output_cli_file -match '[\/\\\:\*\"\?\<\>\|]') { 
		throw "Invalid output file name of console session! May not contain characters: / \ : * ? < > | "
	}elseif(($mode_output_duplicates -gt 1) -or ($mode_output_duplicates -lt 0)) { 
		throw "Invalid duplicates output mode! Use integer values from 0 to 1."
	}elseif($output_dup_file -match '[\/\\\:\*\"\?\<\>\|]') { 
		throw "Invalid output file name of duplicates! May not contain characters: / \ : * ? < > | "
	}elseif(($debug -gt 1) -or ($debug -lt 0)) { 
		throw "Invalid debug mode! Use integer values from 0 to 1."
	}

	# Get script directory, set as cd
	Write-Host "Script directory: $PSScriptRoot" -ForegroundColor Green

	# Check for write permissions in script directory
	if ($mode_output_cli -eq 1) {
		# check for write permissions 
		Try { [io.file]::OpenWrite($output_cli_file).close() }
		Catch { Write-Warning "Script directory has to be writeable to output the cli session!" }
	}

	# Begin output of cli 
	if($mode_output_cli -eq 1) {
		Start-Transcript -path (Join-Path $PSScriptRoot $output_cli_file) -append
	}

	$output_csv = ''
	& { Get-Item $startingdir; Get-ChildItem -Directory -Path $startingdir -Recurse -Exclude $dupdir } | ForEach-Object {
		$container = $_
		$cd = $_.FullName # Current directory's full path
		Write-Host "`n********************************************************************************`nFolder: $cd" -ForegroundColor Cyan
		
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
			if($d) { Write-Host "Total files count: $f, Original files count: $($f-$d), Duplicate files count: $d" -ForegroundColor Green }

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
			}elseif($mode -eq 1 -or $mode -eq 2) {
				if ($mode -eq 1) {
					Write-Host "Mode: $mode - Deleting duplicate files to recycle bin, keeping original file(shortest name among them) ..." -ForegroundColor Cyan
				}elseif ($mode -eq 2) {
					if ($env:OS -notmatch 'Windows_NT') {
						Write-Warning "The operation is not supported on non-Windows systems."
						return
					}
				}
				Write-Host "`tdup file`t`t`t`t`toriginal file`n`t----------`t`t`t`t`t--------------"

				
				$hashes_duplicates.GetEnumerator() | ForEach-Object {
					$duplicates = $_.Value
					$duplicates[1..$($duplicates.Count)] | ForEach-Object {
						$duplicateFile = $_
						$originalFile = $duplicates[0]

						Write-Host "`tDeleting:`t$($duplicateFile.FullName)`t`t`t`t`tOriginal:`t$($originalFile.FullName)"
						if ($mode -eq 1) {
							# Delete to recycle bin

							# This method does not prompt the user 
							Add-Type -AssemblyName Microsoft.VisualBasic
							[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($duplicateFile.FullName,'OnlyErrorDialogs','SendToRecycleBin')

							# No longer using this method because each delete will prompt the user.
							#$shell = New-Object -comobject "Shell.Application"
							#$item = $shell.Namespace(0).ParseName($duplicateFile.FullName)
							#$item.InvokeVerb("delete")
						}elseif ($mode -eq 2) {
							# Permanently delete
							try {
								Remove-item $duplicateFile.FullName -Force -ErrorAction Stop
							}catch {
								Write-Warning "Could not delete $($duplicateFile.FullName). Reason $($_.Exception.Message)"
							}
						}
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
						Move-Item $duplicateFile.FullName $destination
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
			$output_csv | Out-File (Join-Path $PSScriptRoot $output_dup_file) -Encoding utf8
		}
	}

	# Stop transcript
	if($mode_output_cli -eq 1) {
		Stop-Transcript
	}
}catch {
	Write-Warning "Stopped due to an error. Reason: $($_.Exception.Message)"

}
