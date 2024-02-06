#Requires -Version 7.0
<#
.SYNOPSIS
Set the properties of the process inspector dialog view.
.DESCRIPTION
The script decorate the process inspector dialog adapter with a set of propeties.
.PARAMETER UIAdapter
The process inspector dialog adapter to be decorated.
.PARAMETER UI
The process inspector dialog to adapt.
.EXAMPLE
.\Set-ProcessInspectorUIAdapterProperties ([ref] ($dialog = .\Get-ProcessInspectorUIAdapter ([ref] ($UI = .\New-ProcessInspectorUI)))) ([ref] $UI)
PS > $dialog | Get-Member -MemberType ScriptProperty | Select-Object Name

Name
----
MemoryUsage
ProcessList
ProcessName
SortByName
TotalMemoryUsage

Get the adapted view of the $dialog UI object and list the expected properties to be used by the Controller.
.EXAMPLE
.\Set-ProcessInspectorUIAdapterProperties ([ref] ($dialog = .\Get-ProcessInspectorUIAdapter ([ref] ($UI = .\New-ProcessInspectorUI)))) ([ref] $UI)
PS > $dialog.ProcessList = 'chrome','msedge','firefox'
PS > $UI.ComboBoxForProcessName.Items
chrome
msedge
firefox

Create the process inspector dialog and add items to the combobox dropdown list.
#>
[CmdletBinding()]
[OutputType([void])]
Param(
    [Parameter(Mandatory)]
    [ValidateNotNull()]
    [ref] $UIAdapter,
    [Parameter(Mandatory)]
    [ValidateNotNull()]
    [ref] $UI
)

# Partial Add-Member parameters.
@{
    InputObject = $UIAdapter.Value
    MemberType  = 'ScriptProperty'
} | ForEach-Object {

    # Decorate the UI Adapter object with custom properties.
    # -Value defines the getter and -SecondValue defines the setter.
    @{
        Name        = 'ProcessList'
        Value       = {
            [CmdletBinding()]
            [OutputType([object[]])]
            Param()
            @($UI.Value.ComboBoxForProcessName.Items)
        }.GetNewClosure()
        SecondValue = {
            Param($ProcessNameList)
            $UI.Value.ComboBoxForProcessName | ForEach-Object {
                $_.Items.Clear()
                $_.Items.AddRange($ProcessNameList)
            }
        }.GetNewClosure()
    } + $_ | ForEach-Object { Add-Member @_ }

    @{
        Name        = 'ProcessName'
        Value       = {
            [CmdletBinding()]
            [OutputType([string])]
            Param()
            $UI.Value.ComboBoxForProcessName.Text
        }.GetNewClosure() 
        SecondValue = { $UI.Value.ComboBoxForProcessName.Text = $Args[0] }.GetNewClosure()
    } + $_ | ForEach-Object { Add-Member @_ }

    @{
        Name        = 'SortByName'
        Value       = {
            [CmdletBinding()]
            [OutputType([bool])]
            Param()
            $UI.Value.CheckBoxForSortByNameOption.Checked
        }.GetNewClosure()
    } + $_ | ForEach-Object { Add-Member @_ }

    @{
        Name        = 'MemoryUsage'
        Value       = {}
        SecondValue = { $UI.Value.LabelForMemoryUsage.Text = $Args[0] }.GetNewClosure()
    } + $_ | ForEach-Object { Add-Member @_ }
    
    @{
        Name        = 'TotalMemoryUsage'
        Value       = {}
        SecondValue = {
            [CmdletBinding()]
            Param([double] $TotalMemoryUsage)
            $UI.Value.LabelForTotalMemoryUsage | ForEach-Object {
                # If the overall memory usage is less or equal to 50%, set the text to green.
                # Set it to red otherwise.
                $_.ForeColor = 50.00 -ge ($_.Text = $TotalMemoryUsage) ? 'green':'red'
            }
        }.GetNewClosure()
    } + $_ | ForEach-Object { Add-Member @_ }
}