#Requires -Version 7.0
Import-Module "$PSScriptRoot\ProcessInspector.View.psm1" -Scope Local
Import-Module "$PSScriptRoot\ProcessInspector.Model.psm1" -Scope Local

# Stores the process inspector dialog object.
Set-Variable 'UI' -Scope Script
# Stores the name of the currently selected process.
Set-Variable 'ProcessName' -Scope Script

#Region: Utility scriptblocks.
# Set the process name after notification.
$SetProcessName = {
    Write-Host "Process Name: $($UI.ProcessName)"
    $Script:ProcessName = $($UI.ProcessName)
}

# Return true when the lists (array or collection) are not equal.
$ListsNotEqual = { 
    Param($List1, $List2)
    Return $List1.Count -ne $List2.Count -or
    $($i = 0; $List1.Where({ $_ -ne $List2[$i++] }, 'SkipUntil', 1).Count)
}

# Return true when the strings are not equal.
$StringsNotEqual = {
    Param($String1, $String2)
    Return !([string]::IsNullOrWhiteSpace($String1)) -and
    !([string]::IsNullOrWhiteSpace($String2)) -and $String1 -ne $String2
}

# Get the inspected processes sorted by memory usage. 
$ProcessesSortedByMemoryUsage = {
    Return @((Get-ProcessInstance | Sort-Object 'MemoryUsage' -Descending).Name)
}
#EndRegion

#Region: Function definitions.
Filter Stop-ProcessInspector {
    <#
    .SYNOPSIS
    Release resources.
    .DESCRIPTION
    Stop-ProcessInspector removes all items from the list view and reset variables.
    .EXAMPLE
    Show-ProcessInspector
    Process Name: chrome
    Process Name: msedge
    PS > Stop-ProcessInspector
    PS > Show-ProcessInspector
    Show-ProcessInspector: An error has occured. Please, try to use Reset-ProcessInspector to reset the dialog.

    Show-ProcessInspector cannot show the dialog when it is called after Stop-ProcessInspector.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    Param()

    Try { $UI.Dispose() } Catch {}
    $Script:UI = $Null
    $Script:ProcessName = $Null
}

Filter Reset-ProcessInspector {
    <#
    .SYNOPSIS
    Reset the process inspector.
    .DESCRIPTION
    Reset-ProcessInspector reinitilize the process inspector user interface.
    .PARAMETER NoDisplay
    It specifies that the dialog does not launch.
    .EXAMPLE
    Show-ProcessInspector
    Process Name: chrome
    Process Name: msedge
    PS > Stop-ProcessInspector
    PS > Show-ProcessInspector
    Show-ProcessInspector: An error has occured. Please, try to use Reset-ProcessInspector to reset the dialog.
    PS > Reset-ProcessInspector
    Process Name: Code

    Reset the process inspector dialog after is has stopped.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    Param([switch] $NoDisplay)

    Stop-ProcessInspector
    
    $Script:UI = New-ProcessInspector
    
    # Set the event handlers.
    $UI.OnProcessListDropDown({
        $NewProcessList = $UI.SortByName ? @((Get-ProcessInstance -NoMemoryUsage).Name):(& $ProcessesSortedByMemoryUsage)
        # Refresh the dropdown list only when it is different from the latest list of processes. 
        If ((& $ListsNotEqual $UI.ProcessList $NewProcessList)) {
            $UI.ProcessList = $NewProcessList
            $UI.ProcessName = $Script:ProcessName
        }
    })
    
    $UI.OnProcessSelected({
        # Save the selected process name and notify user only
        # when the current and previous selected processes are different.
        If ((& $StringsNotEqual $UI.ProcessName $Script:ProcessName)) { & $SetProcessName }
    })
    
    $UI.OnTerminateProcessClick({
        # Stop the selected process.
        Stop-Process -Name $Script:ProcessName -Force -ErrorAction SilentlyContinue
        Write-Host "Stopped."
    })
    
    $UI.OnRefreshTick({
        # Refresh the total memory usage and the selected process usage.
        $UI.TotalMemoryUsage = Get-TotalMemoryUsage
        $UI.MemoryUsage = Get-ProcessMemoryUsage $Script:ProcessName
    })

    If (!$NoDisplay) { Show-ProcessInspector }
}

Filter Show-ProcessInspector {
    <#
    .SYNOPSIS
    Show the process inspector dialog window.
    .EXAMPLE
    Show-ProcessInspector
    Process Name: chrome
    Process Name: msedge

    Show the process inspector dialog and select few processes.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    Param()

    If ($Null -ne $UI -and
    ([string]::IsNullOrWhiteSpace($Script:ProcessName) -or
    [string]::IsNullOrWhiteSpace($UI.ProcessName))) {
        $UI.ProcessList = & $ProcessesSortedByMemoryUsage
        $UI.ProcessName = $UI.ProcessList[0]
        & $SetProcessName
    }
    Try { [void] $UI.Display() } 
    Catch { Write-Error 'An error has occured. Please, try to use Reset-ProcessInspector to reset the dialog.' }
}
#EndRegion

# Initialize the UI.
Reset-ProcessInspector -NoDisplay

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = { Stop-ProcessInspector }

Export-ModuleMember -Function 'Reset-ProcessInspector','Show-ProcessInspector','Stop-ProcessInspector'