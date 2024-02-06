<#
.SYNOPSIS
Creates a new process inspector dialog.
.DESCRIPTION
The simple factory script returns a new process inspector dialog object.
.EXAMPLE
.\New-ProcessInspectorUI | Get-Member ComboBox*,Label*,Button*,CheckBox*,Timer | Select-Object Name

Name
----
ComboBoxForProcessName
LabelForMemoryUsage
LabelForTotalMemoryUsage
ButtonToTerminateProcess
CheckBoxForSortByNameOption
Timer

Create a process inspector dialog instance and list its controls and timer.
.EXAMPLE
(.\New-ProcessInspectorUI).ShowDialog()
Cancel

Create, display and close the process inspector dialog.
#>
using namespace System.Windows.Forms
using namespace System.Drawing

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[Form]::new() | ForEach-Object {
    $_.Size = '450, 250'
    $_.Text = 'Process Inspector'
    $_.Icon = [Icon]::FromHandle([Bitmap]::FromFile("$PSScriptRoot\ico.bmp").GetHicon())
    $_.BackColor = 'White'
    $_.Font = 'Verdana,10'
    $_.StartPosition = 'CenterScreen'
    $_.MinimumSize = $_.Size
    $_.MaximumSize = $_.Size
    $_.Name = 'DialogForProcessInspector'

    # The immediately invoked scriptblock is used to avoid poluting
    # the global environment with variables created in the script.
    $_.Controls.AddRange(@(& {
        [Label]::new() | ForEach-Object {
            $_.AutoSize = $True
            $_.Text = 'Process name :'
            $_.Location = '20, 20'
            # Only the added controls must be returned.
            Return $_
        }
        [Label]::new() | ForEach-Object {
            $_.AutoSize = $True
            $_.Text = 'Memory usage (MB) :'
            $_.Location = '20, 80'
            Return $_
        }
        [Label]::new() | ForEach-Object {
            $_.AutoSize = $True
            $_.Text = 'Overall memory usage (%) :'
            $_.Font = '9'
            $_.Location = '20, 160'
            Return $_
        }
        # The parentheses wrap the initialization to ensure that
        # the value stored in the variable is immediately returned.
        ($ComboBox = [ComboBox]::new() | ForEach-Object {
            $_.Width = 230
            $_.BackColor = 'WhiteSmoke'
            $_.DropDownStyle = 'DropDownList'
            $_.FlatStyle = 'Flat'
            $_.Location = "182, 17"
            # Only the controls that are meant to change are assigned a name.
            $_.Name = 'ComboBoxForProcessName'
            Return $_
        })
        # The label below is used to draw a solid border around the combobox.
        [Label]::new() | ForEach-Object {
            $_.Width = $ComboBox.Width + 2
            $_.Height = $ComboBox.Height + 3 + $(If ($PSVersionTable.PSVersion.Major -lt 7) { 2 })
            $_.BorderStyle = 'FixedSingle'
            $_.Location = "$($ComboBox.Left - 1), $($ComboBox.Top - 1)"
            Return $_
        }
        [Label]::new() | ForEach-Object {
            $_.AutoSize = $True
            # The label is left aligned with the combobox control.
            $_.Location = "$($ComboBox.Left), 80"
            $_.Name = 'LabelForMemoryUsage'
            Return $_
        }
        [Label]::new() | ForEach-Object {
            $_.AutoSize = $True
            $_.Font = '9'
            $_.Location = "$($ComboBox.Left), 160"
            $_.Name = 'LabelForTotalMemoryUsage'
            Return $_
        }
        [Button]::new() | ForEach-Object {
            $_.Text = 'Terminate Process'
            $_.AutoSize = $True
            $_.FlatStyle = 'Flat'
            $_.Location = '268, 150'
            $_.Name = 'ButtonToTerminateProcess'
            Return $_
        }
        ($CheckBox = [CheckBox]::new() | ForEach-Object {
            $_.FlatStyle = 'Flat'
            $_.Checked = $False
            $_.Location = "$($ComboBox.Right - 11), 44"
            $_.Name = 'CheckBoxForSortByNameOption'
            Return $_
        })
        [Label]::new() | ForEach-Object {
            $_.AutoSize = $True
            $_.Text = 'Sort A-Z'
            $_.Font = '8'
            $_.Location = "$($CheckBox.Left - 50), 49"
            Return $_
        }
    }))

    # Decorate the Form object with the controls which names are not empty.
    Get-Variable '_' -PipelineVariable UI | ForEach-Object {
        $UI.Value.Controls.Where{ !!$_.Name } | ForEach-Object {
            Add-Member -InputObject $UI.Value -Name $_.Name -Value $_ -MemberType NoteProperty
        }
    }

    # Decorate the Form object with the Timer property which
    # refreshes the information in the form fields every second.
    Add-Member -Value $([Timer]::new() | ForEach-Object {
        $_.Interval = 1000
        Return $_
    }) -InputObject $_ -Name Timer -MemberType NoteProperty

    # Stop the refresh timer when the form dialog is not visible.
    $_.add_VisibleChanged({ If (!$This.Visible) { $This.Timer.Stop() } })
    
    # Return the form object.
    Return $_
}