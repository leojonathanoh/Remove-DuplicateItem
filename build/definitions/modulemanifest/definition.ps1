# - Initial setup: Fill in the GUID value. Generate one by running the command 'New-GUID'. Then fill in all relevant details.
# - Ensure all relevant details are updated prior to publishing each version of the module.
# - To simulate generation of the manifest based on this definition, run the included development entrypoint script Invoke-PSModulePublisher.ps1.
# - To publish the module, tag the associated commit and push the tag.
@{
    RootModule = 'Remove-DuplicateItem.psm1'
    # ModuleVersion = ''                            # Value will be set for each publication based on the tag ref. Defaults to '0.0.0' in development environments and regular CI builds
    GUID = '8b66d077-8d0e-45c3-b923-73fddcd6f7b9'
    Author = 'The Oh Brothers'
    CompanyName = 'The Oh Brothers'
    Copyright = '(c) 2017 The Oh Brothers'
    Description = 'Removes duplicate files.'
    PowerShellVersion = '3.0'
    # PowerShellHostName = ''
    # PowerShellHostVersion = ''
    # DotNetFrameworkVersion = ''
    # CLRVersion = ''
    # ProcessorArchitecture = ''
    RequiredModules = @(
        @{
            ModuleName = "Get-DuplicateItem"
            ModuleVersion = '1.1.2'
        }
    )
    # RequiredAssemblies = @()
    # ScriptsToProcess = @()
    # TypesToProcess = @()
    # FormatsToProcess = @()
    # NestedModules = @()
    FunctionsToExport = @(
        Get-ChildItem $PSScriptRoot/../../../src/Remove-DuplicateItem/public -Exclude *.Tests.ps1 | % { $_.BaseName }
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    # DscResourcesToExport = @()
    # ModuleList = @()
    # FileList = @()
    PrivateData = @{
        # PSData = @{           # Properties within PSData will be correctly added to the manifest via Update-ModuleManifest without the PSData key. Leave the key commented out.
            Tags = @(
                'duplicate'
                'files'
                'find'
                'get'
                'item'
                'list'
                'remove'
            )
            LicenseUri = 'https://raw.githubusercontent.com/leojonathanoh/Remove-DuplicateItem/master/LICENSE'
            ProjectUri = 'https://github.com/leojonathanoh/Remove-DuplicateItem'
            # IconUri = ''
            # ReleaseNotes = ''
            # Prerelease = ''
            # RequireLicenseAcceptance = $false
            # ExternalModuleDependencies = @()
        # }
        # HelpInfoURI = ''
        # DefaultCommandPrefix = ''
    }
}
