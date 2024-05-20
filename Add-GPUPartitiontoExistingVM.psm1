Function Add-GPUPartitiontoExistingVM {
    param(
    [string]$VMName,
    [string]$GPUName,
    [string]$Hostname = $ENV:COMPUTERNAME,
    [decimal]$GPUResourceAllocationPercentage
    )

    Import-Module $PSSCriptRoot\Add-VMGpuPartitionAdapterFiles.psm1

    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $CurrentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

    $VM = Get-VM -VMName $VMName
    $VHD = Get-VHD -VMId $VM.VMId

    If ($VM.state -eq "Running") {
        [bool]$state_was_running = $true
        }

    if ($VM.state -ne "Off"){
        "Attemping to shutdown VM..."
        Stop-VM -Name $VMName -Force
        }

    While ($VM.State -ne "Off") {
        Start-Sleep -s 3
        "Waiting for VM to shutdown - make sure there are no unsaved documents..."
        }

    "Adding VM GPU Partition..."
    $PartitionableGPUList = Get-WmiObject -Class "Msvm_PartitionableGpu" -ComputerName $env:COMPUTERNAME -Namespace "ROOT\virtualization\v2"
    if ($GPUName -eq "AUTO" -or [Environment]::OSVersion.Version.Build -lt 22000) {
        $DevicePathName = $PartitionableGPUList.Name[0]
        Add-VMGpuPartitionAdapter -VMName $VMName
        }
    else {
        $DeviceID = ((Get-WmiObject Win32_PNPSignedDriver | where {($_.Devicename -eq "$GPUNAME")}).hardwareid).split('\')[1]
        $DevicePathName = ($PartitionableGPUList | Where-Object name -like "*$deviceid*").Name
        Add-VMGpuPartitionAdapter -VMName $VMName -InstancePath $DevicePathName
        }
    [float]$devider = [math]::round($(100 / $GPUResourceAllocationPercentage),2)
    Set-VMGpuPartitionAdapter -VMName $VMName -MinPartitionVRAM ([math]::round($(1000000000 / $devider))) -MaxPartitionVRAM ([math]::round($(1000000000 / $devider))) -OptimalPartitionVRAM ([math]::round($(1000000000 / $devider)))
    Set-VMGPUPartitionAdapter -VMName $VMName -MinPartitionEncode ([math]::round($(18446744073709551615 / $devider))) -MaxPartitionEncode ([math]::round($(18446744073709551615 / $devider))) -OptimalPartitionEncode ([math]::round($(18446744073709551615 / $devider)))
    Set-VMGpuPartitionAdapter -VMName $VMName -MinPartitionDecode ([math]::round($(1000000000 / $devider))) -MaxPartitionDecode ([math]::round($(1000000000 / $devider))) -OptimalPartitionDecode ([math]::round($(1000000000 / $devider)))
    Set-VMGpuPartitionAdapter -VMName $VMName -MinPartitionCompute ([math]::round($(1000000000 / $devider))) -MaxPartitionCompute ([math]::round($(1000000000 / $devider))) -OptimalPartitionCompute ([math]::round($(1000000000 / $devider)))
    Set-VM -GuestControlledCacheTypes $true -VMName $VMName
    Set-VM -LowMemoryMappedIoSpace 1Gb -VMName $VMName
    Set-VM -HighMemoryMappedIoSpace 32GB -VMName $VMName

    if ($VHD -is [array]) {
        $DiskPath = $VHD.Path[0]
    } else {
        $DiskPath = $VHD.Path
    }

    "Mounting Drive..."
    $DriveLetter = (Mount-VHD -Path $DiskPath -PassThru | Get-Disk | Get-Partition | Get-Volume | Where-Object {$_.DriveLetter  -and $_.FileSystemType -eq "NTFS"} | ForEach-Object DriveLetter)

    if (-Not $DriveLetter) {
        'Drive is not mounted'
        Read-Host -Prompt "Press Enter to Exit"
    }

    "Copying GPU Files - this could take a while..."
    Add-VMGPUPartitionAdapterFiles -hostname $Hostname -DriveLetter $DriveLetter -GPUName $GPUName

    "Dismounting Drive..."
    Dismount-VHD -Path $DiskPath

    If ($state_was_running){
        "Previous State was running so starting VM..."
        Start-VM $VMName
        }

    "Done..."
}
