function Handle-DuplicateItem {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [hashtable]$SearchObject
    ,
        [ValidateNotNullOrEmpty()]
        [int]$Mode
    ,
        [ValidateNotNullOrEmpty()]
        [string]$DuplicateTempDirectoryName
    ,
        [ValidateNotNullOrEmpty()]
        [int]$DebugFlag
    )

    # Perform an action on the duplicates: List; Delete to Recycle Bin (Windows only); Delete Permanently; Move to a specified directory
    if ($SearchObject['resultsCount'] -eq 0) {
        Write-Host "No duplicates were found." -ForegroundColor Green
        return
    }

    $scopeDir = $SearchObject['startingDir']

    $SearchObject['results'].GetEnumerator() | ForEach-Object {
        $result = $_.Value

        if ($SearchObject['scope'] -match 'WithinFolder') {
            $scopeDir = $result['originalItem'].Directory.FullName
            Write-Host "[$scopeDir]" -ForegroundColor Cyan
        }

        # No duplicates!
        if ($result['duplicateItems'].Count -eq 0) {
            Write-Host "No duplicates in: $scopeDir" -ForegroundColor Green
            return
        }

        # Show summary of duplicates
        Write-Host "Files: $( $result['duplicateItems'].Count + 1 ), Original file: 1, Duplicate files: $( $result['duplicateItems'].Count )" -ForegroundColor Green

        # Do the Task based on mode
        switch ($Mode) {
            0 {
                Write-Host "Mode: $Mode - Listing duplicate files, and their original file ..." -ForegroundColor Green
                Write-Host "dup file`toriginal file"
                Write-Host "--------`t--------------"

                # List duplicates
                $result['duplicateItems'] | ForEach-Object {
                   $duplicateItem = $_
                   Write-Host "$($duplicateItem.FullName)`t$($originalItem.FullName)"
                }
            }
            { $_ -eq 1 -or $_ -eq 2 } {
                if ($Mode -eq 1) {
                    Write-Host "Mode: $Mode - Deleting duplicate files permanently, keeping original file ..." -ForegroundColor Green
                }
                if ($Mode -eq 2) {
                    Write-Host "Mode: $Mode - Deleting duplicate files to recycle bin, keeping original file ..." -ForegroundColor Green
                    if ($env:OS -ne 'Windows_NT') {
                        Write-Warning "The operation is not supported on non-Windows systems."
                        return
                    }
                }
                Write-Host "dup file`toriginal file"
                Write-Host "--------`t--------------"

                $result['duplicateItems'] | ForEach-Object {
                    $duplicateItem = $_
                    Write-Host "Deleting: $( $duplicateItem.FullName )`tOriginal: $( $originalItem.FullName )"
                    if (!$DebugFlag) {
                        if ($Mode -eq 1) {
                            # Permanently delete
                            try {
                                $duplicateItem | Remove-item -Force -ErrorAction Stop
                            }catch {
                                throw "Could not delete $( $duplicateItem.FullName ). Reason $( $_.Exception.Message )"
                            }
                        }
                        if ($Mode -eq 2) {
                            # Delete to recycle bin

                            # This method does not prompt the user
                            Add-Type -AssemblyName Microsoft.VisualBasic
                            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($duplicateItem.FullName,'OnlyErrorDialogs','SendToRecycleBin')

                            # No longer using this method because each delete will prompt the user.
                            #$shell = New-Object -comobject "Shell.Application"
                            #$item = $shell.Namespace(0).ParseName($duplicateItem.FullName)
                            #$item.InvokeVerb("delete")
                        }
                    }
                }
                Write-Host "Deleting duplicates successful. Original files are left intact." -ForegroundColor Green
            }
            3 {
                Write-Host "Mode: $Mode - Moving duplicate files to $DuplicateTempDirectoryName, leaving intact original file..." -ForegroundColor Green
                $result['duplicateItems'] | ForEach-Object {
                    $duplicateItem = $_

                    # Move to a dup directory
                    $destinationDir = Join-Path $scopeDir $DuplicateTempDirectoryName
                    $destination = Join-Path $destinationDir $duplicateItem.Name
                    Write-Host "Moving dup file from $($duplicateItem.FullName) to $destination"

                    if (!$DebugFlag) {
                        # Create dup directory if not existing
                        if ( ! (Test-Path $destinationDir -PathType Container) ) {
                            New-Item -ItemType Directory -Force -Path $destinationDir > $null
                        }
                        Move-Item $duplicateItem.FullName $destination -Force
                    }
                }
            }
            default {}
        }
    }
}
