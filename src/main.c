#include <stdio.h>
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/spi_master.h"

// Using VSPI on ESP32 (and what it maps to on the DIN plug)
#define SCK_PIN 18  // DIN Pin 2 - Clock
#define MOSI_PIN 23 // DIN Pin 1 - Data
// #define MISO_PIN 19 // DIN Pin 5 - Remote Control Data
#define CS_PIN 5    // DIN Pin 4 - Strobe

// dispData - 0xCB, <disc>, <track>, <min>, <sec>, <state>, <unknown>, 0xc3, (additional zero bytes for padding between packets)
// Can all be zeros apart from the 0xCB at the start and the 0xC3 at the end
// Note that you can substitute 0xC3 for 0xD3 and the head unit thinks an MD Changer is installed
uint8_t dispData[] = { 0xCB,0x00,0x00,0x00,0x00,0x00,0x00,0xd3,0x00,0x00,0x00,0x00 };

spi_device_handle_t spi3;   // VSPI


static void spi_init() {
    esp_err_t ret;

    spi_bus_config_t buscfg={
        .miso_io_num = -1,
        .mosi_io_num = MOSI_PIN,
        .sclk_io_num = SCK_PIN,
        .quadwp_io_num = -1,
        .quadhd_io_num = -1,
        .max_transfer_sz = 32,
    };

    ret = spi_bus_initialize(SPI2_HOST, &buscfg, SPI_DMA_CH_AUTO);
    ESP_ERROR_CHECK(ret);

    spi_device_interface_config_t devcfg={
        .clock_speed_hz = 1000000,  // 1 MHz
        .mode = 0,                  //SPI mode 0
        .spics_io_num = CS_PIN,     
        .queue_size = 1,
        .flags = SPI_DEVICE_HALFDUPLEX,
        .pre_cb = NULL,
        .post_cb = NULL,
    };

    ESP_ERROR_CHECK(spi_bus_add_device(SPI2_HOST, &devcfg, &spi3));
};

void app_main() {
    spi_init();
}