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

## 11. Known issues and workarounds

### Moduledata and library version mismatch

```
[    4.074538] intel-ipu4 intel-ipu: Moduledata and library version mismatch (20191030 != 20181222)
[    4.074652] intel-ipu4 intel-ipu: Invalid moduledata
[    4.074713] intel-ipu4 intel-ipu: Failed to validate cpd
[    4.074909] intel-ipu4: probe of intel-ipu failed with error -22
```

Workaround:

```bash
echo "options intel_ipu4p fw_version_check=0" | sudo tee /etc/modprobe.d/ipu4.conf

sudo systemctl reboot
```

## 12. Verification

![image](assets/media0-graph.png)

<details>
  <summary>
    <strong>
      journalctl -b | grep -Ei "ipu4|ov5693|int33"
    </strong>
  </summary>

```
kernel: intel_pmc_core INT33A1:00:  initialized
kernel: intel_pmc_core INT33A1:00: hash matches
kernel: acpi INT33A1:00: hash matches
kernel: intel-ipu4 intel-ipu: enabling device (0000 -> 0002)
kernel: intel-ipu4 intel-ipu: Device 0x8a19 (rev: 0x3)
kernel: intel-ipu4 intel-ipu: physical base address 0x6000000000
kernel: intel-ipu4 intel-ipu: mapped as: 0x0000000014a23ea5
kernel: intel-ipu4 intel-ipu: IPU in secure mode
kernel: intel-ipu4 intel-ipu: cpd file name: ipu4p_cpd.bin
kernel: intel-ipu4 intel-ipu: Moduledata version: 20191030, library version: 20181222
kernel: intel-ipu4 intel-ipu: CSS release: 20181222
kernel: intel-ipu4 intel-ipu: IPU driver verion 1.0
kernel: atomisp_ov5693: module is from the staging directory, the quality is unknown, you have been warned.
kernel: atomisp_ov5693: module is from the staging directory, the quality is unknown, you have been warned.
kernel: intel-ipu4-mmu intel-ipu4-mmu0: MMU: 1, allocated page for trash: 0x00000000ad999901
kernel: ov5693 i2c-INT33BE:00: Failed to find EFI variable INT33BE:00_I2CAddr
kernel: ov5693 i2c-INT33BE:00: I2CAddr: using default (-1)
kernel: ov5693 i2c-INT33BE:00: gmin: power management provided via regulator driver (i2c addr 0x00)
kernel: ov5693 i2c-INT33BE:00: gmin_subdev_add: ACPI path is \_SB.PCI0.I2C2.CAMF
kernel: ov5693 i2c-INT33BE:00: Failed to find EFI variable INT33BE:00_ClkSrc
kernel: ov5693 i2c-INT33BE:00: ClkSrc: using default (1)
kernel: ov5693 i2c-INT33BE:00: Failed to find EFI variable INT33BE:00_CsiPort
kernel: ov5693 i2c-INT33BE:00: CsiPort: using default (0)
kernel: ov5693 i2c-INT33BE:00: Failed to find EFI variable INT33BE:00_CsiLanes
kernel: ov5693 i2c-INT33BE:00: CsiLanes: using default (1)
kernel: ov5693 i2c-INT33BE:00: Failed to find EFI gmin variable gmin_V1P8GPIO
kernel: ov5693 i2c-INT33BE:00: V1P8GPIO: using default (-1)
kernel: ov5693 i2c-INT33BE:00: Failed to find EFI gmin variable gmin_V2P8GPIO
kernel: ov5693 i2c-INT33BE:00: V2P8GPIO: using default (-1)
kernel: ov5693 i2c-INT33BE:00: Failed to find EFI variable INT33BE:00_CamClk
kernel: ov5693 i2c-INT33BE:00: CamClk: using default (0)
kernel: ov5693 i2c-INT33BE:00: Failed to get clk from pmc_plt_clk_0: -2
kernel: ov5693 i2c-INT33BE:00: Couldn't set power mode for v1p2
kernel: ov5693 i2c-INT33BE:00: Couldn't set power mode for v1p2
kernel: ov5693 i2c-INT33BE:00: sensor power-up failed
kernel: ov5693 i2c-INT33BE:00: Couldn't set power mode for v1p2
kernel: ov5693 i2c-INT33BE:00: Couldn't set power mode for v1p2
kernel: ov5693 i2c-INT33BE:00: sensor power-up failed
kernel: ov5693 i2c-INT33BE:00: Couldn't set power mode for v1p2
kernel: ov5693 i2c-INT33BE:00: Couldn't set power mode for v1p2
kernel: ov5693 i2c-INT33BE:00: sensor power-up failed
kernel: ov5693 i2c-INT33BE:00: Couldn't set power mode for v1p2
kernel: ov5693 i2c-INT33BE:00: Couldn't set power mode for v1p2
kernel: ov5693 i2c-INT33BE:00: sensor power-up failed
kernel: ov5693 i2c-INT33BE:00: ov5693 power-up err.
kernel: ov5693 i2c-INT33BE:00: sensor power-gating failed
kernel: ov5693: probe of i2c-INT33BE:00 failed with error -22
kernel: intel-ipu4-mmu intel-ipu4-mmu0: mmu is not ready yet. skipping.
kernel: intel-ipu4-mmu intel-ipu4-mmu1: MMU: 0, allocated page for trash: 0x00000000a8afb73b
kernel: intel-ipu4-mmu intel-ipu4-mmu0: mmu is not ready yet. skipping.
kernel: intel-ipu4-mmu intel-ipu4-mmu0: iova trash buffer for MMUID: 1 is 4286578688
kernel: intel-ipu4-isys intel-ipu4-isys0: isys probe 0000000001566217 0000000001566217
kernel: intel-ipu4-isys intel-ipu4-isys0: Entity type for entity Intel IPU4 CSI-2 0 was not initialized!
kernel: intel-ipu4-isys intel-ipu4-isys0: Entity type for entity Intel IPU4 CSI-2 1 was not initialized!
kernel: intel-ipu4-isys intel-ipu4-isys0: Entity type for entity Intel IPU4 CSI-2 2 was not initialized!
kernel: intel-ipu4-mmu intel-ipu4-mmu1: mmu is not ready yet. skipping.
kernel: intel-ipu4 intel-ipu: Sending BOOT_LOAD to CSE
kernel: intel-ipu4-isys intel-ipu4-isys0: Entity type for entity Intel IPU4 CSI-2 3 was not initialized!
kernel: intel-ipu4-isys intel-ipu4-isys0: Entity type for entity Intel IPU4 CSI-2 4 was not initialized!
kernel: intel-ipu4-isys intel-ipu4-isys0: Entity type for entity Intel IPU4 CSI2 BE SOC was not initialized!
kernel: intel-ipu4-isys intel-ipu4-isys0: Entity type for entity Intel IPU4 CSI2 BE was not initialized!
kernel: intel-ipu4-isys intel-ipu4-isys0: Entity type for entity Intel IPU4 ISA was not initialized!
kernel: intel-ipu4-isys intel-ipu4-isys0: no subdevice info provided
kernel: intel-ipu4-mmu intel-ipu4-mmu1: iova trash buffer for MMUID: 0 is 4286578688
kernel: intel-ipu4-psys intel-ipu4-psys0: pkg_dir entry count:12
kernel: intel-ipu4-isys intel-ipu4-isys0: FW authentication failed
kernel: intel-ipu4 intel-ipu: Sending BOOT_LOAD to CSE
kernel: intel-ipu4 intel-ipu: expected resp: 0x1, IPC response: 0x220 
kernel: intel-ipu4 intel-ipu: CSE boot_load failed
kernel: intel-ipu4-isys intel-ipu4-isys0: FW authentication failed
kernel: intel-ipu4 intel-ipu: Sending BOOT_LOAD to CSE
kernel: intel-ipu4 intel-ipu: Sending AUTHENTICATE_RUN to CSE
kernel: intel-ipu4-psys intel-ipu4-psys0: psys probe minor: 0
```
</details></br>

