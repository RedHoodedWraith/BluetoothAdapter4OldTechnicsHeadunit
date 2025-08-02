# Headunit Emulator

## Introduction
The purpose of the emulator is to be able to control the playback of Bluetooth audio by using the built-in controls of the Technics CQ-LQ1051A headunit (or other compatible headunit) by pretending to be a Panasonic CD Changer. Communication between the microcontroller and the headunit is done via [SPI Communication](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface).

This part of the project is based on the information and code examples provided by Kristoffer Sjöberg and Steve Hennerley. See [Panasonic_CD_Changer_Emulator_Info.md](Panasonic_CD_Changer_Emulator_Info.md) and the example [Arduino code](cd_changer_emulator.txt) for more information. These resources are provided as a redundancy should the original site be offline.

The reason why information on a Panasonic CD Changer emulator is used is because Technics is owned by Panasonic since 1965 and all the CD Changers pictured with this headunit on the internet seem to be Panasonic branded.

## The DIN Connector Mapping
```
Pin 1 = CD-C data line. (you need to transfer the bytes on this line)
Pin 2 = CD-C clock	(you need to keep a 8uS clock signal on this line 4us on 4us off)
Pin 3 = Acc		(not required for comms) Note to self: Supply voltage (12V unreg)
Pin 4 = CD-C strobe	(you need to send a 4us pulse after the first byte and last byte of packets)
Pin 5 = RM Data		(this line has data back from the head unit)
Pin 6 = Acc		(not required for comms) Note to self: Supply voltage (12V unreg)
Pin 7 = NC		(not connected)
Pin 8 = GND		(you require a common ground to head unit)
```

## Packet Order
Packet containing state, time, disc and track information to send to the headunit.
| Byte | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
| ---- | - | - | - | - | - | - | - | - |
| Info |  |	  	disc(b0-b3) |	track |	min |	sec |	state |  |  |
| Data |	0xCB |	0x42 |	0x09 |	0x02 |	0x56 |	0x00 |	0x30 |	0xC3 |

## States
| Value |	0x00 | 0x10 | 0x20 | 0x04 | 0x08 |
| ----- | ---- | ---- | ---- | ---- | ---- |
| Info | normal | scan | random | random | repeat |

## Remote Control Data
Code from [cdcemy.asm](example_code/cdcemu/cdcemu.asm) that shows the remote control data received from the head unit.
Refer to the [PIC Instruction Set](pic_instruction_set.pdf) document for the assembly instruction set definitions below.

``` Assembly
TranslateRM
	movwf	RM_tempbyte

	movlw	0x54	; track <
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'<'

	movlw	0x58	; track >
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'>'

	movlw	0x60	; Disc Down
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'P'	; 'P'revious

	movlw	0x70	; Disc Up
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'N'	; 'N'ext

	movlw	0x48	; Random
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'R'	; 'R'andom

	movlw	0x40	; OFF
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'0'	; Turn off scanning and random


	movlw	0x2C	; Scan
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'S'	; 'S'can

	movlw	0x52	; Scan (OFF)
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	's'	; 'S'can


	movlw	0x64	; repeat
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'r'	; 'r'epeat


	movlw	0x1c	; Init
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'I'	; 'I'n

	movlw	0x14	; ON
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'O'	; 'O'n

	movlw	0x20	; Off (ping)
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'o'	; 'o'ff
```