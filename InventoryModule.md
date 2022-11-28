## Install VMWare Module

```powershell
Install-Module vmware.PowerCli -Scope CurrentUser -AllowClobber
```

## Inventory Module

Download inventory module.

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/KalebHawkins/powershell-modules/main/Inventory.psm1 -OutFile Inventory.psm1
```

Import inventory module.

```powershell
Import-Module ./Inventory.psm1
```

## Connect vCenter 

Connect to vCenter. 

```powershell
Connect-ViServer vcenter.domain.com -Credential $(Get-Credential) -Force
```

# Get Inventory

```powershell
Get-InventoryData -Prefix "FilePrefix"
```