<details>
  <summary>
    <strong>
      v4l2-ctl --list-devices
    </strong>
  </summary>

```
ipu4p (PCI:pci:intel-ipu):
	/dev/video0
	/dev/video1
	/dev/video2
	/dev/video3
	/dev/video4
	/dev/video5
	/dev/video6
	/dev/video7
	/dev/video8
	/dev/video9
	/dev/video10
	/dev/video11
	/dev/video12
	/dev/video13
	/dev/video14
	/dev/video15
	/dev/video16
	/dev/video17
	/dev/video18
	/dev/video19
	/dev/video20
	/dev/video21
	/dev/video22
	/dev/video23
	/dev/video24
	/dev/video25
	/dev/video26
	/dev/video27
	/dev/video28
	/dev/video29
	/dev/video30
	/dev/video31
	/dev/video32
	/dev/video33
	/dev/video34
	/dev/video35
	/dev/video36
	/dev/video37
	/dev/video38
	/dev/video39

ipu4p (pci:intel-ipu):
	/dev/media0
```
</details></br>

<details>
  <summary>
    <strong>
      modinfo intel_ipu4p
    </strong>
  </summary>

```
filename:       /lib/modules/5.15.0-999-generic/kernel/drivers/media/pci/intel/ipu4/intel-ipu4p.ko
description:    Intel ipu pci driver
license:        GPL
author:         Intel
author:         Kun Jiang <kun.jiang@intel.com>
author:         Xia Wu <xia.wu@intel.com>
author:         Leifu Zhao <leifu.zhao@intel.com>
author:         Zaikuo Wang <zaikuo.wang@intel.com>
author:         Yunliang Ding <yunliang.ding@intel.com>
author:         Bingbu Cao <bingbu.cao@intel.com>
author:         Renwei Wu <renwei.wu@intel.com>
author:         Tianshu Qiu <tian.shu.qiu@intel.com>
author:         Jianxu Zheng <jian.xu.zheng@intel.com>
author:         Samu Onkalo <samu.onkalo@intel.com>
author:         Antti Laakso <antti.laakso@intel.com>
author:         Jouni Högander <jouni.hogander@intel.com>
author:         Sakari Ailus <sakari.ailus@linux.intel.com>
description:    Intel ipu mmu driver
license:        GPL
author:         Samu Onkalo <samu.onkalo@intel.com>
author:         Sakari Ailus <sakari.ailus@linux.intel.com>
description:    Intel ipu trace support
license:        GPL
author:         Samu Onkalo <samu.onkalo@intel.com>
description:    Intel ipu fw comm library
license:        GPL
srcversion:     F9275B0CF37EC7DDDE4EDF3
alias:          pci:v00008086d00008A19sv*sd*bc*sc*i*
depends:        
retpoline:      Y
intree:         Y
name:           intel_ipu4p
vermagic:       5.15.0-999-generic SMP mod_unload modversions 
sig_id:         PKCS#7
signer:         Build time autogenerated kernel key
sig_key:        65:A5:F2:6A:C2:20:B4:A2:23:AA:0F:84:4F:D5:F7:71:DA:3F:B6:1E
sig_hashalgo:   sha512
signature:      43:48:BA:D1:D3:DB:46:09:17:41:DB:EA:6E:A8:F2:5B:CA:72:D1:A0:
		18:D9:EA:AC:75:F4:E4:56:4C:44:80:3B:15:8E:84:5B:07:AC:C6:69:
		A1:2D:BB:0D:F6:8E:E4:70:2F:AB:53:BC:D9:40:B9:0E:0C:E0:65:93:
		8D:9B:06:15:70:93:E2:54:5A:03:62:61:BB:8D:C7:17:2D:AA:8A:CC:
		E4:0A:A1:1E:BF:B7:38:C6:16:D9:AB:73:2D:B9:C5:C1:FF:13:81:50:
		81:48:2B:1F:B1:0C:C5:E0:7F:78:EC:4F:2F:9D:9C:F2:2D:29:25:84:
		8F:59:4D:19:41:BA:89:EA:3B:17:BE:83:41:77:CC:16:0C:AA:2E:49:
		76:A6:F0:D9:37:B0:D5:AB:61:88:4A:69:90:24:D9:FB:C2:98:74:0C:
		3E:72:70:2D:00:FE:F0:01:21:BE:AB:6E:6C:BA:05:CE:C7:9F:A5:7D:
		2E:CD:4D:3B:AF:4C:0B:41:9A:FB:D5:53:F2:B4:8D:5A:8B:0C:12:7A:
		B4:A3:9A:A1:2F:00:4C:37:E9:51:61:FE:26:81:65:A3:D7:AD:20:8A:
		EF:BA:DF:55:25:1B:0A:9D:88:BB:0B:1A:BA:3D:EC:E9:57:91:8F:76:
		21:86:94:BA:08:6E:05:2C:61:E4:DB:35:0A:36:14:1D:AB:B0:0D:74:
		BB:1F:E3:1C:58:BD:1B:FE:4C:57:8B:B5:AA:40:22:5A:F8:C1:22:FF:
		9A:C6:87:D7:90:43:E2:3F:32:B0:F9:39:D3:19:B7:A1:66:CE:A1:4A:
		35:C7:6E:5D:F2:A1:EF:7F:95:A2:81:AB:39:02:DA:6D:86:83:69:77:
		74:F3:8B:6A:90:E8:DA:0D:D0:33:9E:B5:5B:4B:5E:1E:B8:E2:77:01:
		1B:0A:CE:F9:6C:9C:DF:EA:B3:63:E3:3E:A3:AB:BA:1D:AD:9D:C4:34:
		76:56:E4:72:09:9F:60:8D:21:6C:2E:B9:BF:FC:85:82:51:7B:66:82:
		76:78:05:F9:64:67:B2:80:7F:CF:53:6D:0D:1C:E9:84:2D:EF:5F:03:
		87:8B:9E:47:E3:59:F9:BB:7A:49:8D:42:C9:97:84:65:D9:34:D3:00:
		36:C1:5A:12:2D:15:CE:69:01:5E:EB:CC:DC:DE:7E:67:D7:06:D2:24:
		17:AE:B6:ED:E5:46:C5:77:02:B8:E1:6B:4E:0C:EF:0B:37:58:B9:E4:
		F3:77:D4:2A:8E:3A:EA:12:5B:5F:DC:49:E2:CB:72:5F:F3:42:16:1F:
		23:0A:86:B9:76:39:BD:30:3D:F8:B0:59:16:53:C6:48:74:A9:D5:23:
		03:11:F8:28:EE:23:B2:63:4C:57:00:E1
parm:           fw_version_check:enable/disable checking firmware version (bool)
parm:           secure_mode_enable:bool
parm:           secure_mode:IPU secure mode enable
```
</details></br>

