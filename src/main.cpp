/**
 * @file main.c
 * @author Asami De Almeida (theengineer@redwraith.me)
 * @brief 
 * @version 0.1
 * @date 2025-08-22
 * 
 * @copyright Copyright (c) 2025
 * 
 * Copyright (C) 2025  Asami De Almeida
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 * 
 */

// #include <stdio.h>
// #include "esp_log.h"
// #include "freertos/FreeRTOS.h"
// #include "freertos/task.h"
// #include "driver/spi_master.h"

#include <SPI.h>
#include "AudioTools.h"
#include "BluetoothA2DPSink.h"

#define DEVICE_NAME "Klaus BT Audio"

// Using VSPI on ESP32 (and what it maps to on the DIN plug)
#define SCK_PIN 18  // DIN Pin 2 - Clock
#define MOSI_PIN 23 // DIN Pin 1 - Data
#define MISO_PIN 19 // DIN Pin 5 - UNUSED, we don't receive data from headunit with SPI
#define CS_PIN 5    // DIN Pin 4 - Strobe

// PCM5102 Pin Connections for I2C Streaming
// See https://github.com/pschatzmann/arduino-audio-tools/wiki/External-DAC
// Despite being powered from a 5V source, board signals are 3.3 V and therefore safe to use on ESP32
#define BCK_PIN 14  // BCK (Board Clock) to GPIO 14
#define DATA_PIN 22 // DATA to GPIO 22
#define WS_LRCK_PIN 15  // WS or LRCK to GPIO15

// dispData - 0xCB, <disc>, <track>, <min>, <sec>, <state>, <unknown>, 0xc3, (additional zero bytes for padding between packets)
// Can all be zeros apart from the 0xCB at the start and the 0xC3 at the end
// Note that you can substitute 0xC3 for 0xD3 and the head unit thinks an MD Changer is installed
uint8_t dispData[] = { 0xCB,0x00,0x00,0x00,0x00,0x00,0x00,0xd3,0x00,0x00,0x00,0x00 };

// spi_device_handle_t spi3;   // VSPI
auto vspi = new SPIClass(VSPI);

// A2DP Bluetooth Audio
I2SStream out;
BluetoothA2DPSink a2dp_sink(out);

// This was used in ESP-IDF, needs to be ported to Arduino
// static void spi_init() {
//     esp_err_t ret;

//     spi_bus_config_t buscfg={
//         .miso_io_num = -1,
//         .mosi_io_num = MOSI_PIN,
//         .sclk_io_num = SCK_PIN,
//         .quadwp_io_num = -1,
//         .quadhd_io_num = -1,
//         .max_transfer_sz = 32,
//     };

//     ret = spi_bus_initialize(SPI2_HOST, &buscfg, SPI_DMA_CH_AUTO);
//     ESP_ERROR_CHECK(ret);

//     spi_device_interface_config_t devcfg={
//         .clock_speed_hz = 1000000,  // 1 MHz
//         .mode = 0,                  //SPI mode 0
//         .spics_io_num = CS_PIN,     
//         .queue_size = 1,
//         .flags = SPI_DEVICE_HALFDUPLEX,
//         .pre_cb = NULL,
//         .post_cb = NULL,
//     };

//     ESP_ERROR_CHECK(spi_bus_add_device(SPI2_HOST, &devcfg, &spi3));
// };

void setup() {
  Serial.begin(115200);
  Serial.println("Starting Step 1");
  AudioToolsLogger.begin(Serial, AudioLogger::Info);
  Serial.println("Finished Step 1");

  // Configure i2s
  Serial.println("Starting Step 2");
  auto cfg = out.defaultConfig(TX_MODE);
  cfg.pin_bck = BCK_PIN;
  cfg.pin_ws = WS_LRCK_PIN;
  cfg.pin_data = DATA_PIN;
  out.begin(cfg);
  Serial.println("Finished Step 2");

  // Start A2DP (Bluetooth Audio Receiver)
  Serial.println("Starting Step 3");
  a2dp_sink.start(DEVICE_NAME, true);
  Serial.println("Finished Step 3");

  // Start SPI
  Serial.println("Starting Step 4");
  vspi->begin(SCK_PIN, MISO_PIN, MOSI_PIN, CS_PIN);
  pinMode(CS_PIN, OUTPUT);
  Serial.println("Finished Step 4");

  // Attempt to play music
  a2dp_sink.play();
}


void loop() {
  delay(1000); // do nothing
}
