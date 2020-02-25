$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Export-DuplicateItem" {
    $workDir = "TestDrive:\work"

    $parentDir = "$workDir\parent"
    $itemPath =  "$parentDir\file1"
    $item = New-Item -Path $itemPath -ItemType File -Force
    $duplicateItemPath =  "$parentDir\file2"
    $duplicateItem = New-Item -Path $duplicateItemPath -ItemType File -Force

    $searchObject = @{
        startingDir = $parentDir
        scope = 'withinFolder'
        results = @{
            $item.FullName = @{
                md5 = 'xxxxxxx'
                originalItem = $item
                duplicateItems = @(
                    $duplicateItem
                )
            }
        }
        resultsCount = 0
        duplicateItemsCount = 0
    }

    Context 'Export to file' {

        It 'Exports duplicates to a .json file in the current directory' {
            $exportDuplicatesFileName = 'foo.json'

            Push-Location $workDir
            Export-DuplicateItem -SearchObject $searchObject -ExportFilePath $exportDuplicatesFileName
            Pop-Location

            $result = Get-Item (Join-Path $workDir $exportDuplicatesFileName)
            $result.Name | Should -Be $exportDuplicatesFileName
        }

        It 'Exports duplicates to a .csv file in the current directory' {
            $exportDuplicatesFileName = 'foo.csv'

            Push-Location $workDir
            Export-DuplicateItem -SearchObject $searchObject -ExportFilePath $exportDuplicatesFileName
            Pop-Location

            $result = Get-Item (Join-Path $workDir $exportDuplicatesFileName)
            $result.Name | Should -Be $exportDuplicatesFileName
        }

    }
}