<details>
  <summary>
    <strong>
      lsmod | grep -Ei "ipu4|ov5693|int33"
    </strong>
  </summary>

```
intel_ipu4p_psys       65536  0
intel_ipu4p_psys_csslib   139264  1 intel_ipu4p_psys
intel_ipu4p_isys      163840  0
intel_ipu4p_isys_csslib    65536  1 intel_ipu4p_isys
videobuf2_dma_contig    24576  1 intel_ipu4p_isys
videobuf2_v4l2         32768  1 intel_ipu4p_isys
videobuf2_common       73728  4 videobuf2_dma_contig,videobuf2_v4l2,intel_ipu4p_isys,videobuf2_memops
atomisp_ov5693         36864  0
atomisp_gmin_platform    40960  1 atomisp_ov5693
intel_ipu4p           106496  4 intel_ipu4p_psys,intel_ipu4p_isys
videodev              258048  4 videobuf2_v4l2,videobuf2_common,intel_ipu4p_isys,atomisp_ov5693
mc                     65536  5 videodev,videobuf2_v4l2,videobuf2_common,intel_ipu4p_isys,atomisp_ov5693
```
</details></br>

<details>
  <summary>
    <strong>
      bash ./scripts/libcamera-info.sh
    </strong>
  </summary>

```
v4l-subdev0: Intel IPU4 CSI-2 0
v4l-subdev1: Intel IPU4 CSI-2 1
v4l-subdev2: Intel IPU4 CSI-2 2
v4l-subdev3: Intel IPU4 CSI-2 3
v4l-subdev4: Intel IPU4 CSI-2 4
v4l-subdev5: Intel IPU4 TPG 0
v4l-subdev6: Intel IPU4 TPG 1
v4l-subdev7: Intel IPU4 CSI2 BE SOC
v4l-subdev8: Intel IPU4 CSI2 BE
v4l-subdev9: Intel IPU4 ISA
video0: Intel IPU4 CSI-2 0 capture 0
video1: Intel IPU4 CSI-2 0 capture 1
video2: Intel IPU4 CSI-2 0 capture 2
video3: Intel IPU4 CSI-2 0 capture 3
video4: Intel IPU4 CSI-2 0 meta
video5: Intel IPU4 CSI-2 1 capture 0
video6: Intel IPU4 CSI-2 1 capture 1
video7: Intel IPU4 CSI-2 1 capture 2
video8: Intel IPU4 CSI-2 1 capture 3
video9: Intel IPU4 CSI-2 1 meta
video10: Intel IPU4 CSI-2 2 capture 0
video11: Intel IPU4 CSI-2 2 capture 1
video12: Intel IPU4 CSI-2 2 capture 2
video13: Intel IPU4 CSI-2 2 capture 3
video14: Intel IPU4 CSI-2 2 meta
video15: Intel IPU4 CSI-2 3 capture 0
video16: Intel IPU4 CSI-2 3 capture 1
video17: Intel IPU4 CSI-2 3 capture 2
video18: Intel IPU4 CSI-2 3 capture 3
video19: Intel IPU4 CSI-2 3 meta
video20: Intel IPU4 CSI-2 4 capture 0
video21: Intel IPU4 CSI-2 4 capture 1
video22: Intel IPU4 CSI-2 4 capture 2
video23: Intel IPU4 CSI-2 4 capture 3
video24: Intel IPU4 CSI-2 4 meta
video25: Intel IPU4 TPG 0 capture
video26: Intel IPU4 TPG 1 capture
video27: Intel IPU4 BE SOC capture 0
video28: Intel IPU4 BE SOC capture 1
video29: Intel IPU4 BE SOC capture 2
video30: Intel IPU4 BE SOC capture 3
video31: Intel IPU4 BE SOC capture 4
video32: Intel IPU4 BE SOC capture 5
video33: Intel IPU4 BE SOC capture 6
video34: Intel IPU4 BE SOC capture 7
video35: Intel IPU4 CSI2 BE capture
video36: Intel IPU4 ISA capture
video37: Intel IPU4 ISA config
video38: Intel IPU4 ISA 3A stats
video39: Intel IPU4 ISA scaled capture

media0: ipu4p

Media controller API version 5.15.189

Media device information
------------------------
driver          intel-ipu4-isys
model           ipu4p
serial          
bus info        pci:intel-ipu
hw revision     0x0
driver version  5.15.189

Device topology
- entity 1: Intel IPU4 CSI-2 0 (6 pads, 41 links)
            type V4L2 subdev subtype Unknown flags 0
            device node name /dev/v4l-subdev0
	pad0: Sink
		[fmt:Y10_1X10/4096x3072 field:none]
	pad1: Source
		[fmt:Y10_1X10/4096x3072 field:none]
		-> "Intel IPU4 CSI-2 0 capture 0":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad2: Source
		[fmt:unknown/0x0]
		-> "Intel IPU4 CSI-2 0 capture 1":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad3: Source
		[fmt:unknown/0x0]
		-> "Intel IPU4 CSI-2 0 capture 2":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad4: Source
		[fmt:unknown/0x0]
		-> "Intel IPU4 CSI-2 0 capture 3":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad5: Source
		-> "Intel IPU4 CSI-2 0 meta":0 []

- entity 8: Intel IPU4 CSI-2 0 capture 0 (1 pad, 1 link)
            type Node subtype V4L flags 0
            device node name /dev/video0
	pad0: Sink
		<- "Intel IPU4 CSI-2 0":1 []

- entity 14: Intel IPU4 CSI-2 0 capture 1 (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video1
	pad0: Sink
		<- "Intel IPU4 CSI-2 0":2 []

- entity 20: Intel IPU4 CSI-2 0 capture 2 (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video2
	pad0: Sink
		<- "Intel IPU4 CSI-2 0":3 []

- entity 26: Intel IPU4 CSI-2 0 capture 3 (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video3
	pad0: Sink
		<- "Intel IPU4 CSI-2 0":4 []

- entity 32: Intel IPU4 CSI-2 0 meta (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video4
	pad0: Sink
		<- "Intel IPU4 CSI-2 0":5 []

- entity 38: Intel IPU4 CSI-2 1 (6 pads, 41 links)
             type V4L2 subdev subtype Unknown flags 0
             device node name /dev/v4l-subdev1
	pad0: Sink
		[fmt:Y10_1X10/4096x3072 field:none]
	pad1: Source
		[fmt:Y10_1X10/4096x3072 field:none]
		-> "Intel IPU4 CSI-2 1 capture 0":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad2: Source
		[fmt:unknown/0x0]
		-> "Intel IPU4 CSI-2 1 capture 1":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad3: Source
		[fmt:unknown/0x0]
		-> "Intel IPU4 CSI-2 1 capture 2":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad4: Source
		[fmt:unknown/0x0]
		-> "Intel IPU4 CSI-2 1 capture 3":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad5: Source
		-> "Intel IPU4 CSI-2 1 meta":0 []

- entity 45: Intel IPU4 CSI-2 1 capture 0 (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video5
	pad0: Sink
		<- "Intel IPU4 CSI-2 1":1 []

- entity 51: Intel IPU4 CSI-2 1 capture 1 (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video6
	pad0: Sink
		<- "Intel IPU4 CSI-2 1":2 []

- entity 57: Intel IPU4 CSI-2 1 capture 2 (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video7
	pad0: Sink
		<- "Intel IPU4 CSI-2 1":3 []

- entity 63: Intel IPU4 CSI-2 1 capture 3 (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video8
	pad0: Sink
		<- "Intel IPU4 CSI-2 1":4 []

- entity 69: Intel IPU4 CSI-2 1 meta (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video9
	pad0: Sink
		<- "Intel IPU4 CSI-2 1":5 []

- entity 75: Intel IPU4 CSI-2 2 (6 pads, 41 links)
             type V4L2 subdev subtype Unknown flags 0
             device node name /dev/v4l-subdev2
	pad0: Sink
		[fmt:Y10_1X10/4096x3072 field:none]
	pad1: Source
		[fmt:Y10_1X10/4096x3072 field:none]
		-> "Intel IPU4 CSI-2 2 capture 0":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad2: Source
		[fmt:unknown/0x0]
		-> "Intel IPU4 CSI-2 2 capture 1":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad3: Source
		[fmt:unknown/0x0]
		-> "Intel IPU4 CSI-2 2 capture 2":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad4: Source
		[fmt:unknown/0x0]
		-> "Intel IPU4 CSI-2 2 capture 3":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad5: Source
		-> "Intel IPU4 CSI-2 2 meta":0 []

- entity 82: Intel IPU4 CSI-2 2 capture 0 (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video10
	pad0: Sink
		<- "Intel IPU4 CSI-2 2":1 []

- entity 88: Intel IPU4 CSI-2 2 capture 1 (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video11
	pad0: Sink
		<- "Intel IPU4 CSI-2 2":2 []

- entity 94: Intel IPU4 CSI-2 2 capture 2 (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video12
	pad0: Sink
		<- "Intel IPU4 CSI-2 2":3 []

- entity 100: Intel IPU4 CSI-2 2 capture 3 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video13
	pad0: Sink
		<- "Intel IPU4 CSI-2 2":4 []

- entity 106: Intel IPU4 CSI-2 2 meta (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video14
	pad0: Sink
		<- "Intel IPU4 CSI-2 2":5 []

- entity 112: Intel IPU4 CSI-2 3 (6 pads, 41 links)
              type V4L2 subdev subtype Unknown flags 0
              device node name /dev/v4l-subdev3
	pad0: Sink
		[fmt:Y10_1X10/4096x3072 field:none]
	pad1: Source
		[fmt:Y10_1X10/4096x3072 field:none]
		-> "Intel IPU4 CSI-2 3 capture 0":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad2: Source
		[fmt:unknown/0x0]
		-> "Intel IPU4 CSI-2 3 capture 1":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad3: Source
		[fmt:unknown/0x0]
		-> "Intel IPU4 CSI-2 3 capture 2":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad4: Source
		[fmt:unknown/0x0]
		-> "Intel IPU4 CSI-2 3 capture 3":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad5: Source
		-> "Intel IPU4 CSI-2 3 meta":0 []

- entity 119: Intel IPU4 CSI-2 3 capture 0 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video15
	pad0: Sink
		<- "Intel IPU4 CSI-2 3":1 []

- entity 125: Intel IPU4 CSI-2 3 capture 1 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video16
	pad0: Sink
		<- "Intel IPU4 CSI-2 3":2 []

- entity 131: Intel IPU4 CSI-2 3 capture 2 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video17
	pad0: Sink
		<- "Intel IPU4 CSI-2 3":3 []

- entity 137: Intel IPU4 CSI-2 3 capture 3 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video18
	pad0: Sink
		<- "Intel IPU4 CSI-2 3":4 []

- entity 143: Intel IPU4 CSI-2 3 meta (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video19
	pad0: Sink
		<- "Intel IPU4 CSI-2 3":5 []

- entity 149: Intel IPU4 CSI-2 4 (6 pads, 41 links)
              type V4L2 subdev subtype Unknown flags 0
              device node name /dev/v4l-subdev4
	pad0: Sink
		[fmt:Y10_1X10/4096x3072 field:none]
	pad1: Source
		[fmt:Y10_1X10/4096x3072 field:none]
		-> "Intel IPU4 CSI-2 4 capture 0":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad2: Source
		[fmt:unknown/0x0]
		-> "Intel IPU4 CSI-2 4 capture 1":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad3: Source
		[fmt:unknown/0x0]
		-> "Intel IPU4 CSI-2 4 capture 2":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad4: Source
		[fmt:unknown/0x0]
		-> "Intel IPU4 CSI-2 4 capture 3":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]
	pad5: Source
		-> "Intel IPU4 CSI-2 4 meta":0 []

- entity 156: Intel IPU4 CSI-2 4 capture 0 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video20
	pad0: Sink
		<- "Intel IPU4 CSI-2 4":1 []

- entity 162: Intel IPU4 CSI-2 4 capture 1 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video21
	pad0: Sink
		<- "Intel IPU4 CSI-2 4":2 []

- entity 168: Intel IPU4 CSI-2 4 capture 2 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video22
	pad0: Sink
		<- "Intel IPU4 CSI-2 4":3 []

- entity 174: Intel IPU4 CSI-2 4 capture 3 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video23
	pad0: Sink
		<- "Intel IPU4 CSI-2 4":4 []

- entity 180: Intel IPU4 CSI-2 4 meta (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video24
	pad0: Sink
		<- "Intel IPU4 CSI-2 4":5 []

- entity 186: Intel IPU4 TPG 0 (1 pad, 10 links)
              type V4L2 subdev subtype Sensor flags 0
              device node name /dev/v4l-subdev5
	pad0: Source
		[fmt:SBGGR8_1X8/4096x3072 field:none]
		-> "Intel IPU4 TPG 0 capture":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]

- entity 188: Intel IPU4 TPG 0 capture (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video25
	pad0: Sink
		<- "Intel IPU4 TPG 0":0 []

- entity 194: Intel IPU4 TPG 1 (1 pad, 10 links)
              type V4L2 subdev subtype Sensor flags 0
              device node name /dev/v4l-subdev6
	pad0: Source
		[fmt:SBGGR8_1X8/4096x3072 field:none]
		-> "Intel IPU4 TPG 1 capture":0 []
		-> "Intel IPU4 CSI2 BE":0 []
		-> "Intel IPU4 CSI2 BE SOC":0 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":1 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":2 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":3 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":4 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":5 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":6 [DYNAMIC]
		-> "Intel IPU4 CSI2 BE SOC":7 [DYNAMIC]

- entity 196: Intel IPU4 TPG 1 capture (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video26
	pad0: Sink
		<- "Intel IPU4 TPG 1":0 []

- entity 202: Intel IPU4 CSI2 BE SOC (16 pads, 184 links)
              type V4L2 subdev subtype Unknown flags 0
              device node name /dev/v4l-subdev7
	pad0: Sink
		[fmt:Y10_1X10/4096x3072 field:none]
		<- "Intel IPU4 CSI-2 0":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":4 [DYNAMIC]
		<- "Intel IPU4 TPG 0":0 [DYNAMIC]
		<- "Intel IPU4 TPG 1":0 [DYNAMIC]
	pad1: Sink
		[fmt:Y10_1X10/4096x3072 field:none]
		<- "Intel IPU4 CSI-2 0":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":4 [DYNAMIC]
		<- "Intel IPU4 TPG 0":0 [DYNAMIC]
		<- "Intel IPU4 TPG 1":0 [DYNAMIC]
	pad2: Sink
		[fmt:Y10_1X10/4096x3072 field:none]
		<- "Intel IPU4 CSI-2 0":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":4 [DYNAMIC]
		<- "Intel IPU4 TPG 0":0 [DYNAMIC]
		<- "Intel IPU4 TPG 1":0 [DYNAMIC]
	pad3: Sink
		[fmt:Y10_1X10/4096x3072 field:none]
		<- "Intel IPU4 CSI-2 0":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":4 [DYNAMIC]
		<- "Intel IPU4 TPG 0":0 [DYNAMIC]
		<- "Intel IPU4 TPG 1":0 [DYNAMIC]
	pad4: Sink
		[fmt:Y10_1X10/4096x3072 field:none]
		<- "Intel IPU4 CSI-2 0":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":4 [DYNAMIC]
		<- "Intel IPU4 TPG 0":0 [DYNAMIC]
		<- "Intel IPU4 TPG 1":0 [DYNAMIC]
	pad5: Sink
		[fmt:Y10_1X10/4096x3072 field:none]
		<- "Intel IPU4 CSI-2 0":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":4 [DYNAMIC]
		<- "Intel IPU4 TPG 0":0 [DYNAMIC]
		<- "Intel IPU4 TPG 1":0 [DYNAMIC]
	pad6: Sink
		[fmt:Y10_1X10/4096x3072 field:none]
		<- "Intel IPU4 CSI-2 0":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":4 [DYNAMIC]
		<- "Intel IPU4 TPG 0":0 [DYNAMIC]
		<- "Intel IPU4 TPG 1":0 [DYNAMIC]
	pad7: Sink
		[fmt:Y10_1X10/4096x3072 field:none]
		<- "Intel IPU4 CSI-2 0":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 0":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 1":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 2":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 3":4 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":1 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":2 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":3 [DYNAMIC]
		<- "Intel IPU4 CSI-2 4":4 [DYNAMIC]
		<- "Intel IPU4 TPG 0":0 [DYNAMIC]
		<- "Intel IPU4 TPG 1":0 [DYNAMIC]
	pad8: Source
		[fmt:unknown/0x0
		 crop:(0,0)/0x0]
		-> "Intel IPU4 BE SOC capture 0":0 [DYNAMIC]
	pad9: Source
		[fmt:unknown/0x0
		 crop:(0,0)/0x0]
		-> "Intel IPU4 BE SOC capture 1":0 [DYNAMIC]
	pad10: Source
		[fmt:unknown/0x0
		 crop:(0,0)/0x0]
		-> "Intel IPU4 BE SOC capture 2":0 [DYNAMIC]
	pad11: Source
		[fmt:unknown/0x0
		 crop:(0,0)/0x0]
		-> "Intel IPU4 BE SOC capture 3":0 [DYNAMIC]
	pad12: Source
		[fmt:unknown/0x0
		 crop:(0,0)/0x0]
		-> "Intel IPU4 BE SOC capture 4":0 [DYNAMIC]
	pad13: Source
		[fmt:unknown/0x0
		 crop:(0,0)/0x0]
		-> "Intel IPU4 BE SOC capture 5":0 [DYNAMIC]
	pad14: Source
		[fmt:unknown/0x0
		 crop:(0,0)/0x0]
		-> "Intel IPU4 BE SOC capture 6":0 [DYNAMIC]
	pad15: Source
		[fmt:unknown/0x0
		 crop:(0,0)/0x0]
		-> "Intel IPU4 BE SOC capture 7":0 [DYNAMIC]

- entity 219: Intel IPU4 BE SOC capture 0 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video27
	pad0: Sink
		<- "Intel IPU4 CSI2 BE SOC":8 [DYNAMIC]

- entity 225: Intel IPU4 BE SOC capture 1 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video28
	pad0: Sink
		<- "Intel IPU4 CSI2 BE SOC":9 [DYNAMIC]

- entity 231: Intel IPU4 BE SOC capture 2 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video29
	pad0: Sink
		<- "Intel IPU4 CSI2 BE SOC":10 [DYNAMIC]

- entity 237: Intel IPU4 BE SOC capture 3 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video30
	pad0: Sink
		<- "Intel IPU4 CSI2 BE SOC":11 [DYNAMIC]

- entity 243: Intel IPU4 BE SOC capture 4 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video31
	pad0: Sink
		<- "Intel IPU4 CSI2 BE SOC":12 [DYNAMIC]

- entity 249: Intel IPU4 BE SOC capture 5 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video32
	pad0: Sink
		<- "Intel IPU4 CSI2 BE SOC":13 [DYNAMIC]

- entity 255: Intel IPU4 BE SOC capture 6 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video33
	pad0: Sink
		<- "Intel IPU4 CSI2 BE SOC":14 [DYNAMIC]

- entity 261: Intel IPU4 BE SOC capture 7 (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video34
	pad0: Sink
		<- "Intel IPU4 CSI2 BE SOC":15 [DYNAMIC]

- entity 267: Intel IPU4 CSI2 BE (2 pads, 24 links)
              type V4L2 subdev subtype Unknown flags 0
              device node name /dev/v4l-subdev8
	pad0: Sink
		[fmt:SBGGR14_1X14/4096x3072 field:none]
		<- "Intel IPU4 CSI-2 0":1 []
		<- "Intel IPU4 CSI-2 0":2 []
		<- "Intel IPU4 CSI-2 0":3 []
		<- "Intel IPU4 CSI-2 0":4 []
		<- "Intel IPU4 CSI-2 1":1 []
		<- "Intel IPU4 CSI-2 1":2 []
		<- "Intel IPU4 CSI-2 1":3 []
		<- "Intel IPU4 CSI-2 1":4 []
		<- "Intel IPU4 CSI-2 2":1 []
		<- "Intel IPU4 CSI-2 2":2 []
		<- "Intel IPU4 CSI-2 2":3 []
		<- "Intel IPU4 CSI-2 2":4 []
		<- "Intel IPU4 CSI-2 3":1 []
		<- "Intel IPU4 CSI-2 3":2 []
		<- "Intel IPU4 CSI-2 3":3 []
		<- "Intel IPU4 CSI-2 3":4 []
		<- "Intel IPU4 CSI-2 4":1 []
		<- "Intel IPU4 CSI-2 4":2 []
		<- "Intel IPU4 CSI-2 4":3 []
		<- "Intel IPU4 CSI-2 4":4 []
		<- "Intel IPU4 TPG 0":0 []
		<- "Intel IPU4 TPG 1":0 []
	pad1: Source
		[fmt:SBGGR14_1X14/4096x3072 field:none
		 crop:(0,0)/4096x3072]
		-> "Intel IPU4 CSI2 BE capture":0 []
		-> "Intel IPU4 ISA":0 []

- entity 270: Intel IPU4 CSI2 BE capture (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video35
	pad0: Sink
		<- "Intel IPU4 CSI2 BE":1 []

- entity 276: Intel IPU4 ISA (5 pads, 5 links)
              type V4L2 subdev subtype Unknown flags 0
              device node name /dev/v4l-subdev9
	pad0: Sink
		[fmt:SBGGR14_1X14/4096x3072 field:none]
		<- "Intel IPU4 CSI2 BE":1 []
	pad1: Source
		[fmt:SBGGR12_1X12/4096x3072 field:none
		 crop:(0,0)/4096x3072]
		-> "Intel IPU4 ISA capture":0 []
	pad2: Sink
		[fmt:FIXED/0x0]
		<- "Intel IPU4 ISA config":0 []
	pad3: Source
		[fmt:FIXED/0x0]
		-> "Intel IPU4 ISA 3A stats":0 []
	pad4: Source
		[fmt:SBGGR12_1X12/4096x3072 field:none
		 crop:(0,0)/4096x3072
		 compose:(0,0)/4096x3072]
		-> "Intel IPU4 ISA scaled capture":0 []

- entity 282: Intel IPU4 ISA capture (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video36
	pad0: Sink
		<- "Intel IPU4 ISA":1 []

- entity 288: Intel IPU4 ISA config (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video37
	pad0: Source
		-> "Intel IPU4 ISA":2 []

- entity 294: Intel IPU4 ISA 3A stats (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video38
	pad0: Sink
		<- "Intel IPU4 ISA":3 []

- entity 300: Intel IPU4 ISA scaled capture (1 pad, 1 link)
              type Node subtype V4L flags 0
              device node name /dev/video39
	pad0: Sink
		<- "Intel IPU4 ISA":4 []
```
</details></br>

