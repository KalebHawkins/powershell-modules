<#
 @ Copyright (c) 2022 Your Name
 @
 @Script: Get-Inv.ps1
 @Author: Kaleb Hawkins
 @Email: Kaleb_Hawkins@na.honda.com
 @Create At: 2022-11-18 09:52:03
 @Last Modified By: Your Name
 @Last Modified At: 2022-11-18 11:07:57
 @Description: Collect an inventory of vCenter infrastructure. Along with CPU, memory, and storage overcommitment information.  
#>


function Get-VMHostInventory {
<#
.SYNOPSIS
    Collect various VM host information.

.DESCRIPTION
   Collect various VM host information from each vCenter host. 

.EXAMPLE 
    Get-VMHostInventory

    Obtains Name, Parent Cluster, Version, Build, TimeZone, State, ConnectionState, Powerstate, Cpu information and memory information.
#>
    [CmdletBinding()]
    param ()
    begin {}
    process {
        Get-VMHost |  
        Select-Object Name, Parent, Version, Build, TimeZone, State, ConnectionState, Powerstate, 
            NumCpu, CpuTotalMhz, CpuUsageMhz, @{l="AvailableCpuMhz";e={$_.CpuTotalMhz - $_.CpuUsageMhz}}, 
            @{l="AvailableCpuCores";e={[Math]::Round(($_.CpuTotalMhz - $_.CpuUsageMhz) / $_.ExtensionData.summary.hardware.CpuMhz, 2)}},
            @{l="MemoryTotalGB";e={[Math]::Round($_.MemoryTotalGB, 2)}}, 
            @{l="MemoryUsageGB";e={[Math]::Round($_.MemoryUsageGB, 2)}}, 
            @{l="MemoryAvailableGB";e={[Math]::Round($_.MemoryTotalGB - $_.MemoryUsageGB, 2)}}
    }
    end {}
}

function Get-VMInventory {
<#
.SYNOPSIS
    Collect various virtual machine information.

.DESCRIPTION
   Collect various VM information from each vCenter virtual machine. 

.EXAMPLE 
    Get-VMInventory

    Obtains Name, Parent Host, Powerstate, Folder, ResourcePool, OperatingSystem, NumCPU, Memory, and Notes.
#>
    [CmdletBinding()]
    param ()
    begin {}
    process {
        Get-VM |  
        Select-Object Name, Powerstate, VMHost, Folder, ResourcePool, `
        @{l='OperatingSystem';e={$_.Guest.OSFullName}}, `
        NumCpu, CoresPerSocket, MemoryGB, Notes
    }
    end {}
}

function Get-VMHostInfo {
<#
.SYNOPSIS
    Collect VM host model information. 

.DESCRIPTION
   Collect various VM host model information from each vCenter host. 

.EXAMPLE 
    Get-VMHostInfo

    Obtains Name, CpuModel, CpuMhz, NumCpu, NumCpuCores, NumCpuThreads.
#>
    [CmdletBinding()]
    param ()
    
    begin {}
    process {
        Get-VMHost | Select-Object Name, @{l="Vendor";e={$_.ExtensionData.summary.Hardware.Vendor}},
                    @{l="Model";e={$_.ExtensionData.summary.hardware.CpuModel}},
                    @{l="CpuMhz";e={$_.ExtensionData.summary.hardware.CpuMhz}},
                    @{l="CpuSockets";e={$_.ExtensionData.summary.hardware.NumCpuPkgs}},
                    @{l="CpuCores";e={$_.ExtensionData.summary.hardware.NumCpuCores}},
                    @{l="CpuThreds";e={$_.ExtensionData.summary.hardware.NumCpuThreads}}
    }
    end {}
}

function Get-VMHostCPUOvercommit {
<#
.SYNOPSIS
    Collect CPU Overcommit information from hosts. 

.DESCRIPTION
   Collect CPU Overcommit information from each vmhost. 

.EXAMPLE 
    Get-VMHostCPUOvercommit

    Obtains CPU Overcommit stats from each VM host.
#>
    [CmdletBinding()]
    param ()
    begin {}
    process {
        foreach($VMHost in $(Get-VMHost)) {
            $vCPU = Get-VM -Location $VMHost | Measure-Object -Property NumCpu -Sum | Select-Object -ExpandProperty Sum
            $VMHost | Select-Object Name, Parent, @{l="PhysicalCpus";e={$_.NumCpu}}, @{l="vCPU";e={$vCPU}}, 
                        @{l="Ratio";e={[math]::Round($vCPU/$_.NumCpu,1)}}, 
                        @{l="CpuOvercommit%";e={[math]::Round(100*(($vCPU - $_.NumCpu) / $_.NumCpu), 1)}}
        }
    }
    end {}
}

