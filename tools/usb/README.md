## Usage

Insert the required modules:

```
sudo modprobe libcomposite
sudo modprobe dummy_hcd
```

Create the USB gadget:

```
sudo setup.sh start
```

Run the proxy

```
sudo ./usb-proxy.py
```


## Requirements

A few Linux kernel modules are required:

- `libcomposite`: should be packaged in Ubuntu (at least in 18.04)
- `dummy_hcd`: needs to be built...


### dummy_hcd build

For the rest of the build, let's assume the kernel version is the following one:

```
$ uname -r
4.15.0-65-generic
```

Install current Linux headers:

```
sudo apt-get install linux-headers-$(uname -r)
```

Ensure that apt is configured to download package sources (if not, add the line
below):

```
$ grep ^deb-src /etc/apt/sources.list
deb-src http://fr.archive.ubuntu.com/ubuntu/ bionic main restricted
```

Install current Linux kernel sources:

```
mkdir build/
cd build/
apt-get source linux-source-4.15.0
```

Build:

```
cd linux-4.15.0/

cp -v /usr/src/linux-headers-$(uname -r)/Module.symvers .
cp /boot/config-`uname -r` .config

make menuconfig
# Device Drivers > USB support > USB Gadget Support > USB Peripheral Controller > Dummy HCD
make EXTRAVERSION=-65-generic prepare
make EXTRAVERSION=-65-generic scripts
make EXTRAVERSION=-65-generic -j 4 M=drivers/usb/gadget/udc/
```

On my distro, kernel modules need to be signed:
```
sudo /usr/src/linux-headers-`uname -r`/scripts/sign-file sha256 ~/vm/secureboot/MOK.priv ~/vm/secureboot/MOK.der drivers/usb/gadget/udc/dummy_hcd.ko
```

Eventually, insert the module:

```
sudo insmod drivers/usb/gadget/udc/dummy_hcd.ko
```

A new device should be available in `/sys/class/udc`:

```
$ ls -l /sys/class/udc
total 0
lrwxrwxrwx 1 root root 0 oct.  17 13:17 dummy_udc.0 -> ../../devices/platform/dummy_udc.0/udc/dummy_udc.0
```

### Issues and workaround

#### Invalid module format

If the following error is encountered during the insertion of the module:

```
insmod: ERROR: could not insert module dummy_hcd.ko: Invalid module format
```

the version of module probably differs from the current Linux version. In the
following example, `vermagic` is invalid and should be `4.15.0-65-generic`:

```
$ modinfo drivers/usb/gadget/udc/dummy_hcd.ko | grep ver_magic
vermagic:       4.15.17-65-generic SMP mod_unload
$ uname -r
4.15.0-65-generic
```

The minor version in `Makefile` should be patched to match `uname -r`:

```
SUBLEVEL = 0
```

and the build restarted:

```
make EXTRAVERSION=-65-generic prepare
make EXTRAVERSION=-65-generic scripts
make EXTRAVERSION=-65-generic -j 4 M=drivers/usb/gadget/udc/
```
