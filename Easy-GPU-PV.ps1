#Easier script for adding, updating, removing GPUs from Hyper-V machines
#Make sure to enabled ehanced session to enable audio support...

[int]$choice = Read-Host -Prompt 'What do you want to do:
1. Add GPU to Existing Virtual Machine
2. Update GPU Drivers in Virtual Machine
3. Remove GPU from Virtual Machine
4. Change GPU Allocation'

if ($choice -eq 1) {
    "Adding GPU to VM"
    Import-Module $PSSCriptRoot\Add-GPUPartitiontoExistingVM.psm1

    "Checking for available GPUs"
    Function Get-DesktopPC
    {
     $isDesktop = $true
     if(Get-WmiObject -Class win32_systemenclosure | Where-Object { $_.chassistypes -eq 9 -or $_.chassistypes -eq 10 -or $_.chassistypes -eq 14})
       {
       Write-Warning "Thunderbolt 3 or 4 dock based GPU's may work"
       $isDesktop = $false }
     if (Get-WmiObject -Class win32_battery)
       { $isDesktop = $false }
     $isDesktop
    }

    Function Get-WindowsCompatibleOS {
    $build = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    if ($build.CurrentBuild -ge 19041 -and ($($build.editionid -like 'Professional*') -or $($build.editionid -like 'Enterprise*') -or $($build.editionid -like 'Education*'))) {
        Return $true
        }
    Else {
        Write-Warning "Only Windows 10 20H1 or Windows 11 (Pro or Enterprise) is supported"
        Return $false
        }
    }


    Function Get-HyperVEnabled {
    if (Get-WindowsOptionalFeature -Online | Where-Object FeatureName -Like 'Microsoft-Hyper-V-All'){
        Return $true
        }
    Else {
        Write-Warning "You need to enable Virtualisation in your motherboard and then add the Hyper-V Windows Feature and reboot"
        Return $false
        }
    }

    Function Get-WSLEnabled {
        if ((wsl -l -v)[2].length -gt 1 ) {
            Write-Warning "WSL is Enabled. This may interferre with GPU-P and produce an error 43 in the VM"
            Return $true
            }
        Else {
            Return $false
            }
    }

    Function Get-VMGpuPartitionAdapterFriendlyName {
        $Devices = (Get-WmiObject -Class "Msvm_PartitionableGpu" -ComputerName $env:COMPUTERNAME -Namespace "ROOT\virtualization\v2").name
        Foreach ($GPU in $Devices) {
            $GPUParse = $GPU.Split('#')[1]
            Get-WmiObject Win32_PNPSignedDriver | where {($_.HardwareID -eq "PCI\$GPUParse")} | select DeviceName -ExpandProperty DeviceName
            }
    }

    If ((Get-DesktopPC) -and  (Get-WindowsCompatibleOS) -and (Get-HyperVEnabled)) {
        "System Compatible"
        $build = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
        if ($build.CurrentBuild -ge 22000) {
            $gpuTable = @{}
            $gpuOut = Get-VMGpuPartitionAdapterFriendlyName
            $count = 0
            ForEach ($line in $($gpuOut -split "`r`n"))
            {
                $count = $count + 1
                $gpuTable.Add($count, $Line)
            }
            "Select GPU you want to attach to VM"
            $count = 0
            ForEach ($key in $gpuTable.keys)
            {
                $message = '{0}. {1}' -f $key, $gpuTable[$key]
                Write-Output $message
            }
            [int]$selection = Read-Host -Prompt 'GPU: '
            if ($gpuTable.ContainsKey($selection)) {
                [string]$selectedGpu = '{1}' -f $selection, $gpuTable[$selection]
                "Selected GPU: $selectedGpu"

                "Checking for available virtual machines"
                $vmTable = @{}
                $GetVM = Get-VM
                $count = 0
                ForEach ($line in $($GetVM -split "`r`n"))
                {
                    $count = $count + 1
                    $line = $line.replace("VirtualMachine (Name = '","").replace("') ","").replace("[","") -replace ('Id = .*', '')
                    $vmTable.Add($count, $Line)
                }
                "Select Virtual Machine"
                $count = 0
                ForEach ($key in $vmTable.keys)
                {
                    $message = '{0}. {1}' -f $key, $vmTable[$key]
                    Write-Output $message
                }
                [int]$selection = Read-Host -Prompt 'Virtual Machine: '
                if ($vmTable.ContainsKey($selection)) {
                    [string]$selectedVM = '{1}' -f $selection, $vmTable[$selection]
                    "Selected VM: $selectedVM"
                    [int]$perc = Read-Host -Prompt 'Enter GPU Allocation Percentage: '
                    Add-GPUPartitiontoExistingVM -VMName $selectedVM -GPUName $selectedGpu -Hostname $ENV:Computername -GPUResourceAllocationPercentage $perc
                }
                else {
                    'This VM does not exists'
                    Read-Host -Prompt "Press Enter to Exit"
                }
              }
            else {
                'This GPU does not exists'
                Read-Host -Prompt "Press Enter to Exit"
            }
        }
        else {
            $selectedGpu = 'AUTO'
            "Windows 10 Detected"
            "Selected GPU: $selectedGpu"

            "Checking for available virtual machines"
            $vmTable = @{}
            $GetVM = Get-VM
            $count = 0
            ForEach ($line in $($GetVM -split "`r`n"))
            {
                $count = $count + 1
                $line = $line.replace("VirtualMachine (Name = '","").replace("') ","").replace("[","") -replace ('Id = .*', '')
                $vmTable.Add($count, $Line)
            }
            "Select Virtual Machine"
            $count = 0
            ForEach ($key in $vmTable.keys)
            {
                $message = '{0}. {1}' -f $key, $vmTable[$key]
                Write-Output $message
            }
            [int]$selection = Read-Host -Prompt 'Virtual Machine: '
            if ($vmTable.ContainsKey($selection)) {
                [string]$selectedVM = '{1}' -f $selection, $vmTable[$selection]
                "Selected VM: $selectedVM"
                [int]$perc = Read-Host -Prompt 'Enter GPU Allocation Percentage: '
                Add-GPUPartitiontoExistingVM -VMName $selectedVM -GPUName $selectedGpu -Hostname $ENV:Computername -GPUResourceAllocationPercentage $perc
            }
            else {
                'This VM does not exists'
                Read-Host -Prompt "Press Enter to Exit"
            }
        }
    }
    else {
    Read-Host -Prompt "Press Enter to Exit"
    }
}
if ($choice -eq 2) {
    "Updating Drivers in VM"
    Import-Module $PSSCriptRoot\Update-VMGpuPartitionDriver.psm1

    "Checking for available GPUs"
    Function Get-DesktopPC
    {
     $isDesktop = $true
     if(Get-WmiObject -Class win32_systemenclosure | Where-Object { $_.chassistypes -eq 9 -or $_.chassistypes -eq 10 -or $_.chassistypes -eq 14})
       {
       Write-Warning "Thunderbolt 3 or 4 dock based GPU's may work"
       $isDesktop = $false }
     if (Get-WmiObject -Class win32_battery)
       { $isDesktop = $false }
     $isDesktop
    }

    Function Get-WindowsCompatibleOS {
    $build = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    if ($build.CurrentBuild -ge 19041 -and ($($build.editionid -like 'Professional*') -or $($build.editionid -like 'Enterprise*') -or $($build.editionid -like 'Education*'))) {
        Return $true
        }
    Else {
        Write-Warning "Only Windows 10 20H1 or Windows 11 (Pro or Enterprise) is supported"
        Return $false
        }
    }


    Function Get-HyperVEnabled {
    if (Get-WindowsOptionalFeature -Online | Where-Object FeatureName -Like 'Microsoft-Hyper-V-All'){
        Return $true
        }
    Else {
        Write-Warning "You need to enable Virtualisation in your motherboard and then add the Hyper-V Windows Feature and reboot"
        Return $false
        }
    }

    Function Get-WSLEnabled {
        if ((wsl -l -v)[2].length -gt 1 ) {
            Write-Warning "WSL is Enabled. This may interferre with GPU-P and produce an error 43 in the VM"
            Return $true
            }
        Else {
            Return $false
            }
    }

    Function Get-VMGpuPartitionAdapterFriendlyName {
        $Devices = (Get-WmiObject -Class "Msvm_PartitionableGpu" -ComputerName $env:COMPUTERNAME -Namespace "ROOT\virtualization\v2").name
        Foreach ($GPU in $Devices) {
            $GPUParse = $GPU.Split('#')[1]
            Get-WmiObject Win32_PNPSignedDriver | where {($_.HardwareID -eq "PCI\$GPUParse")} | select DeviceName -ExpandProperty DeviceName
            }
    }

    If ((Get-DesktopPC) -and  (Get-WindowsCompatibleOS) -and (Get-HyperVEnabled)) {
        "System Compatible"
        $build = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
            if ($build.CurrentBuild -ge 22000) {
            $gpuTable = @{}
            $gpuOut = Get-VMGpuPartitionAdapterFriendlyName
            $count = 0
            ForEach ($line in $($gpuOut -split "`r`n"))
            {
                $count = $count + 1
                $gpuTable.Add($count, $Line)
            }
            "Select GPU you want to attach to VM"
            $count = 0
            ForEach ($key in $gpuTable.keys)
            {
                $message = '{0}. {1}' -f $key, $gpuTable[$key]
                Write-Output $message
            }
            [int]$selection = Read-Host -Prompt 'GPU: '
            if ($gpuTable.ContainsKey($selection)) {
                [string]$selectedGpu = '{1}' -f $selection, $gpuTable[$selection]
                "Selected GPU: $selectedGpu"

                "Checking for available virtual machines"
                $vmTable = @{}
                $GetVM = Get-VM
                $count = 0
                ForEach ($line in $($GetVM -split "`r`n"))
                {
                    $count = $count + 1
                    $line = $line.replace("VirtualMachine (Name = '","").replace("') ","").replace("[","") -replace ('Id = .*', '')
                    $vmTable.Add($count, $Line)
                }
                "Select Virtual Machine"
                $count = 0
                ForEach ($key in $vmTable.keys)
                {
                    $message = '{0}. {1}' -f $key, $vmTable[$key]
                    Write-Output $message
                }
                [int]$selection = Read-Host -Prompt 'Virtual Machine: '
                if ($vmTable.ContainsKey($selection)) {
                    [string]$selectedVM = '{1}' -f $selection, $vmTable[$selection]
                    "Selected VM: $selectedVM"
                    Update-VMGpuPartitionDriver -VMName $selectedVM -GPUName $selectedGpu -Hostname $ENV:Computername
                }
                else {
                    'This VM does not exists'
                    Read-Host -Prompt "Press Enter to Exit"
                }
              }
            else {
                'This GPU does not exists'
                Read-Host -Prompt "Press Enter to Exit"
            }
        }
        else {
                $selectedGpu = 'AUTO'
                "Windows 10 Detected"
                "Selected GPU: $selectedGpu"
                "Checking for available virtual machines"
                $vmTable = @{}
                $GetVM = Get-VM
                $count = 0
                ForEach ($line in $($GetVM -split "`r`n"))
                {
                    $count = $count + 1
                    $line = $line.replace("VirtualMachine (Name = '","").replace("') ","").replace("[","") -replace ('Id = .*', '')
                    $vmTable.Add($count, $Line)
                }
                "Select Virtual Machine"
                $count = 0
                ForEach ($key in $vmTable.keys)
                {
                    $message = '{0}. {1}' -f $key, $vmTable[$key]
                    Write-Output $message
                }
                [int]$selection = Read-Host -Prompt 'Virtual Machine: '
                if ($vmTable.ContainsKey($selection)) {
                    [string]$selectedVM = '{1}' -f $selection, $vmTable[$selection]
                    "Selected VM: $selectedVM"
                    Update-VMGpuPartitionDriver -VMName $selectedVM -GPUName $selectedGpu -Hostname $ENV:Computername
                }
                else {
                    'This VM does not exists'
                    Read-Host -Prompt "Press Enter to Exit"
                }
        }
    }
    else {
    Read-Host -Prompt "Press Enter to Exit"
    }
}
if ($choice -eq 3) {
    "Removing GPUs from VM"
    "Checking for available virtual machines"
    $vmTable = @{}
    $GetVM = Get-VM
    $count = 0
    ForEach ($line in $($GetVM -split "`r`n"))
    {
        $count = $count + 1
        $line = $line.replace("VirtualMachine (Name = '","").replace("') ","").replace("[","") -replace ('Id = .*', '')
        $vmTable.Add($count, $Line)
    }
    "Select Virtual Machine"
    $count = 0
    ForEach ($key in $vmTable.keys)
    {
        $message = '{0}. {1}' -f $key, $vmTable[$key]
        Write-Output $message
    }
    [int]$selection = Read-Host -Prompt 'Virtual Machine: '
    if ($vmTable.ContainsKey($selection)) {
        [string]$selectedVM = '{1}' -f $selection, $vmTable[$selection]
        "Selected VM: $selectedVM"
        Remove-VMGpuPartitionAdapter -VMName $selectedVM
        "GPU Removed"
    }
    else {
        'This VM does not exists'
        Read-Host -Prompt "Press Enter to Exit"
    }
}
if ($choice -eq 4) {
    "Changing GPU Allocation"
    Import-Module $PSSCriptRoot\Resize-GPUAlloc.psm1
    "Checking for available virtual machines"
    $vmTable = @{}
    $GetVM = Get-VM
    $count = 0
    ForEach ($line in $($GetVM -split "`r`n"))
    {
        $count = $count + 1
        $line = $line.replace("VirtualMachine (Name = '","").replace("') ","").replace("[","") -replace ('Id = .*', '')
        $vmTable.Add($count, $Line)
    }
    "Select Virtual Machine"
    $count = 0
    ForEach ($key in $vmTable.keys)
    {
        $message = '{0}. {1}' -f $key, $vmTable[$key]
        Write-Output $message
    }
    [int]$selection = Read-Host -Prompt 'Virtual Machine: '
    if ($vmTable.ContainsKey($selection)) {
        [string]$selectedVM = '{1}' -f $selection, $vmTable[$selection]
        "Selected VM: $selectedVM"
        [int]$perc = Read-Host -Prompt 'Enter GPU Allocation Percentage: '
        Resize-GPUAlloc -VMName $selectedVM -GPUName -GPUResourceAllocationPercentage $perc
    }
    else {
        'This VM does not exists'
        Read-Host -Prompt "Press Enter to Exit"
    }
}