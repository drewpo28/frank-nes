/*
 * FRANK NES - NES Emulator for RP2350
 * Board configuration: PC (Olimex RP2040-PICO-PC)
 *
 * HSTX HDMI only. PWM audio only (no I2S). No TV/VGA.
 * PSRAM on GP8 (RP2350B).
 */

#ifndef BOARD_PC_H
#define BOARD_PC_H

/* PS/2 Keyboard */
#define KBD_CLOCK_PIN 0
#define KBD_DATA_PIN  1
#define PS2_PIN_CLK   0
#define PS2_PIN_DATA  1

/* SD Card (PIO-SPI) */
#define SDCARD_PIN_SPI0_SCK  6
#define SDCARD_PIN_SPI0_MOSI 7
#define SDCARD_PIN_SPI0_MISO 4
#define SDCARD_PIN_SPI0_CS   22

/* NES Gamepad */
#define NESPAD_CLK_PIN   5
#define NESPAD_LATCH_PIN 9
#define NESPAD_DATA_PIN  20

/* No I2S audio on this board */

/* PWM Audio */
#define PWM_PIN0 27
#define PWM_PIN1 28

/* No TV/VGA */

/* PSRAM on GP8 only */
#define PSRAM_CS_PIN_RP2350B 8
#define PSRAM_CS_PIN_RP2350A 8

/* No UART logging (GPIO 0 is KBD) */
#define NO_UART_LOGGING 1

/* Video: HSTX only (GPIO 12-19) */
#define HAS_HSTX 1
#define HDMI_BASE_PIN 12

#endif /* BOARD_PC_H */
