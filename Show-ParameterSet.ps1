<#PSScriptInfo

.VERSION 1.0

.GUID 688680b4-cb5f-433d-8cce-7ee057f9eef3

.AUTHOR MartinGC94

.COMPANYNAME 

.COPYRIGHT 

.TAGS Parameter Parameterset Help

.LICENSEURI 

.PROJECTURI https://github.com/MartinGC94/PublishedScripts

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
#>


#Requires -Version 5
<#
.Synopsis
    Shows parameter sets for a given command.
.DESCRIPTION
    Shows parameter sets for a given command.
.PARAMETER CommandName
    Name of the command(s) to lookup. Supports wildcards like Get-Command does.
.PARAMETER InputObject
    Input from Get-Command output.
.PARAMETER ParameterSetName
    The parameter set name to show parameters for. Supports wildcards.
.PARAMETER MandatoryOnly
    Show only mandatory parameters from each parameter set.
.PARAMETER IncludeCommonParameters
    Show common parameters that all Advanced functions/cmdlets get such as Verbose.
.PARAMETER NoColors
    Disables any color customization from the output.
.EXAMPLE
    Get-Command | Get-Random | Show-ParameterSet
    Shows all parametersets for a random command, note that if the module hasn't been imported it will show no parameters.
.EXAMPLE
    Show-ParameterSet -CommandName Remove-Item -ParameterSetName LiteralPath
    Shows the parameters for the LiteralPath parameterset of Remove-Item
.INPUTS
    Command name strings and output from Get-Command
.OUTPUTS
    Strings and format data that is not suited for anything except plaintext export.
.NOTES
    Information for commands from modules that hasn't been imported yet will be inaccurate.
#>
[CmdletBinding(DefaultParameterSetName="ByName")]

Param
(
    [Parameter(Mandatory,ValueFromPipeline,ParameterSetName="ByName",Position=0)]
    [string[]]
    $CommandName,

    [Parameter(Mandatory,ValueFromPipeline,ParameterSetName="ByObject")]
    [System.Management.Automation.CommandInfo[]]
    $InputObject,

    [Parameter(Position=1)]
    [ArgumentCompleter(
    {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

        if ($fakeBoundParameters["CommandName"])
        {
            $FoundCommand=Get-Command -Name $fakeBoundParameters["CommandName"] -ErrorAction Ignore
        }
        else
        {
            $FoundCommand=$fakeBoundParameters["Command"]
        }

        if ($FoundCommand -is [System.Management.Automation.CommandInfo])
        {
            $ParamSets=$FoundCommand.ParameterSets | Where-Object -Property Name -Like "$wordToComplete*"
            foreach ($Item in $ParamSets)
            {
                $CompletionText = $Item.Name
                $ListItemText   = $Item.Name
                $ResultType     = [System.Management.Automation.CompletionResultType]::ParameterValue
                $ToolTip        = "Default: $($Item.IsDefault)"

                [System.Management.Automation.CompletionResult]::new($CompletionText,$ListItemText,$ResultType,$ToolTip)
            }
        }
    }
    )]
    [string]
    $ParameterSetName="*",

    [Parameter()]
    [switch]
    $MandatoryOnly,

    [Parameter()]
    [switch]
    $IncludeCommonParameters,

    [Parameter()]
    [switch]$NoColors,

    [Parameter(DontShow)]
    [string]$CommandNameColor="$([char]27)[4m",

    [Parameter(DontShow)]
    [string]$ParameterSetInfoColor="$([char]27)[96m",

    [Parameter(DontShow)]
    [string]$MandatoryParameterColor="$([char]27)[92m"
)
begin
{
    $ColorReset="$([char]27)[0m"
    if ($Host.UI.SupportsVirtualTerminal -eq $false -or $NoColors)
    {
        $CommandNameColor=""
        $ParameterSetInfoColor=""
        $MandatoryParameterColor=""
        $ColorReset=""
    }
    $CommonParameters=[System.Management.Automation.Cmdlet]::CommonParameters
}
Process
{
    if ($CommandName)
    {
        $CommandsToShow=Get-Command -Name $CommandName
    }
    if ($InputObject)
    {
        $CommandsToShow=$InputObject
    }

    foreach ($Command in $CommandsToShow)
    {
        if ($Command -is [System.Management.Automation.AliasInfo])
        {
            $ParameterSets=$Command.ResolvedCommand.ParameterSets
        }
        else
        {
            $ParameterSets=$Command.ParameterSets
        }

        #Output
        "CommandName: $CommandNameColor$($Command.Name)$ColorReset"
        ""

        foreach ($Item in ($ParameterSets | Where-Object -Property Name -Like $ParameterSetName) )
        {
            $ParametersToShow=$Item.Parameters
            if (!$IncludeCommonParameters)
            {
                $ParametersToShow=$ParametersToShow | Where-Object -Property Name -NotIn $CommonParameters
            }
            if ($MandatoryOnly)
            {
                $ParametersToShow=$ParametersToShow | Where-Object -Property IsMandatory -EQ $true
            }

            #Output
            "  ParameterSetName: $ParameterSetInfoColor$($Item.Name)$ColorReset"
            "  IsDefault: $ParameterSetInfoColor$($Item.IsDefault)$ColorReset"


            $TableOutput=$ParametersToShow | Format-Table -Property @(
                @{Name="Position";           Expression={if ($_.Position -eq -2147483648) {$null} else {$_.Position} } }
                "Name"
                @{Name="ParameterType";      Expression={$_.ParameterType.Name} }
                @{Name="Mandatory";          Expression={$_.IsMandatory} }
                @{Name="Dynamic";            Expression={$_.IsDynamic} }
                "Aliases"
                @{Name="Pipeline";           Expression={$_.ValueFromPipeline} }
                @{Name="PropertyName";       Expression={$_.ValueFromPipelineByPropertyName} }
                @{Name="RemainingArguments"; Expression={$_.ValueFromRemainingArguments} }
            )
            
            foreach ($Line in $TableOutput)
            {
                $FieldList=$Line.formatEntryInfo.formatPropertyFieldList

                if ($FieldList)
                {
                    #If Mandatory field is True
                    if ($FieldList[3].propertyValue -eq "True")
                    {
                        foreach ($Property in $FieldList)
                        {
                            $Property.propertyValue="$MandatoryParameterColor$($Property.propertyValue)$ColorReset"
                        }
                    }
                    #Right alignment for Position field
                    $FieldList[0].alignment=3
                }
            }
            #Output
            $TableOutput

            if (!$ParametersToShow)
            {
                #Output
                ""
            }
        }
    }
}