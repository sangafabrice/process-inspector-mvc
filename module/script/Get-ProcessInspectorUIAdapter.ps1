<#
.SYNOPSIS
Get the adapted view of the process inspector dialog.
.DESCRIPTION
The simple factory script returns a Process Inspector UI adapter object. The goal is to encapsulate the process inspector UI (the adaptee) and provide an interface to the controller that has no direct reference to UI elements.
.PARAMETER UI
The process inspector dialog to adapt.
.EXAMPLE
.\Get-ProcessInspectorUIAdapter ([ref] ($dialog = .\New-ProcessInspectorUI)) | Get-Member -MemberType ScriptMethod | Select-Object Name

Name
----
Display
Dispose
OnProcessListDropDown
OnProcessSelected
OnRefreshTick
OnTerminateProcessClick

Get the adapted view of the $dialog UI object and list the expected methods to be used by the Controller.
.EXAMPLE
$dialog = .\New-ProcessInspectorUI
PS > (.\Get-ProcessInspectorUIAdapter ([ref] $dialog)).Display()
Cancel

Create, display and close the process inspector dialog.
#>
[CmdletBinding()]
[OutputType([pscustomobject])]
Param(
    [Parameter(Mandatory)]
    [ValidateNotNull()]
    [ref] $UI
)

Return New-Module -ArgumentList $UI -AsCustomObject {
    Param([ref] $UI)

    Filter OnRefreshTick {
        <#
        .SYNOPSIS
        Add a timer tick event listener to the Process Inspector dialog.
        #>

        # Reinforce that the right number of arguments be entered.
        If ($Args.Count -ne 1) { Throw [System.ArgumentException] }
        # $Args[0] is the handler scriptblock of the added event.
        $UI.Value.Timer.add_Tick($Args[0])
    }

    Filter OnProcessListDropDown {
        <#
        .SYNOPSIS
        Add a combobox dropdown event listener to the Process Inspector dialog.
        #>

        If ($Args.Count -ne 1) { Throw [System.ArgumentException] }
        $UI.Value.ComboBoxForProcessName.add_DropDown($Args[0])
    }

    Filter OnProcessSelected {
        <#
        .SYNOPSIS
        Add a combobox selection change committed event listener to the Process Inspector dialog.
        .DESCRIPTION
        The event occurs after a process name in the dropdown list has been clicked to be committed.  
        #>

        If ($Args.Count -ne 1) { Throw [System.ArgumentException] }
        $UI.Value.ComboBoxForProcessName.add_SelectionChangeCommitted($Args[0])
    }

    Filter OnTerminateProcessClick {
        <#
        .SYNOPSIS
        Add a button click event listener to the Process Inspector dialog.
        #>

        If ($Args.Count -ne 1) { Throw [System.ArgumentException] }
        $UI.Value.ButtonToTerminateProcess.add_Click($Args[0])
    }

    Filter Display {
        <#
        .SYNOPSIS
        Display the process inspector dialog after starting the timer.
        #>

        If ($Args.Count -ne 0) { Throw [System.ArgumentException] }
        $UI.Value | ForEach-Object {
            $_.Timer.Start()
            $_.ShowDialog()
        } 
    }

    Filter Dispose {
        <#
        .SYNOPSIS
        Clean up the UI objects after the timer has been stopped.
        #>

        If ($Args.Count -ne 0) { Throw [System.ArgumentException] }
        $UI.Value | ForEach-Object {
            $_.Timer | ForEach-Object {
                $_.Stop()
                $_.Dispose()
            }
            $_.Controls.ForEach{ $_.Dispose() }
            $_.Dispose()
        }
    }
}