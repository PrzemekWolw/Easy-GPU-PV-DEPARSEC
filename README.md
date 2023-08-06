# Simple-GPU-P
A work-in-progress project dedicated to making GPU Paravirtualization on Windows Hyper-V easier!

![](https://i.imgur.com/pRlwa4n.gif)

GPU-PV allows you to partition your systems dedicated or integrated GPU and assign it to several Hyper-V VMs.  It's the same technology that is used in WSL2, and Windows Sandbox.

Simple-GPU-P aims to make this easier by automating the steps required to get a GPU-PV VM up and running.
Simple-GPU-P does the following...
1. Allows managing GPUs in your VM
2. Adds GPU to existing VM
3. Updates Drivers in VM
4. Removes GPUs from VM
5. Changes allocation of your GPU

### Prerequisites:
* Windows 10 20H1+ Pro, Enterprise or Education OR Windows 11 Pro, Enterprise or Education.  Windows 11 on host and VM is preferred due to better compatibility.
* Desktop Computer with dedicated NVIDIA/AMD GPU or Integrated Intel GPU - Laptops with NVIDIA GPUs are not supported at this time, but Intel integrated GPUs work on laptops.  GPU must support hardware video encoding (NVIDIA NVENC, Intel Quicksync or AMD AMF).
* Latest GPU driver from Intel.com or NVIDIA.com, don't rely on Device manager or Windows update.
* Virtualisation enabled in the motherboard and [Hyper-V fully enabled](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v) on the Windows 10/ 11 OS (requires reboot).
* Allow Powershell scripts to run on your system - typically by running "Set-ExecutionPolicy unrestricted" in Powershell running as Administrator.

### Instructions
1. Make sure your system meets the prerequisites.
2. Download files from this repository
3. Use Generation 2 of VM
4. Install Windows on your VM
5. DISABLE dynamic memory
6. DISABLE automatic snapshots
7. Run ```RUN-ME.BAT``` as Administrator
8. Follow the steps in command prompt
9. In Hyper-V settings enable enhanced session to add sound support

### Thanks to:
- [Hyper-ConvertImage](https://github.com/tabs-not-spaces/Hyper-ConvertImage) for creating an updated version of [Convert-WindowsImage](https://github.com/MicrosoftDocs/Virtualization-Documentation/tree/master/hyperv-tools/Convert-WindowsImage) that is compatible with Windows 10 and 11.
- [gawainXX](https://github.com/gawainXX) for help testing and pointing out bugs and feature improvements.

### Vulkan:
- Vulkan works on certain Hardware-software configurations
  ![](https://media.beamng.com/ch2on8x8rhtebHeS | width=100)

### Notes:
- Your GPU on the host will have a Microsoft driver in device manager, rather than an nvidia/intel/amd driver. As long as it doesn't have a yellow triangle over top of the device in device manager, it's working correctly.
- The screen may go black for times up to 10 seconds in situations when UAC prompts appear, applications go in and out of fullscreen and when you switch between video codecs in Parsec - not really sure why this happens, it's unique to GPU-P machines and seems to recover faster at 1280x720.
- If you do not have administrator permissions on the machine it means you set the username and vmname to the same thing, these needs to be different.
- AMD Polaris GPUS like the RX 580 do not support hardware video encoding via GPU Paravirtualization at this time.
- Linux Virtual Guests are not supported yet

### Original Project:
- Original Project is available [here.](https://github.com/jamesstringerparsec/Easy-GPU-PV)
