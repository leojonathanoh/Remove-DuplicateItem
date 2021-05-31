$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "New-SearchObject" -Tag 'Unit' {

    Context 'Terminating errors' {

        It 'throws exception when StartingDir is invalid' {
            $invalidStartingDir = ''
            $scope = 'foo'

            { New-SearchObject -StartingDir $invalidStartingDir -Scope $scope } | Should -Throw
        }

        It 'throws exception when Scope is invalid' {
            $startingDir = "TestDrive:\"
            $invalidScope = ''

            { New-SearchObject -StartingDir $startingDir -Scope $invalidScope } | Should -Throw
        }

    }

    Context 'Return' {

        It 'Should return a [hashtable]' {
            $startingDir = "TestDrive:\"
            $scope = 'foo'

            $result = New-SearchObject -StartingDir $startingDir -Scope $scope
            $result | Should -BeOfType [hashtable]
        }

    }

}
