#!/usr/bin/env python3

import argparse
import binascii
import os
import select
import socket
import sys
from construct import *

usb_header_t = Struct(
    "channel" / Int16ub,
    "tag"     / Int8ub,
    "seq"     / Int16ub,
)

def recvall(s, size):
    """Receive a fix amount of data."""

    data = b''
    while len(data) < size:
        try:
            tmp = s.recv(size - len(data))
        except ConnectionResetError:
            raise ConnectionClosed
        if len(tmp) == 0:
            raise ConnectionClosed
        data += tmp
    return data

class USBProxy:
    def __init__(self, s, device='/dev/hidg0'):
        self.s = s
        self.device = device
        self.channel = 0x0101

    def usb_write(self, data):
        with open(self.device, 'wb') as fp:
            fp.write(data)

    def usb_read(self, size):
        with open(self.device, 'rb') as fp:
            data = fp.read(size)
        return data

    def recv_usb_packet(self, usb_seq):
        data = self.usb_read(64)
        print('[<]', binascii.hexlify(data))
        assert len(data) == 64

        header = usb_header_t.parse(data)

        # remember last channel in use
        self.channel = header.channel

        return data[usb_header_t.sizeof():]

    def recv_usb_full_payload(self):
        '''Receive a USB packet and return the embedded payload.'''

        usb_seq = 0
        payload = self.recv_usb_packet(usb_seq)

        # the payload size is the 2 first bytes
        size = int.from_bytes(payload[:2], 'big')
        payload = payload[2:]

        while len(payload) < size:
            print(len(payload), size)
            usb_seq += 1
            payload += self.recv_usb_packet(usb_seq)

        # strip padding
        payload = payload[:size]

        return payload

    def send_usb_packet(self, payload, usb_seq, channel):
        packet = b''
        packet += usb_header_t.build(dict(channel=channel, tag=0x05, seq=usb_seq))
        packet += payload

        if len(packet) < 64:
            while len(packet) % 64 != 0:
                packet += b'\x00'

        print('[>]', binascii.hexlify(packet), len(packet))

        self.usb_write(packet)

    def send_usb_full_payload(self, payload, channel=0x0101):
        size = len(payload)
        payload = size.to_bytes(2, 'big') + payload

        usb_seq = 0
        while payload:
            self.send_usb_packet(payload[:64-5], usb_seq, channel)
            usb_seq += 1
            payload = payload[64-5:]

    def send_tcp_data(self, packet):
        size = len(packet)
        packet = size.to_bytes(4, 'big') + packet
        #print('send socket', binascii.hexlify(packet))
        self.s.sendall(packet)

    def recv_tcp_data(self):
        data = recvall(self.s, 4)
        size = int.from_bytes(data, 'big')
        data = recvall(self.s, size + 2)
        return data

    def run(self):
        print('[*] running')
        while True:
            fpr = open(self.device, 'rb')
            l, _, _ = select.select([ self.s, fpr ], [], [])

            if fpr in l:
                fpr.close()
                data = self.recv_usb_full_payload()

                self.send_tcp_data(data)

            if self.s in l:
                data = self.recv_tcp_data()

                self.send_usb_full_payload(data, self.channel)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-d', '--device', default='/dev/hidg0', help='USB gadget device')
    parser.add_argument('-p', '--port', default=1237, help='SE proxy TCP port')
    args = parser.parse_args()

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('127.0.0.1', args.port))

    proxy = USBProxy(s, args.device)
    proxy.run()

    s.close()
