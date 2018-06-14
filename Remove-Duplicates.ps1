############### configure script settings ##########
# Absolute path to directory where duplicates might exist. May contain trailing slash. Folders paths only.
$startingDir = "D:\duplicatesfolder"

# Scope: scope to search for duplicates
# May be 'withinFolder' or 'acrossFolder'
# 'withinFolder' - duplicates will be located among all files found within each folder node starting from $startingDir
# 'acrossFolder' - 'acrossFolder', duplicates will be located among all files found across all folder nodes starting from $startingDir
$scope = 'withinFolder'

# Mode: action to take for duplicates found
# 0 - List only.
# 1 - Delete permanently.
# 2 - Delete to recycle bin (Only on Windows systems).
# 3 - Move to $dupdir that will be created.  
# Default: 0
$mode = 0

# The name of the directory name where duplicates will be moved. Cannot contain the following characters:/ \ : * ? < > |
# If $scope is 1 (acrossFolder), this directory will be created in the $startingDir directory
# If $scope is 0 (withinFolder), this directory will be created each searched child directory
# NOTE: Applies only to mode 2. Edit between the quotes
# Default: "!dup"
$dupdir = "!dup" 

# Whether to output a transcript of the console output
# 0 - Off
# 1 - On
# Default: 1
$mode_output_cli = 0

# File name of the console transcript. File will be created in same directory as powershell script.
# NOTE: Edit between the quotes. May not contain characters: / \ : * ? < > |
# Default: "output.txt"
$output_cli_file = "output.txt"

# Whether to write the duplicates as .csv / .json file for review.
# 0 - Off
# 1 - On
# Default: 1
$mode_output_duplicates = 1

# File name of the duplicates export file. File will be created in same directory as powershell script.
# If the file extension is '.json', export will be in JSON format.
# If the file extension is '.csv', export will be in CSV format.
# NOTE: Edit between the quotes. May not contain characters: / \ : * ? < > |
# Default: "duplicates.csv"
$output_dup_file = "duplicates.csv"

# Debug mode
# 0 - Off
# 1 - On
# Default: 0
$debug = 0
############################################################# 

$devFile = Join-Path (Join-Path $PSScriptRoot 'tests') 'config.ps1'
if ( Test-Path $devFile ) {
	. $devFile
}

if ($startingDir -match '[\*\"\?\<\>\|]'){
	throw "Invalid starting directory! $startingDir may not contain characters: : * ? < > | "
}elseif (! $(Test-Path $startingDir -PathType Container) ) {
	throw "Invalid starting directory! $startingDir must be an existing folder. "
}elseif (! (($scope -eq 'withinFolder') -or ($scope -eq 'acrossFolder')) ) { 
	throw "Invalid scope $scope! Use 'withinFolder' or 'acrossFolder'."
}elseif ( ($mode -gt 3) -or ($mode -lt 0) ) { 
	throw "Invalid mode! Use integer values from 0 to 2."
}elseif ( ($dupdir -match '[\/\\\:\*\"\?\<\>\|]') -and ($mode -eq 2) ){
	throw "Invalid duplicates directory! $dupdir may not contain characters: / \ : * ? < > | "
}elseif ( ($mode_output_cli -gt 1) -or ($mode_output_cli -lt 0) ) { 
	throw "Invalid console output mode! Use integer values from 0 to 1."
}elseif ($output_cli_file -match '[\/\\\:\*\"\?\<\>\|]') { 
	throw "Invalid output file name of console session! May not contain characters: / \ : * ? < > | "
}elseif ( ($mode_output_duplicates -gt 1) -or ($mode_output_duplicates -lt 0) ) { 
	throw "Invalid duplicates output mode! Use integer values from 0 to 1."
}elseif ($output_dup_file -match '[\/\\\:\*\"\?\<\>\|]') { 
	throw "Invalid output file name of duplicates! May not contain characters: / \ : * ? < > | "
}elseif ( ($debug -gt 1) -or ($debug -lt 0) ) { 
	throw "Invalid debug mode! Use integer values from 0 to 1."
}

# Get script directory, set as cd
Write-Host "Script directory: $PSScriptRoot" -ForegroundColor Green

