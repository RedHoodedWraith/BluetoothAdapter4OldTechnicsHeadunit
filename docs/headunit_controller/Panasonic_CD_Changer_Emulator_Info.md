# Panasonic car stereo CD Changer Emulator circuit
## Introduction
The following is written by Kristoffer Sjöberg which can be found on [Kristoffer's site](https://q1.se/cdcemu/details.php). It was converted into a markup document by myself Asami De Almeida on the 2nd of August 2025 to make document referencing easier and reliable during development.

## How to make your own

So I've been making a Panasonic CD Changer Emulator the last few weeks. The hardest part was to get the pinout for the DIN on the back of the head unit. Finally I got found a guy in the UK who had the pinout:

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

With this information I got SO much closer - couldn't have done it without it. But I also found very relevant info on http://www-user.tu-chemnitz.de/~harn/mp3_cdc.htm - but sadly enough the page was offline when I needed it. Google's cache saved my day:

> ### Panasonic
> 
> The protocol panasonic uses is of the serial sync. type. There is one data line, a clock line and a sync line the **changer** uses to send data to the radio.
> The radio to **changer** communication is done by some signals known from standard IR remote controls (without a carrier) using one dataline.
> This remote control **signal** is pulse width modulated,the dataline is active high.
> After an initail high(9ms) low(4.5ms) there follows a 32 bit sequence with a 0 encoded as 550us high,550us low and a 1 as 550us high,1.7ms low.
> If the low pulse in the init phase is only 2.25ms long it is just a **signal** send periodical when a key is hold down and there are no data bits.
> The data is transfered lsb first, the 1st byte is 0xFF-0th byte and the 3rd byte is 0xFE-2nd byte.The 2nd byte is the command.
> 
> The **changer** to radio communication transfers the data in bytes msb first, the data is valid at the falling clock edge and a low pulse of one half clock period is sent after the first and the last byte of the transfer on the sync line..The clock period is arround 8us.
> 
> There was only one packet containing state, time, disc and track information.
> | Byte | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
> | ---- | - | - | - | - | - | - | - | - |
> | Info |  |	  	disc(b0-b3) |	track |	min |	sec |	state |  |  |
> | Data |	0xCB |	0x42 |	0x09 |	0x02 |	0x56 |	0x00 |	0x30 |	0xC3 |
> 
> **state:**
> | Value |	0x00 | 0x10 | 0x20 | 0x04 | 0x08 |
> | ----- | ---- | ---- | ---- | ---- | ---- |
> | Info | normal | scan | random | random | repeat |

 

For the inputs to be enabled, the head unit must think there's a Panasonic-made CD-changer connected.

Now, I had the information I needed. The only thing left was coding it up.

To summarize the current PIC firmware capabilities:

    RS232 communication in 57600bps with RTS/CTS flow control, half duplex
    Panasonic CDC Emulation
        Head Unit Display Update
        Recognizes key presses (normal and repetitive) on the head unit and forwards them through RS232 to DTE
        Very simple protocol enables Head Unit Display update through RS232

Runs on a PIC16F84A @ 20MHz

### Connections to Head unit as follows:
```
PIC16F84A Pin  1 RA2 -> DIN8C Pin 2 SCLK to Head Unit
PIC16F84A Pin  2 RA3 -> DIN8C Pin 1 STX  to Head Unit
PIC16F84A Pin 18 RA1 -> DIN8C Pin 4 SYNC to Head Unit
PIC16F84A Pin  6 RB0 <- DIN8C Pin 5 RM to Head Unit
```

### RS232 bitrate and format:
```
57600bps, 8n1
```

### Table describes a 9 pin DSUB connector (female, same applies to male)
```
Short DB9F Pin 4 	<> 	DB9F Pin 6  (to make DSR follow DTR)
PIC TX out 	RB1 	-> 	DB9F Pin 2, RXD
PIC RX in	RB2  	<- 	DB9F Pin 3, TXD
PIC RTS in	RB3  	<- 	DB9F Pin 7, RTS
PIC CTS out	RB4  	-> 	DB9F Pin 8, CTS
```

## Files and source

And then, of course, the source code for the CDCEmu v3 (old) It's written in relocatable assembler using MPLAB 6.x

* [cdcemu.asm](example_code/cdcemu/cdcemu.asm)
* [obj_delay_20MHz.asm](example_code/cdcemu/obj_delay_20MHz.asm)
* [obj_rs232.asm](example_code/cdcemu/obj_rs232.asm)

Here's an Arduino implementation kindly provided by Steve Hennerley in January, 2017:

* [arduino.txt](example_code/cd_changer_emulator/cd_changer_emulator.ino)

## Contact
Kristoffer Sjöberg
kristoffer.sjoberg at galeno.se
