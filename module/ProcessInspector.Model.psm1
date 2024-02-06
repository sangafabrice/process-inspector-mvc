#Requires -Version 7.0

Filter Get-TotalMemoryUsage {
    <#
    .SYNOPSIS
    Get the overall system memory usage.
    .DESCRIPTION
    Get-TotalMemoryUsage returns the total memory usage of the local computer and displays it as a percentage value.
    .EXAMPLE
    Get-TotalMemoryUsage
    67.67
    
    The total memory usage of the local computer is 67.67%.
    #>
    [CmdletBinding()]
    [OutputType([double])]
    Param()

    Return [System.Math]::Round((1 - ((Get-CimInstance -Class Win32_OperatingSystem) |
    ForEach-Object { $_.FreePhysicalMemory/$_.TotalVisibleMemorySize })) * 100.0 , 2)
}

Filter Get-ProcessMemoryUsage {
    <#
    .SYNOPSIS
    Get the memory usage of the specified process.
    .DESCRIPTION
    Get-ProcessMemoryUsage returns the memory usage of a process specified by its name and displays it in megabytes (MB).
    .PARAMETER Name
    The name of the specified process.
    .EXAMPLE
    Get-ProcessMemoryUsage 'chrome'
    1376.88

    The memory usage of chrome is 1376.88MB.
    #>
    [CmdletBinding()]
    [OutputType([double])]
    Param(
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string] $Name
    ) 

    Return [string]::IsNullOrWhiteSpace($Name) ? 0:([System.Math]::Round(((Get-CimInstance Win32_PerfFormattedData_PerfProc_Process).
    Where({ $_.Name -match "^$Name(#[1-9]\d*)?$" }) | Measure-Object WorkingSetPrivate -Sum).Sum / 1MB, 2))
}

Filter Get-ProcessInstance {
    <#
    .SYNOPSIS
    Get custom process object.
    .DESCRIPTION
    Get-ProcessInstance returns a custom process object with its name and its memory usage.
    .PARAMETER NoMemoryUsage
    The switch specifies that the memory usage is not returned.
    .EXAMPLE
    Get-ProcessInstance | Sort-Object MemoryUsage -Descending | Select-Object -First 10

    Name               MemoryUsage
    ----               -----------
    chrome           1443762176.00
    Code              699727872.00
    pwsh              507662336.00
    svchost           390881280.00
    msedge            334741504.00
    MsMpEng           241418240.00
    dwm                79663104.00
    IAStorDataMgrSvc   77639680.00
    RuntimeBroker      52133888.00
    explorer           51228672.00

    Get the 10 most memory-consuming processes.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    Param([switch] $NoMemoryUsage)

    If ($NoMemoryUsage) { Return Get-Process | Select-Object Name -Unique }
    
    Return (
        (Get-CimInstance Win32_PerfFormattedData_PerfProc_Process).Where{ $_.Name -ne '_Total' } |
        Select-Object @{ N = 'Name'; E = { ($_.Name -split '#')[0] } },WorkingSetPrivate |
        Group-Object -Property Name
    ) | ForEach-Object -Parallel {
        Add-Member -InputObject $(
            $_.Group | Measure-Object WorkingSetPrivate -Sum
        ) -MemberType NoteProperty -Name Name -Value $_.Name -Passthru
    } | 
    Select-Object Name,@{ N = 'MemoryUsage'; E = { $_.Sum } }
}