# How to build an Ubuntu Linux kernel

## Requirements

* Ubuntu 22.04 LTS (Jammy Jellyfish)

* ~30GB free storage space

## 1. Install required packages

To install the required packages and build dependencies, run:

```bash
sudo apt update && \
    sudo apt build-dep -y linux linux-image-unsigned-$(uname -r) && \
    sudo apt install -y fakeroot llvm libncurses-dev dwarves
```

Some other packages that might be usefull:

```bash
sudo apt install -y git gawk flex bison openssl libssl-dev dkms autoconf \
    libelf-dev libudev-dev libpci-dev libiberty-dev
```

## 2. Clone the ipu4-next repo

```bash
git clone https://github.com/ruslanbay/ipu4-next

cd ipu4-next
```

## 3. Obtain the source for an Ubuntu release

### 3.1. Get local copy of kernel source

```bash
git clone -b Ubuntu-5.15.0-161.171 --single-branch --depth=1 \
    https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/jammy linux
```

### 3.2. Apply patches

```bash
cd linux

git am ../patches/*.patch
```

## 4. Prepare the kernel source

Run the following commands to ensure you have a clean build environment and the necessary scripts have execute permissions:

```bash
chmod a+x debian/scripts/* && \
    chmod a+x debian/scripts/misc/* && \
    fakeroot debian/rules clean
```

### Modify ABI number

You should modify the kernel version number to avoid conflicts and to differentiate the development kernel from the kernel released by Canonical.

To do so, modify the ABI number (the number after the dash following the kernel version) to “999” in the first line of the <kernel_source_working_directory>/debian.master/changelog file:

```bash
sed -i '1s/\(.*\)-\([0-9]\+\.\([0-9]\+\)\)/\1-999.\3/' debian.master/changelog
```

For example:

```
linux (5.15.0-999.171) jammy; urgency=medium
```

## 5. Modify kernel configuration

To enable or disable any features using the kernel configuration, run:

```bash
fakeroot debian/rules editconfigs
```

This will invoke the menuconfig interface for you to edit specific configuration files related to the Ubuntu kernel package. You will need to explicitly respond with Y or N when making any config changes to avoid getting errors later in the build process.

Choose the following:
```
Device Drivers > Multimedia support > Media drivers > Media PCI Adapters
- Intel IPU driver
  - intel ipu generation type (Compile for IPU4 driver)
    - (X) Compile for IPU4P driver
  - intel ipu hardware platform type (Compile for SOC)
    - (X) Compile for SOC
- Skeleton PCI V4L2 driver

Device Drivers > Multimedia support > Media ancillary drivers > Camera sensor devices
 - <M> CRL Module sensor support
```

## 6. Build the kernel

You are now ready to build the kernel.

```bash
fakeroot debian/rules clean && \
    fakeroot debian/rules binary
```

**Note**: *Run `fakeroot debian/rules clean` to clean the build environment each time before you recompile the kernel **after making any changes** to the kernel source or configuration.*

If the build is successful, several .deb binary package files will be produced in the directory one level above the kernel source working directory.

## 7. Install the new kernel

Install all the debian packages generated from the previous step (on your build system or a different target system with the same architecture) with dpkg -i and reboot:

```bash
cd ..

sudo dpkg -i linux-headers-*_all.deb \
    linux-headers-*.deb \
    linux-image-unsigned-*.deb \
    linux-modules-*.deb

sudo reboot
```

## 8. Test the new kernel

Run any necessary testing to confirm that your changes and customizations have taken effect. You should also confirm that the newly installed kernel version matches the value in the <kernel_source_working_directory>/debian.master/changelog file by running:

```bash
uname -r
```

## 9. Build and install the `libcamerahal` package

Follow the instructions provided in the [libcamerahal README](libcamerahal/README.md).

## 10. Build and install the `icamerasrc` package

Follow the instructions provided in the [icamerasrc README](icamerasrc/README.md).

# Some IPU4 devices

