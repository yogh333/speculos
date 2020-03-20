#!/bin/bash

set -e

configfs='/sys/kernel/config/usb_gadget'
g='nanos'
d="${configfs}/${g}"
c='c.1'
func='hid.usb1'
func2='hid.usb0'
func3='hid.usb2'

function stop()
{
    echo "" > "${d}/UDC"

    rm "${d}/configs/${c}/${func}"
    rm "${d}/configs/${c}/${func2}"
    #rm "${d}/configs/${c}/${func3}"

    rmdir "${d}/strings/0x409/"

    rmdir "${d}/configs/${c}/strings/0x409"
    rmdir "${d}/configs/${c}"
    rmdir "${d}/functions/${func}"
    rmdir "${d}/functions/${func2}"
    #rmdir "${d}/functions/${func3}"
    rmdir "${d}"
}

function start()
{
    mkdir -p "${d}/"

    echo 0x2c97 > "${d}/idVendor"
    echo 0x0001 > "${d}/idProduct"
    echo 0x0200 > "${d}/bcdDevice" # v1.0.0
    echo 0x0200 > "${d}/bcdUSB" # USB2

    mkdir -p "${d}/strings/0x409/"
    echo "0001" > "${d}/strings/0x409/serialnumber"
    echo "Ledger" > "${d}/strings/0x409/manufacturer"
    echo "Nano S" > "${d}/strings/0x409/product"

    # multifunction gadget
    echo 0x00 > "${d}/bDeviceClass"
    echo 0x00 > "${d}/bDeviceSubClass"
    echo 0x00 > "${d}/bDeviceProtocol"

    # general config
    mkdir -p "${d}/configs/${c}/"
    mkdir -p "${d}/configs/${c}/strings/0x409"
    echo "Nano S" > "${d}/configs/${c}/strings/0x409/configuration"
    echo 100 > "${d}/configs/${c}/MaxPower"

    ####################################################################
    # func 1: ?
    ####################################################################

    #mkdir -p "${d}/functions/${func}/"
    #echo 0 > "${d}/functions/${func}/protocol"
    #echo 0 > "${d}/functions/${func}/subclass"
    #echo 64 > "${d}/functions/${func}/report_length"
    #python3 -c "import binascii, sys; sys.stdout.buffer.write(binascii.unhexlify('12 01 10 02 00 00 00 40 97 2C 11 10 00 02 01 02 03 01'.replace(' ', '')))" > "${d}/functions/${func}/report_desc"
    #ln -s "${d}/functions/${func}" "${d}/configs/${c}"

    mkdir -p "${d}/functions/${func}/"
    echo 1 > "${d}/functions/${func}/protocol"
    echo 1 > "${d}/functions/${func}/subclass"
    echo 64 > "${d}/functions/${func}/report_length"
    python3 -c "import binascii, sys; sys.stdout.buffer.write(binascii.unhexlify('06 A0 FF 09 01 A1 01 09 03 15 00 26 FF 00 75 08 95 40 81 08 09 04 15 00 26 FF 00 75 08 95 40 91 08 C0'.replace(' ', '')))" > "${d}/functions/${func}/report_desc"
    ln -s "${d}/functions/${func}" "${d}/configs/${c}"

    ####################################################################
    # func 2: Keyboard from usbhid-dump
    ####################################################################

    mkdir -p "${d}/functions/${func2}/"
    echo 1 > "${d}/functions/${func2}/protocol"
    echo 1 > "${d}/functions/${func2}/subclass"
    echo 64 > "${d}/functions/${func2}/report_length"
    python3 -c "import binascii, sys; sys.stdout.buffer.write(binascii.unhexlify('06 A0 FF 09 01 A1 01 09 03 15 00 26 FF 00 75 08 95 40 81 08 09 04 15 00 26 FF 00 75 08 95 40 91 08 C0'.replace(' ', '')))" > "${d}/functions/${func2}/report_desc"
    ln -s "${d}/functions/${func2}" "${d}/configs/${c}"

    ####################################################################
    # func 3: WebUSB?
    ####################################################################

    #mkdir -p "${d}/functions/${func3}/"
    # XXX: class webusb 0xff
    #echo 0xff > "${d}/functions/${func3}/protocol"
    #echo 0xff > "${d}/functions/${func3}/subclass"
    #echo 64 > "${d}/functions/${func3}/report_length"
    #python3 -c "import binascii, sys; sys.stdout.buffer.write(binascii.unhexlify('09 '.replace(' ', '')))" > "${d}/functions/${func3}/report_desc"
    #ln -s "${d}/functions/${func3}" "${d}/configs/${c}"

    # requires the dummy_hdc Linux kernel module

    ls /sys/class/udc
    echo 'dummy_udc.0' > "${d}/UDC"

    ls -l /dev/hidg0
}


if [ "$1" = "start" ]; then
    start
elif [ "$1" = "stop" ]; then
    stop
else
    echo "Usage: $0 (start | stop)"
fi
