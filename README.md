## **Use MVC to make a GUI with PowerShell WinForms: the Process Inspector** 
![Module Version](https://img.shields.io/badge/version-0.0.0-teal) ![Test Coverage](https://img.shields.io/badge/coverage-100%25-teal)
[![CD of ProcessInspector](https://github.com/sangafabrice/process-inspector-mvc/actions/workflows/publish-module.yaml/badge.svg)](https://github.com/sangafabrice/process-inspector-mvc/actions/workflows/publish-module.yaml)

Author: Fabrice Sanga
<br>

You might be familiar with the **Task Manager** in Windows, which you rush to when a program window stops working abruptly and notifies you that its process is _Not Responding_.  You then have no option other than clicking the button to _End Task_. By the name you guess, it manages tasks. It has many more features than inspecting and ending processes like monitoring system performance, starting tasks, etc.

The **Process Inspector** dialogue box is another reinvented wheel that inspects individual processes and provides an option to stop them. It is a simplified view of the Task Manager. However, it is a practical starter for making GUI applications in PowerShell while applying the **Model-View-Controller (MVC)** architecture.

Here is the link to the demo of the Process Inspector [on YouTube](https://youtu.be/_qvuhucREUY). :film_strip:

<img src="https://gistcdn.githack.com/sangafabrice/a8c75d6031a491c0907d5ca5eb5587e0/raw/406120be7a900c3998e33d7302772827f20539f0/automation.svg" alt="Custom Powershell Module Icon" width="3%"> [![Downloads](https://img.shields.io/powershellgallery/dt/ProcessInspector?color=blue&label=PSGallery%20%E2%AC%87%EF%B8%8F)](https://www.powershellgallery.com/packages/ProcessInspector)
--
<br>

The project is a PowerShell module structured around three nested module scripts **ProcessInspector.Model.psm1**, **ProcessInspector.View.psm1**</span>, and **ProcessInspector.Controller.psm1** in the `.\module` subfolder provided that the paths are relative to the module base directory in `PSModulePath`.
<br>

```
ProcessInspector
│   ProcessInspector.psd1
│
└───module
    │   ProcessInspector.Controller.psm1
    │   ProcessInspector.Model.psm1
    │   ProcessInspector.View.psm1
    │
    └───script
            Get-ProcessInspectorUIAdapter.ps1
            ico.bmp
            New-ProcessInspectorUI.ps1
            Set-ProcessInspectorUIAdapterProperties.ps1
```
<br>

## 1. The ProcessInspector.View nested module

The module contains all the code related to the user interface, which is built using **Windows Forms**. It exports its only function **New-ProcessInspector**, referred to as a **Factory Method** that creates a new process inspector dialogue object that contains all the graphic elements.

```PowerShell
PS> Import-Module ProcessInspector\module\ProcessInspector.View.psm1
PS> New-ProcessInspector | Get-Member -MemberType Script* | Select-Object Name,MemberType

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
```
<br>

With the previous commands, we list the custom methods and properties of the Process Inspector UI object. It inherits its other members from the `PSCustomObject` type. You can unbind the parameter `MemberType` from `Get-Member` to get the complete list of members.

The created Process Inspector UI object encapsulates the bare **WinForms** user interface. The logic of the function `New-ProcessInspector` depends on the **Adapter Design Pattern**. The first script on which the View module depends, **New-ProcessInspectorUI.ps1**, returns the WinForms dialogue box object decorated with a timer and other note-properties that refer to graphic elements which state or behavior change.

```PowerShell
PS> .\ProcessInspector\module\script\New-ProcessInspectorUI | Get-Member -MemberType NoteProperty | Select-Object Name

Name
----
ButtonToTerminateProcess
CheckBoxForSortByNameOption
ComboBoxForProcessName
LabelForMemoryUsage
LabelForTotalMemoryUsage
Timer
```
<br>

`New-ProcessInspector` returns an adapted view of the user interface form with the successive calls to **Get-ProcessInspectorUIAdapter.ps1** and **Set-ProcessInspectorUIAdapterProperties.ps1** scripts.

First, the controls convert to the values they contain:
+ **ComboBoxForProcessName** converts to **ProcessName** and **ProcessList**,
+ **CheckBoxForSortByNameOption** converts to **SortByName**,
+ **LabelForMemoryUsage** converts to **MemoryUsage**,
+ **LabelForTotalMemoryUsage** converts to **TotalMemoryUsage**.

Then, the controls and timer convert to a unified set of event listeners:
+ **ComboBoxForProcessName** listens to **OnProcessSelected()** and **OnProcessListDropDown()**,
+ **ButtonToTerminateProcess** listens to **OnTerminateProcessClick()**,
+ **Timer** listens to **OnRefreshTick()**.

The method **Display()** starts the timer and opens the dialogue box. The timer stops when the dialogue box closes. **Dispose()** releases resources.

Here is the link to the demo of the View [on YouTube](https://youtu.be/2To7t4ZtoW0). :film_strip:
<br>
<br>

## 2. The ProcessInspector.Model nested module

The module is stateless and exports three simple functions. Their goal is to read data related to processes on the local system.
+ **Get-ProcessInstance** gets a list of custom process objects. It only returns process names when it binds the parameter **NoMemoryUsage** switch for faster processing time when the user ticks the option to sort the list by names.
+ **Get-ProcessMemoryUsage** returns the memory usage in megabytes (MB) of a specified process as computed in Task Manager. Here is the link to the comparison of values between the Task Manager and the Process Inspector [on YouTube](https://youtube.com/shorts/XL0X0GET7Vo?feature=share). :film_strip:
+ **Get-TotalMemoryUsage** returns the total memory usage of the local computer and displays it as a percentage value.

```PowerShell
PS> Import-Module ProcessInspector\module\ProcessInspector.Model.psm1
PS> Get-ProcessInstance | Sort-Object MemoryUsage -Descending | Select-Object -First 10

Name                      MemoryUsage
----                      -----------
chrome                  1647558656.00
Code                    1311846400.00
MsMpEng                  360693760.00
msedge                   347893760.00
svchost                  206532608.00
StartMenuExperienceHost  176316416.00
dwm                      136261632.00
Video.UI                 132186112.00
explorer                 130179072.00
pwsh                     128028672.00

PS> Get-ProcessInstance -NoMemoryUsage | Select-Object -First 10

Name
----
AgentService
ApplicationFrameHost
app_updater
audiodg
backgroundTaskHost
chrome
client32
cmd
Code
CompPkgSrv

PS> Get-ProcessMemoryUsage chrome # in MB
1440.44

PS> Get-TotalMemoryUsage # in %
74.71
```
<br>

## 3. The ProcessInspector.Controller nested module

The Controller module is a **Mediator** between the View and the Model, both decoupled from each other. It exports three functions whose tasks are as follows:
+ **Reset-ProcessInspector**: initializing the User Interface or resetting it,
+ **Show-ProcessInspector**: displaying the Process Inspector dialog window,
+ **Stop-ProcessInspector**: disposing of the resources.

`Reset-ProcessInspector` is where the **event handlers** are defined. The Controller performs only one **Delete** operation on the data when the **OnTerminateProcessClick** is raised. When the user clicks **"Terminate Process"**, the selected process is deleted from the dropdown list and stopped from running on the local system.

**Read** operations happen when the user opens the dialogue to display the overall memory usage of the local system, when she clicks the combo box to list processes, and when she selects one to show its memory consumption.

At last, the root module imports the Controller module and loads the **ProcessInspector** module.