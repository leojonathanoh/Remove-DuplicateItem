function Export-DuplicateItem {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [hashtable]$SearchObject
    ,
        [ValidateNotNullOrEmpty()]
        [string]$ExportFilePath
    )

    Write-Host "Exporting duplicates file to $exportFilePath" -ForegroundColor Cyan

    if ($ExportDuplicatesFileName.Trim() -match '\.json$') {
        # JSON export
        $SearchObject['results'] | ConvertTo-Json -Depth 2 | Out-File $exportFilePath -Encoding utf8
    }else {
        # CSV export
        $csvContent = '"Duplicate File Directory","Duplicate File","Duplicate File Size","Duplicate File Hash","Original File Directory","Original File","Original File Size","Original File Hash"'
        $SearchObject['results'].GetEnumerator() | ForEach-Object {
            $result = $_.Value

            $result['duplicateItems'] | ForEach-Object {
                $duplicateItem = $_

                $duplicateItem_size_in_kB = "$( $duplicateItem.Length / 1000 ) kB"
                $originalFile_size_in_kB = "$( $result['originalItem'].Length / 1000 ) kB"

                $csvContent += "`n`"$( $duplicateItem.Directory.FullName )`",`"$($duplicateItem.FullName)`",`"$duplicateItem_size_in_kB`",`"$( $result['md5'] )`",`"$( $result['originalItem'].Directory.FullName )`",`"$( $result['originalItem'].FullName )`",`"$originalFile_size_in_kB`",`"$( $result['md5'] )`""
            }
        }
        $csvContent | Out-File $exportFilePath -Encoding utf8
    }
}