## Diff between IPU4 and IPU4P specifications

The Intel Image Processing Units (IPU4 and IPU4P) differ primarily by their associated hardware platforms and PCI Device IDs. The IPU4 (`8086:5a88`) is used in Celeron N3350/Pentium N4200/Atom E3900 series systems, while the IPU4P (`8086:8a19`) addresses all other compatible devices utilizing that specific ID. You can verify which unit you have by running `lspci -vvv -k -n`.

- IPU4 (PCI 8086:5a88): Celeron N3350/Pentium N4200/Atom E3900 Series Imaging Unit
- IPU4P (PCI 8086:8a19): For every other IPU4 devices with PCI Device ID 8a19


## Surface Pro 7

|||
|-|-|
|Image Signal Processor|IPU4|
|Front Sensor|OV5693|
|Front Sensor ACPI ID|INT33BE|
|Front Module|MSHW0190|
|Rear Sensor|OV8865|
|Rear Sensor ACPI ID|INT347A|
|Rear Module|MSHW0191|
|IR Sensor|OV7251|
|IR Sensor ACPI ID|INT347E|
|IR Module|MSHW0192|

```bash
lspci -vvv -k

00:05.0 Multimedia controller: Intel Corporation Image Signal Processor (rev 03)
	Subsystem: Intel Corporation Image Signal Processor
	Control: I/O- Mem+ BusMaster- SpecCycle- MemWINV- VGASnoop- ParErr- Stepping- SERR- FastB2B- DisINTx-
	Status: Cap+ 66MHz- UDF- FastB2B- ParErr- DEVSEL=fast >TAbort- <TAbort- <MAbort+ >SERR- <PERR- INTx-
	Interrupt: pin A routed to IRQ 16
	Region 0: Memory at 6000000000 (64-bit, non-prefetchable) [size=16M]
	Capabilities: <access denied>
	Kernel modules: intel_ipu4p, intel_ipu4p_isys, intel_ipu4p_psys
```

```bash
lspci -vvv -k -n

00:05.0 0480: 8086:8a19 (rev 03)
	Subsystem: 8086:7270
```

## Surface Book 3 13"

|||
|-|-|
|Image Signal Processor|IPU4|
|Front Sensor|OV5693|
|Front Sensor ACPI ID|INT33BE|
|Front Module|MSHW0210|
|Rear Sensor|OV8865|
|Rear Sensor ACPI ID|INT347A|
|Rear Module|MSHW0211|
|IR Sensor|OV7251|
|IR Sensor ACPI ID|INT347E|
|IR Module|MSHW0212|

## Surface Book 3 15"

|||
|-|-|
|Image Signal Processor|IPU4|
|Front Sensor|OV5693|
|Front Sensor ACPI ID|INT33BE|
|Front Sensor |
|Front Module|MSHW0200|
|Rear Sensor|OV8865|
|Rear Sensor ACPI ID|INT347A|
|Rear Module|MSHW0201|
|IR Sensor|OV7251|
|IR Sensor ACPI ID|INT347E|
|IR Module|MSHW0202|

## Surface Laptop 3 (Intel)

|||
|-|-|
|Image Signal Processor|IPU4|
|Front Sensor|OV9734|
|Front Sensor ACPI ID|OVTI9734|
|IR Sensor|OV7251|
|IR Sensor ACPI ID|INT347E|

# Links

1. [How to build an Ubuntu Linux kernel](https://canonical-kernel-docs.readthedocs-hosted.com/latest/how-to/develop-customise/build-kernel/#modify-kernel-configuration)
2. [How to obtain kernel source for an Ubuntu release using Git](https://canonical-kernel-docs.readthedocs-hosted.com/latest/how-to/source-code/obtain-kernel-source-git/)
3. https://github.com/intel/ipu4-cam-hal
4. https://github.com/intel/ipu4-icamerasrc
5. https://github.com/linux-surface/linux-surface/wiki/Camera-Support
