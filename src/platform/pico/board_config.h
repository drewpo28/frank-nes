/*
 * FRANK NES - NES Emulator for RP2350
 * Copyright (c) 2026 Mikhail Matveev <xtreme@rh1.tech>
 * https://rh1.tech | https://github.com/rh1tech/frank-nes
 * SPDX-License-Identifier: MIT
 */

#ifndef BOARD_CONFIG_H
#define BOARD_CONFIG_H

/*
 * Platform board configuration dispatcher.
 * Select platform via CMake: -DPLATFORM=m1|m2|pc|dv|z0
 */

#if defined(PLATFORM_M1)
  #include "board_m1.h"
#elif defined(PLATFORM_PC)
  #include "board_pc.h"
#elif defined(PLATFORM_DV)
  #include "board_dv.h"
#elif defined(PLATFORM_Z0)
  #include "board_z0.h"
#else
  #include "board_m2.h"
#endif

#endif /* BOARD_CONFIG_H */
