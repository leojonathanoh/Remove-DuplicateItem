function Remove-DuplicateItem {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER Path
    Absolute path to directory where duplicates might exist. Folders paths only.
    Default: Current directory

    .PARAMETER Scope
    Scope to search for duplicates
    May be 'withinFolder' or 'acrossFolder'
    'withinFolder' - duplicates will be located among all files found within each folder node starting from $Path
    'acrossFolder' - 'acrossFolder', duplicates will be located among all files found across all folder nodes starting from $Path
    Default: withinFolder

    .PARAMETER Mode
    Mode: action to take for duplicates found
    0 - List only.
    1 - Delete permanently.
    2 - Delete to recycle bin (Only on Windows systems).
    3 - Move to $DuplicateTempDirectoryName that will be created.
    Default: 0

    .PARAMETER DuplicateTempDirectoryName
    Name of the directory where duplicates will be moved. Cannot contain the following characters: / \ : * ? < > |
    NOTE: Applies only to mode 2.
    If $scope is 'withinFolder', the specified directory will be created each searched child directory
    If $scope 'acrossFolder'', the specified directory will be created in the $Path directory
    Default: "!dup"

    .PARAMETER ExportDuplicates
    Whether to write the duplicates as .csv / .json file for review.
    0 - Off
    1 - On
    Default: 1

    .PARAMETER ExportDuplicatesFileName
    File name of the duplicates export file. File will be created in current directory. Cannot contain the following characters: / \ : * ? < > |
    If the file extension is '.json', export will be in JSON format.
    If the file extension is '.csv', export will be in CSV format.
    Default: "duplicates.csv"

    .PARAMETER ExportTranscript
    Whether to output a transcript of the console output
    0 - Off
    1 - On
    Default: 1

    .PARAMETER ExportTranscriptFileName
    File name of the console transcript. File will be created in current directory.  File will be created in current directory. Cannot contain the following characters: / \ : * ? < > |
    Default: "transcript.log"

    .PARAMETER DebugFlag
    Debug mode
    In debug mode, regardless of $mode specified, no files will be deleted or moved.
    0 - Off
    1 - On
    Default: 0

    .EXAMPLE
    Remove-Duplicates -Path R:/1 -Scope 'withinFolder' -Mode 0
    Remove-Duplicates -Path R:/1 -Scope 'withinFolder' -Mode 1

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
            [ValidateNotNullOrEmpty()]
            [string]$Path
        ,
            [ValidateNotNullOrEmpty()]
            [ValidateSet('withinFolder', 'acrossFolder')]
            [string]$Scope
        ,
            [ValidateNotNullOrEmpty()]
            [ValidateRange(0,3)]
            [int]$Mode
        ,
            [ValidateScript({
                if ( $_ -match '[\/\\\:\*\"\?\<\>\|]' ) {
                    return $false
                }
                $true
            })]
            [string]$DuplicateTempDirectoryName
        ,
            [ValidateNotNullOrEmpty()]
            [ValidateRange(0,1)]
            [int]$ExportDuplicates
        ,
            [ValidateScript({
                if ( $_ -match '[\/\\\:\*\"\?\<\>\|]' ) {
                    return $false
                }
                if ( $_ -notmatch '.csv$|.json$' ) {
                    return $false
                }
                $true
            })]
            [string]$ExportDuplicatesFileName
        ,
            [ValidateNotNullOrEmpty()]
            [ValidateRange(0,1)]
            [int]$ExportTranscript
        ,
            [ValidateScript({
                if ( $_ -match '[\/\\\:\*\"\?\<\>\|]' ) {
                    return $false
                }
                $true
            })]
            [string]$ExportTranscriptFileName
        ,
            [ValidateNotNullOrEmpty()]
            [ValidateRange(0,1)]
            [int]$DebugFlag
    )

    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        # Validation
        $Path = if ($Path) { $Path } else { $pwd }
        $Scope = if ($Scope) { $Scope } else { 'withinFolder' }
        if ($Mode -eq 2 -and $env:OS -ne 'Windows_NT') {
            throw 'Mode 2 (Deleting to recycle bin) is only supported on Windows OS'
        }
        $DuplicateTempDirectoryName = if ($DuplicateTempDirectoryName) { $DuplicateTempDirectoryName } else { '!dup' }
        $ExportDuplicates = if ($ExportDuplicates) { $ExportDuplicates } else { 1 }
        $ExportDuplicatesFileName = if ($ExportDuplicatesFileName) { $ExportDuplicatesFileName } else { 'duplicates.csv' }
        $ExportTranscript = if ($ExportTranscript) { $ExportTranscript } else { 0 }
        $ExportTranscriptFileName = if ($ExportTranscriptFileName) { $ExportTranscriptFileName } else { 'transcript.log' }
        $DebugFlag = if ($DebugFlag) { $DebugFlag } else { 0 }
    }
    process {
        try {
            # Begin output transcript
            if ($ExportTranscript -eq 1) {
                # Check for write permissions in script directory
                # try {
                #     [io.file]::OpenWrite((Join-Path $Path $ExportTranscriptFileName)).close()
                # }catch {
                #     throw "Script directory has to be writeable to output the cli session!"
                # }

                Start-Transcript -path (Join-Path $Path $ExportTranscriptFileName) -append
            }

            # Import Get-DuplicateItem Module
            try {
                Import-Module 'Get-DuplicateItem' -ErrorAction Stop 3>$null
            }catch {
                throw "Could not import Get-DuplicateItem module"
            }

            # Instantiate the SearchObject
            $searchObj = New-SearchObject -StartingDir $Path

            # Search for duplicates and populate the SearchObject
            & { if ($scope -match 'WithinFolder') {
                    Get-Item $Path -ErrorAction Stop; Get-ChildItem -Directory -Path $Path -Exclude $DuplicateTempDirectoryName -Recurse
                }else {
                    Get-Item $Path
                    Write-Host "The AcrossFolder search scope might take a while ... Please be patient" -ForegroundColor Yellow
                }
            } | ForEach-Object {
                $container = $_

                $params = @{
                    Path = $container.FullName
                    Recurse = if ($scope -eq 'acrossFolder') { $true } else { $false }
                    AsHashtable = $true
                    ExcludeDirectory = $DuplicateTempDirectoryName
                }
                $results = Get-DuplicateItem @params

                $results.GetEnumerator() | ForEach-Object {
                    $md5 = $_.Key
                    $duplicateItems = $_.Value
                    $originalItem = $duplicateItems[0]
                    $searchObj['results'][$originalItem.FullName] = @{
                        md5 = $md5
                        originalItem = $originalItem
                        duplicateItems  = @(
                            $duplicateItems[1..$( $duplicateItems.Count - 1 )]
                        )
                    }
                }
            }
            $searchObj['resultsCount'] = $searchObj['results'].Keys.Count
            $searchObj['results'].GetEnumerator() | ForEach-Object {
                $searchObj['duplicateItemsCount'] += $_.Value['duplicateItems'].Count
            }

            # Performs actions on duplicate items
            Handle-DuplicateItems -SearchObject $searchObj -Mode $Mode

            # Export duplicates .json or .csv
            if ($ExportDuplicates -eq 1) {
                $exportFilePath = Join-Path $PSScriptRoot $ExportDuplicatesFileName
                Export-DuplicateItems -SearchObject $searchObj -ExportFilePath $exportFilePath
            }

            # Stop transcript
            if ($ExportTranscript -eq 1) {
                Stop-Transcript
            }
        }catch {
            if ($callerEA -eq 'Stop') {
                throw
            }else {
                Write-Error "Stopped due to an error. Reason: $($_.Exception.Message)" -ErrorAction $callerEA
            }
        }
    }
}
