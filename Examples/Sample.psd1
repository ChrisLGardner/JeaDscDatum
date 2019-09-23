@{
    Configurations = @(
        "JeaConfig"
    )

    JeaConfig = @{
        SessionConfigurations = @(
            @{
                EndpointName = 'Sample'
                TranscriptDirectory = 'C:\ProgramData\JEAConfiguration\Transcripts'
                RunAsVirtualAccountGroups = 'Administrators'
                RoleDefinitions = @{
                    GeneralLev1Group = @{ RoleCapabilities = 'BasicTest' }
                }
            }
        )
        RoleCapabilities = @(
            @{
                Name = 'BasicTest'
                Path = 'C:\Program Files\WindowsPowerShell\Modules\Jea\RoleCapabilities\BasicTest.psrc'
                VisibleCmdlets = 'Invoke-Cmdlet1', @{ Name = 'Invoke-Cmdlet2'; Parameters = @{ Name = 'Parameter1'; ValidateSet = 'Item1', 'Item2' }, @{ Name = 'Parameter2'; ValidatePattern = 'L*' } }
                VisibleFunctions = 'Invoke-Function1', @{ Name = 'Invoke-Function2'; Parameters = @{ Name = 'Parameter1'; ValidateSet = 'Item1', 'Item2' }, @{ Name = 'Parameter2'; ValidatePattern = 'L*' } }
                VisibleProviders = 'Item1'
            }
        )
    }
}