function Get-VMHostMemoryOvercommit(){
<#
.SYNOPSIS
    Collect Memory Overcommit information from hosts. 

.DESCRIPTION
   Collect Memory Overcommit information from each vmhost. 

.EXAMPLE 
    Get-VMHostMemoryOvercommit

    Obtains Memory Overcommit stats from each VM host.
#>
    [CmdletBinding()]
    param ()
    
    begin {}
    process {
        foreach($VMHost in $(Get-VMHost)) {
            $vmMem = Get-VM -Location $VMHost | Measure-Object -Property MemoryGB -Sum | Select-Object -ExpandProperty Sum
            $VMHost | Select-Object Name, Parent, @{l="PhysicalMemory(GB)";e={$_.MemoryTotalGB}}, 
                        @{l="VMMemory";e={$vmMem}}, 
                        @{l="Ratio";e={[math]::Round($vmMem/$_.MemoryTotalGB,1)}}, 
                        @{l="CpuOvercommit%";e={[math]::Round(100*(($vmMem - $_.MemoryTotalGB) / $_.MemoryTotalGB), 1)}} 
        }
    }
    end {}
}

function Get-DataStoreInventory(){
    <#
    .SYNOPSIS
        Collect datastore information.
    
    .DESCRIPTION
       Collect datastore information.
    
    .EXAMPLE 
        Get-DataStoreInventory
    
        Obtains datastore information.
    #>
        [CmdletBinding()]
        param ()
        
        begin {}
        process {
            Get-DataStore | 
                Select-Object Name, FileSystemVersion, Datacenter, DatastoreBrowserPath, 
                    CapacityGB, FreeSpaceGb, @{l="UsedSpaceGb";e={$_.CapacityGB - $_.FreeSpaceGb }},
                    Accessible, Type, State, Id
        }
        end {}
    }

function Get-InventoryData {
<#
.SYNOPSIS
    Collect all vCenter inventory data. Optionally emailling a spreadsheet containing said data for analysis and review. 

.DESCRIPTION
   Collect all vCenter inventory data. Optionally emailling a spreadsheet containing said data for analysis and review. 

.EXAMPLE 
    Get-InventoryData -Prefix "vCenterData"
#>
    [CmdletBinding()]
    param (
        $Prefix
    )
    begin {
        if ($Prefix -eq "") { $Prefix = "InvData" }

        $ExcelModuleName = "ImportExcel"
        $ExcelModule = Get-Module -ListAvailable | Where-Object { $_.Name -eq $ExcelModuleName }
        if (!$ExcelModule) {
            Install-Module ImportExcel -Scope CurrentUser -Confirm:$True
        }
        Import-Module $ExcelModuleName

        $FileName = "$Prefix-$(Get-Date -Format "yyyy-MM-dd").xlsx"

        $HostInventory = Get-VMHostInventory
        $HostInfo = Get-VMHostInfo
        $HostCpuOvercommit = Get-VMHostCPUOvercommit
        $HostMemoryOvercommit = Get-VMHostMemoryOvercommit
        $VMInventory = Get-VMInventory
        $DataStoreInventory = Get-DataStoreInventory
    } 
    process {
        
        $HostInventory | Export-Excel $FileName -Worksheet "HostInventory" -TableName "HostInventory"
        $HostInfo | Export-Excel $FileName -Worksheet "HostInfo" -TableName "HostInfo"
        $HostCpuOvercommit | Export-Excel $FileName -Worksheet "HostCpuOvercommit" -TableName "HostCpuOvercommit"
        $HostMemoryOvercommit | Export-Excel $FileName -Worksheet "HostMemoryOvercommit" -TableName "HostMemoryOvercommit"
        $DataStoreInventory | Export-Excel $FileName -Worksheet "DataStoreInventory" -TableName "DataStoreInventory"

        $VMInventory | Export-Excel $FileName -Worksheet "VirtualMachineInventory" -TableName "VirtualMachineInventory"
    
        $operatingSystems = $VMInventory | Group-Object OperatingSystem | Select-Object Name, Count
        $operatingSystems | Export-Excel $FileName -WorksheetName "OperatingSystems" -IncludePivotChart -PivotRows Name -PivotData @{Count="Sum"} -ChartType PieExploded3D
    }
    end {}
}