# Some IPU4 devices

## Diff between IPU4 and IPU4P specifications

The Intel Image Processing Units (IPU4 and IPU4P) differ primarily by their associated hardware platforms and PCI Device IDs. The IPU4 (`8086:5a88`) is used in Celeron N3350/Pentium N4200/Atom E3900 series systems, while the IPU4P (`8086:8a19`) addresses all other compatible devices utilizing that specific ID. You can verify which unit you have by running `lspci -vvv -k -n`.

- IPU4 (PCI 8086:5a88): Celeron N3350/Pentium N4200/Atom E3900 Series Imaging Unit
- IPU4P (PCI 8086:8a19): For every other IPU4 devices with PCI Device ID 8a19


## Surface Pro 7

|||
|-|-|
|Image Signal Processor|IPU4P|
|PCI Device ID|8086:8a19|
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
|Image Signal Processor||
|PCI Device ID||
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
|Image Signal Processor||
|PCI Device ID||
|Front Sensor|OV5693|
|Front Sensor ACPI ID|INT33BE|
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
|Image Signal Processor||
|PCI Device ID||
|Front Sensor|OV9734|
|Front Sensor ACPI ID|OVTI9734|
|IR Sensor|OV7251|
|IR Sensor ACPI ID|INT347E|

## Dell XPS 13 7390 2-in-1

|||
|-|-|
|Image Signal Processor|IPU4P|
|PCI Device ID|8086:8a19|
|Front Sensor|OV5693|
|Front Sensor ACPI ID|INT33BE|

# Links

1. [How to build an Ubuntu Linux kernel](https://canonical-kernel-docs.readthedocs-hosted.com/latest/how-to/develop-customise/build-kernel/#modify-kernel-configuration)
2. [How to obtain kernel source for an Ubuntu release using Git](https://canonical-kernel-docs.readthedocs-hosted.com/latest/how-to/source-code/obtain-kernel-source-git/)
3. https://github.com/intel/ipu4-cam-hal
4. https://github.com/intel/ipu4-icamerasrc
5. https://github.com/linux-surface/linux-surface/wiki/Camera-Support
6. https://wiki.ubuntu.com/Dell/XPS/XPS-13-7390-2-in-1#Camera
