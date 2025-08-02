# Bluetooth Adapter for a Technics Headunit (CQ-LQ1051A)

By Asami De Almeida

Important Note: Work in progress. Code is incomplete.

## Introduction
Making a Bluetooth audio adapter intended for Technics CQ-LQ1051A Headunit using its CD Controller Interface.
This adapter uses the ESP32 for Bluetooth connectivity, audio processing, and interfacing with the headunit as if it were an external CD changer player. The ESP32 outputs audio via a Digitial-to-Audio decoding board and into the RCA audio inputs in the back of the headunit.

There are three main parts to this project:
* CD Changer Emulator
* Bluetooth Handling
* Digital to Analogue Audio Conversion

## CD Changer Emulator
This part of the project is based on the information and code examples provided by Kristoffer Sjöberg and Steve Hennerley (see [Resources Used](#resources-used) section). The purpose of the emulator is to be able to use the built-in controls of the headunit to control the playback of Bluetooth audio.

For more information, see the Headunit Controller documentation in [`docs/headunit_controller`](docs/headunit_controller).

## Bluetooth Handling
This part of the project uses the Espressif Bluetooth® A2DP API to handle audio playback (such as music) and the Espressif HFP Client API for handling phone calls.

## Digital to Audio Conversion
This part of the project handles the conversion passing a digital audio stream to an analogue output via an external digital-to-analogue converter (DAC). This is likely going to involve a DAC board that receives digital audio via I2C or SPI. The most likely I2C board used is the PCM5102 decoder.

## Development Environment
This project is designed to be used with the PlatformIO framework for uploading to the ESP32 board.


## Resources Used
* [Panasonic car stereo CD Changer Emulator circuit](https://q1.se/cdcemu/)
* [Panasonic car stereo CD Changer Emulator circuit | How to make your own](https://q1.se/cdcemu/details.php) by Kristoffer Sjöberg
* [Basic Panasonic CQ-FX55LEN (and similar) CD Changer emulator for Arduino](https://q1.se/cdcemu/arduino.txt) by Steve Hennerley
* [Espressif | Bluetooth® A2DP API](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-reference/bluetooth/esp_a2dp.html)
* [Espressif | HFP Client API](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-reference/bluetooth/esp_hf_client.html)