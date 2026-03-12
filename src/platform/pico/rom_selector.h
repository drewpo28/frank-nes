/*
 * MurmNES - ROM Selector Menu
 * Displays cartridges with cover art from SD card metadata.
 * SPDX-License-Identifier: MIT
 */

#ifndef ROM_SELECTOR_H
#define ROM_SELECTOR_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Maximum ROM filename length (including path) */
#define ROM_PATH_MAX 280

/**
 * Pre-load all ROM metadata from SD (CRCs, titles, images) and
 * if only 1 ROM, load it into PSRAM too.
 * Call BEFORE HDMI starts — SD card SPI conflicts with HSTX.
 * @param out_rom_size  Set to ROM size if single ROM auto-loaded, else 0
 * @return Number of ROMs found
 */
int rom_selector_preload(long *out_rom_size);

/**
 * Show the ROM selector UI (no SD access — all data in memory).
 * Call AFTER HDMI starts.
 * @param out_rom_size  Receives size of selected ROM in PSRAM
 * @return true if ROM selected
 */
bool rom_selector_show(long *out_rom_size);

/**
 * Get PSRAM pointer to the last selected/loaded ROM data.
 */
void *rom_selector_get_rom_data(void);

#ifdef __cplusplus
}
#endif

#endif /* ROM_SELECTOR_H */
