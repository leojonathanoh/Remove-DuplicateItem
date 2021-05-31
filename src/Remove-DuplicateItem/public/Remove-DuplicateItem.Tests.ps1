$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Remove-DuplicateItem" -Tag 'Unit' {

    function Start-Transcript {}
    function Import-Module {}
    function New-SearchObject {
        [CmdletBinding()]
        [OutputType([hashtable])]
        param (
            [string]$StartingDir
        )

        @{
            startingDir = $StartingDir
            scope = $scope
            results = @{}
            resultsCount = 0
            duplicateItemsCount = 0
        }
    }
    function Get-DuplicateItem {
        @{}
    }
    function Handle-DuplicateItems {}
    function Export-DuplicateItems {}
    function Stop-Transcript {}

    Context 'Non-terminating errors' {

        It 'Shows error when Path does not exist' {
            $invalidPath =  "TestDrive:\foo"

            Remove-DuplicateItem -Path $invalidPath -ErrorVariable err -ErrorAction Continue 2>$null

            $err.Count | Should Not Be 0
        }

    }
    Context 'Terminating errors' {

        It 'Throws exception when Path does not exist' {
            $invalidPath =  "TestDrive:\foo"

            { Remove-DuplicateItem -Path $invalidPath -ErrorAction Stop } | Should -Throw
        }

        It 'Throws exception when Scope is invalid' {
            $invalidScope = 'foo'

            { Remove-DuplicateItem -Scope $invalidScope -ErrorAction Stop } | Should -Throw
        }

        It 'Throws exception when Mode is invalid' {
            $invalidMode1 = -1

            { Remove-DuplicateItem -Mode $invalidMode1 -ErrorAction Stop } | Should -Throw
        }
        It 'Throws exception when Mode is invalid' {
            $invalidMode2 = 4

            { Remove-DuplicateItem -Mode $invalidMode2 -ErrorAction Stop } | Should -Throw
        }

        It 'Throws exception when DuplicateTempDirectoryName is invalid' {
            $invalidDuplicateTempDirectory1 = 'foo/'
            $invalidDuplicateTempDirectory2 = 'foo\'
            $invalidDuplicateTempDirectory3 = 'foo:'
            $invalidDuplicateTempDirectory4 = 'foo?'
            $invalidDuplicateTempDirectory5 = 'foo<'
            $invalidDuplicateTempDirectory6 = 'foo>'
            $invalidDuplicateTempDirectory7 = 'foo|'

            { Remove-DuplicateItem -DuplicateTempDirectoryName $invalidDuplicateTempDirectory1 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -DuplicateTempDirectoryName $invalidDuplicateTempDirectory2 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -DuplicateTempDirectoryName $invalidDuplicateTempDirectory3 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -DuplicateTempDirectoryName $invalidDuplicateTempDirectory4 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -DuplicateTempDirectoryName $invalidDuplicateTempDirectory5 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -DuplicateTempDirectoryName $invalidDuplicateTempDirectory6 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -DuplicateTempDirectoryName $invalidDuplicateTempDirectory7 -ErrorAction Stop } | Should -Throw
        }

        It 'Throws exception when ExportDuplicates is invalid' {
            $invalidExportDuplicates = 0

            { Remove-DuplicateItem -ExportDuplicates:$invalidExportDuplicates -ErrorAction Stop } | Should -Throw
        }

        It 'Throws exception when ExportDuplicatesFileName is invalid' {
            $invalidExportDuplicatesFileName1 = 'foo/'
            $invalidExportDuplicatesFileName2 = 'foo\'
            $invalidExportDuplicatesFileName3 = 'foo:'
            $invalidExportDuplicatesFileName4 = 'foo?'
            $invalidExportDuplicatesFileName5 = 'foo<'
            $invalidExportDuplicatesFileName6 = 'foo>'
            $invalidExportDuplicatesFileName7 = 'foo|'
            $invalidExportDuplicatesFileNameWrongExtension = 'foo.bar'

            { Remove-DuplicateItem -ExportDuplicatesFileName $invalidExportDuplicatesFileName1 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -ExportDuplicatesFileName $invalidExportDuplicatesFileName2 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -ExportDuplicatesFileName $invalidExportDuplicatesFileName3 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -ExportDuplicatesFileName $invalidExportDuplicatesFileName4 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -ExportDuplicatesFileName $invalidExportDuplicatesFileName5 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -ExportDuplicatesFileName $invalidExportDuplicatesFileName6 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -ExportDuplicatesFileName $invalidExportDuplicatesFileName7 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -ExportDuplicatesFileName $invalidExportDuplicatesFileNameWrongExtension -ErrorAction Stop } | Should -Throw
        }

        It 'Throws exception when ExportTranscript is invalid' {
            $invalidExportTranscript = -1

            { Remove-DuplicateItem -ExportTranscript:$invalidExportTranscript -ErrorAction Stop } | Should -Throw
        }

        It 'Throws exception when ExportTranscriptFileNameName is invalid' {
            $invalidExportTranscriptFileName1 = 'foo/'
            $invalidExportTranscriptFileName2 = 'foo\'
            $invalidExportTranscriptFileName3 = 'foo:'
            $invalidExportTranscriptFileName4 = 'foo?'
            $invalidExportTranscriptFileName5 = 'foo<'
            $invalidExportTranscriptFileName6 = 'foo>'
            $invalidExportTranscriptFileName7 = 'foo|'

            { Remove-DuplicateItem -ExportTranscriptFileName $invalidExportTranscriptFileName1 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -ExportTranscriptFileName $invalidExportTranscriptFileName2 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -ExportTranscriptFileName $invalidExportTranscriptFileName3 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -ExportTranscriptFileName $invalidExportTranscriptFileName4 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -ExportTranscriptFileName $invalidExportTranscriptFileName5 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -ExportTranscriptFileName $invalidExportTranscriptFileName6 -ErrorAction Stop } | Should -Throw
            { Remove-DuplicateItem -ExportTranscriptFileName $invalidExportTranscriptFileName7 -ErrorAction Stop } | Should -Throw
        }

        It 'Throws exception when DebugFlag is invalid' {
            $invalidDebugFlag = -1

            { Remove-DuplicateItem -DebugFlag $invalidDebugFlag -ErrorAction Stop } | Should -Throw
        }

        It 'Throws exception when DebugFlag is invalid' {
            $invalidDebugFlag = 2

            { Remove-DuplicateItem -DebugFlag $invalidDebugFlag -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'Silence on Errors' {

        It 'Remains silent when Path does not exist' {
            $invalidPath =  "TestDrive:\foo"

            $err = Remove-DuplicateItem -Path $invalidPath -ErrorVariable err -ErrorAction SilentlyContinue

            $err | Should Be $null
        }

    }

    Context 'Transcript' {

        $workDir = "TestDrive:\work"

        $parentDir = "$workDir\parent"
        New-Item $parentDir -ItemType Directory -Force > $null



        It 'Starts Transcript' {
            Mock Start-Transcript {}
            $exportTranscript = $true

            Push-Location $workDir
            Remove-DuplicateItem -Path $parentDir -ExportTranscript:$exportTranscript
            Pop-Location

            Assert-MockCalled Start-Transcript -Times 1
        }

        It 'Stops Transcript' {
            Mock Stop-Transcript {}
            $exportTranscript = $true

            Push-Location $workDir
            Remove-DuplicateItem -Path $parentDir -ExportTranscript:$exportTranscript
            Pop-Location

            Assert-MockCalled Stop-Transcript -Times 1
        }

    }

    Context 'Actions when duplicates are found' {
        $workDir = "TestDrive:\work"

        $parentDir = "$workDir\parent"
        New-Item $parentDir -ItemType Directory -Force > $null
        'foo'           | Out-File "$parentDir\file1"  -Encoding utf8 -Force
        'foo'           | Out-File "$parentDir\file2" -Encoding utf8 -Force

        $childDir = "$parentDir\child"
        New-Item $childDir -ItemType Directory -Force > $null
        'foo'           | Out-File "$childDir\file1"  -Encoding utf8 -Force
        'foo'           | Out-File "$childDir\file2" -Encoding utf8 -Force

        It 'Handles duplicate items' {
            Mock Handle-DuplicateItems {}

            Push-Location $workDir
            Remove-DuplicateItem -Path $parentDir
            Pop-Location

            Assert-MockCalled Handle-DuplicateItems -Times 1
        }

        It 'Exports duplicate items to file' {
            Mock Export-DuplicateItems {}
            $ExportDuplicates = $true

            Push-Location $workDir
            Remove-DuplicateItem -Path $parentDir -ExportDuplicates:$ExportDuplicates
            Pop-Location

            Assert-MockCalled Export-DuplicateItems -Times 1
        }
    }
}
