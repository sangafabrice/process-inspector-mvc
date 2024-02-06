#Requires -Version 7.0

Filter New-ProcessInspector {
    <#
    .SYNOPSIS
    Create a process inspector dialog.
    .DESCRIPTION
    New-ProcessInspector creates a custom object abstracting the view of a process inspector dialog.
    .EXAMPLE
    New-ProcessInspector | Get-Member -MemberType Script* | Select-Object Name,MemberType

    Name                        MemberType
    ----                        ----------
    Display                   ScriptMethod
    Dispose                   ScriptMethod
    OnProcessListDropDown     ScriptMethod
    OnProcessSelected         ScriptMethod
    OnRefreshTick             ScriptMethod
    OnTerminateProcessClick   ScriptMethod
    MemoryUsage             ScriptProperty
    ProcessList             ScriptProperty
    ProcessName             ScriptProperty
    SortByName              ScriptProperty
    TotalMemoryUsage        ScriptProperty

    Create a process inspector dialog and list the expected members to be used by the Controller.
    .EXAMPLE
    (New-ProcessInspector).Display()
    Cancel

    Create, display and close the process inspector dialog.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    Param()

    Push-Location "$PSScriptRoot\script\"
    .\Set-ProcessInspectorUIAdapterProperties ([ref] ($UIAdapter = .\Get-ProcessInspectorUIAdapter ([ref] ($UI = .\New-ProcessInspectorUI)))) ([ref] $UI)
    Pop-Location

    Return $UIAdapter
}