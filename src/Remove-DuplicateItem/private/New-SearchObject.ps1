function New-SearchObject {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [ValidateNotNullOrEmpty()]
        [string]$StartingDir
    ,
        [ValidateNotNullOrEmpty()]
        [string]$Scope
    )

    @{
        startingDir = $StartingDir
        scope = $Scope
        results = @{}
        resultsCount = 0
        duplicateItemsCount = 0
    }
}
