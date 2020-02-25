$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Export-DuplicateItem" {
    $workDir = "TestDrive:\work"

    $parentDir = "$workDir\parent"
    $childDir = "$parentDir\child"

    $itemPath = "$parentDir\file1"
    $duplicateItemPaths = @(
        "$parentDir\file2"
    )
    $childItemPath = "$childDir\file1"
    $duplicateChildItemPath = @(
        "$childDir\file2"
    )

    Context 'Handles duplicates' {

        It 'Lists duplicate items' {
            New-Item $parentDir -ItemType Directory -Force > $null
            New-Item $childDir -ItemType Directory -Force > $null
            $itemPath, $duplicateItemPaths, $childItemPath, $duplicateChildItemPath | % {
                'foo'           | Out-File -Path "$_"  -Encoding utf8 -Force
            }

            $originalItem = Get-Item $itemPath
            $childOriginalItem = Get-Item $childItemPath

            $searchObject = @{
                startingDir = $parentDir
                scope = 'withinFolder'
                results = @{
                    ($originalItem.FullName) = @{
                        md5 = 'xxxxxxx'
                        originalItem = $originalItem
                        duplicateItems = @(
                            $duplicateItemPaths | Get-Item
                        )
                    }
                    ($childOriginalItem.FullName) = @{
                        md5 = 'xxxxxxx'
                        originalItem = $childOriginalItem
                        duplicateItems = @(
                            $duplicateChildItemPath | Get-Item
                        )
                    }
                }
                resultsCount = 2
                duplicateItemsCount = 2
            }

            Push-Location $parentDir
            Handle-DuplicateItem -SearchObject $searchObject
            Pop-Location

            $result = Get-Item -Path $parentDir/file*
            $result.Count | Should -Be 2

            $result = Get-Item -Path $childDir/file*
            $result.Count | Should -Be 2
        }

        It 'Deletes duplicate items permanently (withinFolder)' {
            New-Item $parentDir -ItemType Directory -Force > $null
            New-Item $childDir -ItemType Directory -Force > $null
            $itemPath, $duplicateItemPaths, $childItemPath, $duplicateChildItemPath | % {
                'foo'           | Out-File -Path "$_"  -Encoding utf8 -Force
            }

            $originalItem = Get-Item $itemPath
            $childOriginalItem = Get-Item $childItemPath

            $searchObject = @{
                startingDir = $parentDir
                scope = 'withinFolder'
                results = @{
                    ($originalItem.FullName) = @{
                        md5 = 'xxxxxxx'
                        originalItem = $originalItem
                        duplicateItems = @(
                            $duplicateItemPaths | Get-Item
                        )
                    }
                    ($childOriginalItem.FullName) = @{
                        md5 = 'xxxxxxx'
                        originalItem = $childOriginalItem
                        duplicateItems = @(
                            $duplicateChildItemPath | Get-Item
                        )
                    }
                }
                resultsCount = 2
                duplicateItemsCount = 2
            }
            $mode = 1

            Push-Location $parentDir
            Handle-DuplicateItem -SearchObject $searchObject -Mode $mode
            Pop-Location

            $result = Get-Item -Path $parentDir/file*
            $result.Count | Should -Be 1

            $result = Get-Item -Path $childDir/file*
            $result.Count | Should -Be 1
        }
        It 'Deletes duplicate items permanently (acrossFolder)' {
            New-Item $parentDir -ItemType Directory -Force > $null
            New-Item $childDir -ItemType Directory -Force > $null
            $itemPath, $duplicateItemPaths, $childItemPath, $duplicateChildItemPath | % {
                'foo'           | Out-File -Path "$_"  -Encoding utf8 -Force
            }

            $originalItem = Get-Item $itemPath
            $childOriginalItem = Get-Item $childItemPath

            $searchObject = @{
                startingDir = $parentDir
                scope = 'acrossFolder'
                results = @{
                    ($originalItem.FullName) = @{
                        md5 = 'xxxxxxx'
                        originalItem = $originalItem
                        duplicateItems = @(
                            $childOriginalItem
                            $duplicateItemPaths | Get-Item
                            $duplicateChildItemPath | Get-Item
                        )
                    }
                }
                resultsCount = 1
                duplicateItemsCount = 3
            }
            $mode = 1

            Push-Location $parentDir
            Handle-DuplicateItem -SearchObject $searchObject -Mode $mode
            Pop-Location

            $result = Get-Item -Path $parentDir/file*
            $result.Count | Should -Be 1

            $result = Get-Item -Path $childDir/file*
            $result.Count | Should -Be 0
        }

        It 'Does not delete duplicate items permanently when in debug mode (acrossFolder)' {
            New-Item $parentDir -ItemType Directory -Force > $null
            New-Item $childDir -ItemType Directory -Force > $null
            $itemPath, $duplicateItemPaths, $childItemPath, $duplicateChildItemPath | % {
                'foo'           | Out-File -Path "$_"  -Encoding utf8 -Force
            }

            $originalItem = Get-Item $itemPath
            $childOriginalItem = Get-Item $childItemPath

            $searchObject = @{
                startingDir = $parentDir
                scope = 'acrossFolder'
                results = @{
                    ($originalItem.FullName) = @{
                        md5 = 'xxxxxxx'
                        originalItem = $originalItem
                        duplicateItems = @(
                            $childOriginalItem
                            $duplicateItemPaths | Get-Item
                            $duplicateChildItemPath | Get-Item
                        )
                    }
                }
                resultsCount = 1
                duplicateItemsCount = 3
            }
            $mode = 1
            $debugFlag = 1

            Push-Location $parentDir
            Handle-DuplicateItem -SearchObject $searchObject -Mode $mode -DebugFlag $debugFlag
            Pop-Location

            $result = Get-Item -Path $parentDir/file*
            $result.Count | Should -Be 2

            $result = Get-Item -Path $childDir/file*
            $result.Count | Should -Be 2
        }
    }

    It 'Moves duplicate items to a temporary location (acrossFolder)' {
        New-Item $parentDir -ItemType Directory -Force > $null
        New-Item $childDir -ItemType Directory -Force > $null
        $itemPath, $duplicateItemPaths, $childItemPath, $duplicateChildItemPath | % {
            'foo'           | Out-File -Path "$_"  -Encoding utf8 -Force
        }

        $originalItem = Get-Item $itemPath
        $childOriginalItem = Get-Item $childItemPath

        $searchObject = @{
            startingDir = $parentDir
            scope = 'acrossFolder'
            results = @{
                ($originalItem.FullName) = @{
                    md5 = 'xxxxxxx'
                    originalItem = $originalItem
                    duplicateItems = @(
                        $childOriginalItem
                        $duplicateItemPaths | Get-Item
                        $duplicateChildItemPath | Get-Item
                    )
                }
            }
            resultsCount = 1
            duplicateItemsCount = 2
        }
        $mode = 3
        $duplicateTempDirectoryName = '.tmp'

        Push-Location $parentDir
        Handle-DuplicateItem -SearchObject $searchObject -Mode $mode -DuplicateTempDirectoryName $duplicateTempDirectoryName
        Pop-Location

        $result = Get-Item -Path $parentDir/$duplicateTempDirectoryName/file*
        $result.Count | Should -Be 2

        Remove-Item -Path $parentDir/$duplicateTempDirectoryName -Force -Recurse
    }

    It 'Moves duplicate items to a temporary location (withinFolder)' {
        New-Item $parentDir -ItemType Directory -Force > $null
        New-Item $childDir -ItemType Directory -Force > $null
        $itemPath, $duplicateItemPaths, $childItemPath, $duplicateChildItemPath | % {
            'foo'           | Out-File -Path "$_"  -Encoding utf8 -Force
        }

        $originalItem = Get-Item $itemPath
        $childOriginalItem = Get-Item $childItemPath

        $searchObject = @{
            startingDir = $parentDir
            scope = 'withinFolder'
            results = @{
                ($originalItem.FullName) = @{
                    md5 = 'xxxxxxx'
                    originalItem = $originalItem
                    duplicateItems = @(
                        $duplicateItemPaths | Get-Item
                    )
                }
                ($childOriginalItem.FullName) = @{
                    md5 = 'xxxxxxx'
                    originalItem = $childOriginalItem
                    duplicateItems = @(
                        $duplicateChildItemPath | Get-Item
                    )
                }
            }
            resultsCount = 2
            duplicateItemsCount = 2
        }
        $mode = 3
        $duplicateTempDirectoryName = '.tmp'

        Push-Location $parentDir
        Handle-DuplicateItem -SearchObject $searchObject -Mode $mode -DuplicateTempDirectoryName $duplicateTempDirectoryName
        Pop-Location

        $result = Get-Item -Path $parentDir/$duplicateTempDirectoryName/file*
        $result.Count | Should -Be 1

        $result = Get-Item -Path $childDir/$duplicateTempDirectoryName/file*
        $result.Count | Should -Be 1
    }

}