# Check for write permissions in script directory
if ($mode_output_cli -eq 1) {
	# check for write permissions 
	Try { [io.file]::OpenWrite((Join-Path $PSScriptRoot $output_cli_file)).close() }
	Catch { Write-Warning "Script directory has to be writeable to output the cli session!" }
}

# Begin output of cli 
if($mode_output_cli -eq 1) {
	Start-Transcript -path (Join-Path $PSScriptRoot $output_cli_file) -append
}

# Import Module
try {
	Import-Module 'Get-Duplicates' -ErrorAction Stop 3>$null
}catch {
	$module = Import-Module (Join-Path $PSScriptRoot './Modules/Get-Duplicates/Get-Duplicates.psm1' ) -Force -PassThru -ErrorAction SilentlyContinue 3>$null
	if (!$module) {
		Write-Warning "Could not import Get-Duplicates module. Exiting"
		return
	}
}

# Check parameters' argument validity
try {
    # Instantiate the SearchObject
    $searchObj = @{
        startingDir = $startingDir
        scope = $scope
        results = @{}
        results_count = 0
        duplicate_files_count = 0
	}

	& { if ($scope -match 'WithinFolder') {
			Get-Item $startingDir; Get-ChildItem -Folder -Path $startingDir -Exclude $dupdir
		}else {
			Get-Item $startingDir
			Write-Host "The AcrossFolder search scope might take a while ... Please be patient" -ForegroundColor Yellow		
		}
	} | ForEach-Object {
		$container = $_

		$params = @{
			Path = $container.FullName
			Recurse = if ($scope -match 'AcrossFolder') { $true } else { $false }
			AsHashtable = $true
			ExcludeDirectory = $dupdir
		}
		$hashes_duplicates = Get-Duplicates @params
		
		# Populate the SearchObject, Collect basic content for the csv
		$hashes_duplicates.GetEnumerator() | ForEach-Object {
			$md5 = $_.Key
			$duplicates = $_.Value
			$originalFile = $duplicates[0]
			$duplicateFiles = $duplicates[1..$($duplicates.Count - 1)]

			# Populate the SearchObject
			$searchObj['results'][$originalFile.FullName] = @{
				md5 = $md5
				originalFile = $originalFile
				duplicateFiles  = $duplicateFiles
			}
		}
	}
	# Populate the SearchObject
	$searchObj['results_count'] = $searchObj['results'].Keys.Count
	$searchObj['results'].GetEnumerator() | ForEach-Object { 
		$searchObj['duplicate_files_count'] += $_.Value['duplicateFiles'].Count 
	}

	# Perform an action on the duplicates: List; Delete to Recycle Bin (Windows only); Delete Permanently; Move to a specified directory
	if ($searchObj['results_count'] -eq 0) {
		Write-Host "No duplicates were found." -ForegroundColor Green
	}else {
		$scope = $searchObj['scope']
		$results = $searchObj['results']
		$scopeDir = $searchObj['startingDir']

		$results.GetEnumerator() | ForEach-Object {
			if ($scope -match 'WithinFolder') {
				$scopeDir = $originalFile.Directory.FullName
			}
			Write-Host "`n********************************************************************************`nFolder: $scopeDir" -ForegroundColor Cyan		
	
			$result = $_.Value
			$md5 = $result['md5']
			$originalFile = $result['originalFile']
			$duplicateFiles = $result['duplicateFiles']

			# Duplicates count
			$d = $duplicateFiles.Count

			# Tell user no dups found in this folder 
			if($d -eq 0) { 
				Write-Host "`tNo duplicates in: $scopeDir" -ForegroundColor Green 
			}else {
				# Show summary only if dups exist
				if($d) { Write-Host "Total files count: $($d + 1), Original files count: 1, Duplicate files count: $d" -ForegroundColor Green }

				# Do the Task based on mode
				if($mode -eq 0) {
					Write-Host "Mode: $mode - Listing duplicate files, and their original file ..." -ForegroundColor Green
					Write-Host "`tdup file`t`t`t`t`toriginal file`n`t----------`t`t`t`t`t--------------"

					# List duplicates
					$duplicateFiles | ForEach-Object {
						$duplicateFile = $_
						Write-Host "`t$($duplicateFile.FullName)`t`t`t`t`t$($originalFile.FullName)"  
					}
				}elseif($mode -eq 1 -or $mode -eq 2) {
					if ($mode -eq 1) {
						Write-Host "Mode: $mode - Deleting duplicate files to recycle bin, keeping original file ..." -ForegroundColor Green
					}elseif ($mode -eq 2) {
						Write-Host "Mode: $mode - Deleting duplicate files permanently, keeping original file ..." -ForegroundColor Green
						if ($env:OS -notmatch 'Windows_NT') {
							Write-Warning "The operation is not supported on non-Windows systems."
							return
						}
					}
					Write-Host "`tdup file`t`t`t`t`toriginal file`n`t----------`t`t`t`t`t--------------"

					$duplicateFiles | ForEach-Object {
						$duplicateFile = $_
						Write-Host "`tDeleting:`t$($duplicateFile.FullName)`t`t`t`t`tOriginal:`t$($originalFile.FullName)"
						if (!$debug) {
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
									if ($debug) {
										Remove-item $duplicateFile.FullName -Force -ErrorAction Stop
									}
								}catch {
									Write-Warning "Could not delete $($duplicateFile.FullName). Reason $($_.Exception.Message)"
								}
							}
						}
					}
					Write-Host "Deleting duplicates successful. Original files are left intact." -ForegroundColor Green
				}elseif($mode -eq 3) {
					Write-Host "Mode: $mode - Moving duplicate files to $dupdir, leaving intact original file..." -ForegroundColor Green 
					$duplicateFiles | ForEach-Object {
						$duplicateFile = $_
							
						# Move to a dup directory
						$destinationDir = Join-Path $scopeDir $dupdir
						$destination = Join-Path $destinationDir $duplicateFile.Name
						Write-Host "`tMoving dup file from $($duplicateFile.FullName) to $destination" -ForegroundColor Green
						
						if (!$debug) {
							# Create dup directory if not existing
							if(!$(Test-Path $destinationDir -PathType Container)) {
								New-Item -ItemType Directory -Force -Path $destinationDir > $null
							}
							Move-Item $duplicateFile.FullName $destination
						}
					}
				}
			}
		}
	}

	# Export duplicates .json or .csv
	if ($mode_output_duplicates -eq 1) {
		$results = $searchObj['results']

		$exportFilePath = Join-Path $PSScriptRoot $output_dup_file
		Write-Host "Exporting duplicates file to $exportFilePath" -ForegroundColor Cyan

		if ($output_dup_file.Trim() -match '\.json$') {
			# JSON export
			$results | ConvertTo-Json -Depth 2 | Out-File $exportFilePath -Encoding utf8
		}else {
			# CSV export
			$output_csv = ''
			$results.GetEnumerator() | ForEach-Object {
				$result = $_.Value
				$md5 = $result['md5']
				$originalFile = $result['originalFile']
				$duplicateFiles = $result['duplicateFiles']
				
				$duplicateFiles | ForEach-Object {
					$duplicateFile = $_
					
					$duplicateFile_size_in_kB = "$($duplicateFile.Length/1000) kB"
					$originalFile_size_in_kB = "$($originalFile.Length/1000) kB"

					$output_csv += "`n`"$($duplicateFile.Directory.FullName)`",`"$($duplicateFile.FullName)`",`"$duplicateFile_size_in_kB`",`"$md5`",`"$($originalFile.Directory.FullName)`",`"$($originalFile.FullName)`",`"$originalFile_size_in_kB`",`"$md5`""
				}
			}
			$output_csv = '"Duplicate File Directory","Duplicate File","Duplicate File Size","Duplicate File Hash","Original File Directory","Original File","Original File Size","Original File Hash"' + $output_csv
			$output_csv | Out-File $exportFilePath -Encoding utf8
		}
	}

	# Stop transcript
	if($mode_output_cli -eq 1) {
		Stop-Transcript
	}
}catch {
	Write-Warning "Stopped due to an error. Reason: $($_.Exception.Message)"
	throw
}