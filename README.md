# Powershell vCenter Modules

The modules in this repository offer convenient functionality for vCenter operations.

## Prerequisites

These modules do require you to have the `vmware.Powercli` module installed. It also requires that you are already connected to a vCenter server.

Any additional prerequisites are handled by script logic. For example `Get-InvetoryData` in the `inventory.psm1` module requires that the `ImportExcel` module is present and imported. The script logic will handle the installation and importing of that module.

To install the `vmware.Powercli` module.

```powershell
Install-Module vmware.Powercli -Scope CurrentUser -Confirm:$true
Import-Module VMware.VimAutomation.Core
```

To connect to vCenter use the following command.

```powershell
Connect-VIServer <vcenter.domain.com> -Credentials $(Get-Credential) -Force 
```

## Using Modules

To use modules from this repository you need to download and import them. For example, download the `inventory.psm1` file and import it like so. You will need to be in the directory you downloaded the file to perform the import.

```powershell
Import-Module ./inventory.psm1
```

