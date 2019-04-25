function Out-HashString {
    <# 
    .SYNOPSIS 
        Convert an hashtable or and OrderedDictionary to a string 
    
    .DESCRIPTION 
        Convert an hashtable or and OrderedDictionary to a string 
    
    .PARAMETER InputObject 
        The object that is to be converted 
    
    .PARAMETER PreSpacing 
        Number of spaces used for indentation 
    
    .EXAMPLE 
        $hashObject = @{ 
            Name = "Tore" 
            Goal = "Rule the World" 
        } 
        $hashObject | Out-HashString 
    
        This will convert the hashtable to the following string 
        @{ 
            Name = "Tore" 
            Goal = "Rule the World" 
        } 
    
    .INPUTS 
        Hashtable 
    
    .OUTPUTS 
        string 
        
    .NOTES 
        Author: Tore Groneng 
        Website: www.firstpoint.no 
        Twitter: @ToreGroneng 
    #>
    [cmdletbinding()]
    Param(
        [Parameter(ValueFromPipeLine)]
        $InputObject,
        
        [string]$PreSpacing = " "
    )
    Begin {
        $f = $MyInvocation.InvocationName
        Write-Verbose -Message "$f - START"
        $newLine = [environment]::NewLine

        if ($PreSpacing) {
            $endspaceCount = $PreSpacing.Length - 4
            if ($endspaceCount -lt 0) { $endspaceCount = 0 }
            $endspace = " " * $endspaceCount
            $beginSpace = " " * $endspaceCount
        }   
    }
    Process {
        $out = "@{"
    
        $out = $out + $newLine
        $preSpace = $PreSpacing

        if (-not $InputObject -or $InputObject.keys.count -eq 0) { return "@{}" }

        foreach ($key in $InputObject.Keys) {
            Write-Verbose -Message "$f - Processing key [$key]"

            if ($key.Contains('$')) {
                $DisplayKey = "'$key'"
            }

            $value = $InputObject.$key
            $objType = $value.GetType().Name
            Write-Verbose -Message "$f - ObjectType = $objType"
        
            $mode = "stringValue"

            if ($objType -eq "Hashtable" -or $objType -eq "OrderedDictionary") {
                $mode = "hashtable"
            }
        
            if ($value -is [array] -or $objType -eq 'List`1') {
                if ($value[0]) {
                    $arrayType = $value[0].GetType().Name
                    Write-Verbose -Message "$f - arrayType is [$arrayType]"
                
                    if ($arrayType -eq "Hashtable" -or $arrayType -eq "OrderedDictionary") {
                        $mode = "HashTableValue"
                    }
                    else {
                        $mode = "ArrayValue"
                    }
                }            
            }
        
            Write-Verbose -Message "$f - Mode is [$mode]"
            if ($DisplayKey) {
                $key = $DisplayKey
                $DisplayKey = $null
            }

            $out += "$PreSpacing$key = "
        
            switch ($mode) {
                'stringValue' {
                    $out += '"' + $value + '"' + $newLine 
                }

                'hashtable' {               
                    $stringValue = Out-HashString -InputObject $value -PreSpacing "$PreSpacing "
                    $out += $stringValue + $newLine
                }

                'HashTableValue' {
                    $stringValue = ""
                    foreach ($arrayHash in $value) {                                       
                        $hashString = Out-HashString -InputObject $arrayHash -PreSpacing "$PreSpacing "
                        $hash = " $hashString"
                        $hash = "$hash," + $newLine
                        $stringValue += $hash
                    }
                    $separatorIndex = $stringValue.LastIndexOf(",")
                    $stringValue = $stringValue.Remove($separatorIndex, 1)                
                    $out += $stringValue
                }

                'ArrayValue' {
                    $out += '"' + ($value -join '","') + '"' + $newLine
                }
            
                Default { }
            }
        }
        $out += "$endspace}"
        $out          
    }
}


function Convert-RolePropertiesToString {
    param (
        $Role
    )
    $NewHashtable = @{}

    foreach ($Property in $Role.Keys) {
        $output = @()
        
        Foreach ($Item in $Role.$Property) {
            if ($Role.$Property -is [Array] -or $Role.$Property.gettype().name -eq 'List`1') {
                if ($Item.GetType().Name -in @('Hashtable','OrderedDictionary')) {
                    $output += Out-Hashstring -InputObject $Item
                }
                else {
                    $output += $Item
                }
            }
            else {
                if ($Item.GetType().Name -in @('Hashtable','OrderedDictionary')) {
                    $output = Out-Hashstring -InputObject $Item
                }
                else {
                    $output = $Item
                }
            }
        }
        $NewHashtable.$Property = $output
    }

    $NewHashtable
}

Configuration JeaConfig {
    Param(
        $SessionConfigurations = @(),
        $RoleCapabilities = @()
    )

    Import-DscResource -ModuleName JeaDsc

    foreach ($Role in $RoleCapabilities) {
        if (!$Role.Ensure) { $Role.add('Ensure', 'Present') }
        $Name = $Role.Name
        $Role.Remove('Name')

        $RoleHashtable = Convert-RolePropertiesToString -Role $Role
        (Get-DscSplattedResource -ResourceName 'JeaRoleCapabilities' -ExecutionName "$($Name)_rc" -Properties $RoleHashtable -NoInvoke).Invoke($RoleHashtable)
    }

    foreach ($SessionConfiguration in $SessionConfigurations) {
        if (!$SessionConfiguration.Ensure) { $SessionConfiguration.add('Ensure', 'Present') }

        $SessionConfigurationHashtable = Convert-RolePropertiesToString -Role $SessionConfiguration
        (Get-DscSplattedResource -ResourceName 'JeaSessionConfiguration' -ExecutionName "$($SessionConfiguration.EndpointName)_sc" -Properties $SessionConfigurationHashtable -NoInvoke).Invoke($SessionConfigurationHashtable)
    }

}

