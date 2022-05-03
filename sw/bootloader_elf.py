#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : bootloader_elf.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 16.03.2022
# Last Modified Date: 03.05.2022
# Description       : Bootloader script to download binaries using the UART port
#                     for the Pixel SoC bootloader ROM
import serial
import argparse
import pathlib
import sys
import time
import glob
from tqdm import tqdm
from elftools.elf.elffile import ELFFile
from elftools.elf.sections import SymbolTableSection

default_serial = '/dev/tty.usbserial-210319A438821'
default_speed  = 115200
gpio_addr      = 'D0000000'
rst_ctrl       = 'C0000000'

def _start_seq(serial_p):
    ser = serial.Serial(serial_p['port'], serial_p['speed'], timeout=1)
    for i in range(10):
        led = 1<<i
        led = '{0:0>8x}'.format(led)
        data = bytes('w'+gpio_addr+'d'+led+'\r','UTF-8')
        # print(data)
        ser.write(data)
        time.sleep(0.02)
    data = bytes('\r','UTF-8')
    ser.write(data)
    data = bytes('w'+gpio_addr+'d00000092\r','UTF-8')
    ser.write(data)
    time.sleep(0.05)

def _end_seq(serial_p, rst_addr):
    with serial.Serial(serial_p['port'], serial_p['speed'], timeout=1) as ser:
        data = bytes('w'+gpio_addr+'d00000000\r','UTF-8')
        ser.write(data)
        time.sleep(0.01)
        data = bytes('w'+rst_ctrl+'d'+rst_addr+'\r','UTF-8')
        ser.write(data)
        print('Reset address changed to: %s'%(rst_addr))
        time.sleep(0.01)

def _program(mem_addr, data, serial_p):
    with serial.Serial(serial_p['port'], serial_p['speed'], timeout=1) as ser:
        print('Burst mode [ON]')
        f_mode = bytes('f'+mem_addr+'\r', encoding='utf8')
        ser.write(f_mode)
        time.sleep(0.01)
        for idx,word in enumerate(tqdm(data)):
            ser.write(word)
            # print(word)
            time.sleep(0.001)
        print('Burst mode [OFF]')
        data = bytes('e\r','UTF-8')
        ser.write(data)
        time.sleep(0.001)
    print('Transfer completed!')

def _fmt_data(data, size_file, size_mem):
    byte_list = []
    # File size = Real data in the ELF
    # Mem size = Total data size in the memory
    # If they differ it's because we have zeroed data in the memory
    if (size_file != 0):
        for i in range(0,size_file,4):
            word_int  = data[i+3]<<24|data[i+2]<<16|data[i+1]<<8|data[i]
            word_str  = '{0:0>8x}'.format(word_int)
            byte_list.append(bytes('@'+word_str+'\r','UTF-8'))

    if size_file != size_mem:
        for i in range(0,size_mem,4):
            byte_list.append(bytes('@00000000\r','UTF-8'))
    return byte_list

def _transfer_program(elf, serial_p):
    print('Processing elf file:', elf)
    _start_seq(serial_p)
    with open(elf, 'rb') as f:
        elffile = ELFFile(f)
        # Check the elf attr. like machine/class
        if elffile.elfclass != 32 or elffile.get_machine_arch() != 'RISC-V':
            print('[Error] ELF file is not a RISC-V program')
            print('%s: elfclass is %s' % (elf, elffile.elfclass))
            print('%s: elfmachine is %s' % (elf, elffile.get_machine_arch()))
            sys.exit(1)

        entry_point = '{0:0>8x}'.format(elffile.header['e_entry'])
        print('Entry point / Reset addr: %s' % entry_point)
        for idx,segment in enumerate(elffile.iter_segments()):
            seg_info = {}
            seg_info['type']=segment.header.p_type
            seg_info['vaddr']='{0:0>8x}'.format(segment.header.p_vaddr)
            seg_info['paddr']='{0:0>8x}'.format(segment.header.p_paddr)
            seg_info['filesz']=segment.header.p_filesz
            seg_info['memsz']=segment.header.p_memsz

            print('---Segment [%d] info:---'%idx)
            print('1) Type: %s'%seg_info['type'])
            print('2) Virtual addr: %s'%seg_info['vaddr'])
            print('3) Physical addr: %s'%seg_info['paddr'])
            print('4) File size: %d bytes'%seg_info['filesz'])
            print('5) Mem size: %d bytes'%seg_info['memsz'])

            if segment.header.p_filesz != segment.header.p_memsz:
                print('Contain uninitialized data segment (.bss/.sbss/...)')

            if (seg_info['type'] == 'PT_LOAD') and (seg_info['filesz'] != 0):
                print('Loading %d bytes in the location %s...'%(seg_info['filesz'],seg_info['vaddr']))
                ready_to_send = _fmt_data(segment.data(), seg_info['filesz'], seg_info['memsz'])
                _program(seg_info['vaddr'], ready_to_send, serial_p)
            elif (seg_info['type'] == 'PT_LOAD') and (seg_info['filesz'] == 0):
                print('Zeroing %d bytes in the location %s...'%(seg_info['memsz'],seg_info['vaddr']))
                ready_to_send = _fmt_data(segment.data(), seg_info['filesz'], seg_info['memsz'])
                _program(seg_info['vaddr'], ready_to_send, serial_p)
        _end_seq(serial_p, entry_point)
        print('All segments are programmed!, please press the reset button')

def _serial_ports():
    """ Lists serial port names

        :raises EnvironmentError:
            On unsupported or unknown platforms
        :returns:
            A list of the serial ports available on the system
    """
    if sys.platform.startswith('win'):
        ports = ['COM%s' % (i + 1) for i in range(256)]
    elif sys.platform.startswith('linux') or sys.platform.startswith('cygwin'):
        # this excludes your current terminal "/dev/tty"
        ports = glob.glob('/dev/ttyUSB*') # ubuntu is /dev/ttyUSB0
    elif sys.platform.startswith('darwin'):
        ports = glob.glob('/dev/tty.*')
    else:
        raise EnvironmentError('Unsupported platform')

    result = []
    for port in ports:
        try:
            s = serial.Serial(port)
            s.close()
            result.append(port)
        except serial.SerialException as e:
            if e.errno == 13:
                raise e
            pass
        except OSError:
            pass
    return result

def _check_serial(serial_p):
    devices = _serial_ports()
    if serial_p['port'] in devices:
        print('USB device found')
        try:
            ser = serial.Serial(serial_p['port'], serial_p['speed'], timeout=10)
            return True
        except serial.serialutil.SerialException as err:
            raise err
            return False
        return True
    else:
        print('USB device not found or busy, please choose one in the list of available ones:')
        print(devices)

def main():
    parser = argparse.ArgumentParser(
        description='UART Bootloader script'
    )
    parser.add_argument('--elf',
                        nargs='?',
                        type=pathlib.Path,
                        default=sys.stdin)
    parser.add_argument('--device',
                        nargs='?',
                        type=str,
                        default=default_serial)
    parser.add_argument('--speed',
                        nargs='?',
                        type=int,
                        default=default_speed)
    args = parser.parse_args()

    serial_p = {}
    serial_p['port']  = args.device
    serial_p['speed'] = args.speed

    if _check_serial(serial_p):
        _transfer_program(args.elf, serial_p)

if __name__ == '__main__':
    main()
