#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"
#include <string.h>
#include "esp_log.h"
#include "driver/spi_master.h"

// Using VSPI on ESP32 (and what it maps to on the DIN plug)
#define SCK_PIN 18  // DIN Pin 2 - Clock
#define MOSI_PIN 23 // DIN Pin 1 - Data
#define CS_PIN 5    // DIN Pin 4 - Strobe

// dispData - 0xCB, <disc>, <track>, <min>, <sec>, <state>, <unknown>, 0xc3, (additional zero bytes for padding between packets)
// Can all be zeros apart from the 0xCB at the start and the 0xC3 at the end
// Note that you can substitute 0xC3 for 0xD3 and the head unit thinks an MD Changer is installed
uint8_t dispData[] = { 0xCB,0x00,0x00,0x00,0x00,0x00,0x00,0xd3,0x00,0x00,0x00,0x00 };


void app_main() {

}