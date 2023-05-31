Function Install-Splunk {
<#
.Synopsis
    Install the Splunk Forwarder.
.DESCRIPTION
    Install the Splunk Universal forwarder. 
.EXAMPLE
    Install-Splunk -ComputerName Comp1,Comp2,Comp3 -Installer C:\Path\To\Installer.msi -SplunkUsername user -SplunkPassword pass -DeploymentServer SplunkDeploy.domain.com:8089
#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ParameterType]
        [string[]]$ComputerName,
        [Parameter()]
        [ParameterType]
        [string]$Installer,
        [Parameter()]
        [ParameterType]
        [string]$SplunkUsername,
        [Parameter()]
        [ParameterType]
        [string]$SplunkPass,
        [Parameter()]
        [ParameterType]
        [string]$DeploymentServer
        
    )
    
    begin {}
    process {
        [ScriptBlock]$ScriptBlock = {
            param(
                $InstallerPath,
                $SplunkUsername,
                $SplunkPass,
                $DeploymentServer
            )

            $installerPath = "C:\temp\$InstallerPath"

            msiexec /i $InstallerPath AGREETOLICENSE=yes DEPLOYMENT_SERVER=$DeploymentServer SPLUNKUSERNAME=$SplunkUsername SPLUNKPASSWORD=$SplunkPass /quiet /L*v C:\Temp\Splunk_install.log
        }

        foreach ($Computer in $ComputerName) {
            $InstallerName = Split-Path $Installer -Leaf
            Copy-Item -Path $Installer -Destination \\$Computer\C$\temp\$InstallerName
            
            $s = New-PSSession -ComputerName $Computer
            Invoke-Command -Session $s -ScriptBlock $ScriptBlock -ArgumentList $InstallerName, $SplunkUsername, $SplunkPass, $DeploymentServer
            Remove-PSSession -Session $s
        }
    }
}
