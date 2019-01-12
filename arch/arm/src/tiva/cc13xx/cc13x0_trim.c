/****************************************************************************
 * arch/arm/src/tiva/cc13xx/cc13x_start.c
 *
 *   Copyright (C) 2018 Gregory Nutt. All rights reserved.
 *   Author: Gregory Nutt <gnutt@nuttx.org>
 *
 * This is a port of TI's setup.c file (revision 49363) which has a fully
 * compatible BSD license:
 *
 *    Copyright (c) 2015-2017, Texas Instruments Incorporated
 *    All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are met:
 *
 *  1) Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *
 *  2) Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *
 *  3) Neither the name NuttX nor the names of its contributors may be used to
 *     endorse or promote products derived from this software without specific
 *     prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 *  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *  POSSIBILITY OF SUCH DAMAGE.
 *
 ******************************************************************************/

/******************************************************************************
 * Included Files
 ******************************************************************************/

#include <nuttx/config.h>

#include "tiva_chipinfo.h"
#include "hardware/tiva_vims.h"
#include "hardware/tiva_ccfg.h"
#include "hardware/tiva_ddi0_osc.h"

/******************************************************************************
 * Private Functions
 ******************************************************************************/

/******************************************************************************
 * Name: trim_wakeup_frompowerdown
 *
 * Description:
 *   Trims to be applied when coming from POWER_DOWN (also called when
 *   coming from SHUTDOWN and PIN_RESET).
 *
 * Returned Value:
 *   None
 *
 ******************************************************************************/

static void trim_wakeup_frompowerdown(void)
{
  /* Currently no specific trim for Powerdown */
}

/******************************************************************************
 * Name: trim_wakeup_fromshutdown
 *
 * Description:
 *   Trims to be applied when coming from SHUTDOWN (also called when
 *   coming from PIN_RESET).
 *
 * Input Parameters:
 *   fcfg1_revision
 *
 * Returned Value:
 *   None
 *
 ******************************************************************************/

static void trim_wakeup_fromshutdown(uint32_t fcfg1_revision)
{
  uint32_t ccfg_modeconf;
  uint32_t mp1rev;

  /* Force AUX on and enable clocks No need to save the current status of the
   * power/clock registers. At this point both AUX and AON should have been
   * reset to 0x0.
   */

  putreg32(AON_WUC_AUXCTL_AUX_FORCE_ON, TIVA_AON_WUC_AUXCTL);

  /* Wait for power on on the AUX domain */

  while ((getreg32(TIVA_AON_WUC_PWRSTAT) & AON_WUC_PWRSTAT_AUX_PD_ON) == 0)
    {
    }

  /* Enable the clocks for AUX_DDI0_OSC and AUX_ADI4 */

  putreg32(AUX_WUC_MODCLKEN0_AUX_DDI0_OSC | AUX_WUC_MODCLKEN0_AUX_ADI4,
           TIVA_AON_WUC_MODCLKEN0);

  /* Check in CCFG for alternative DCDC setting */

  if ((getreg32(TIVA_CCFG_SIZE_AND_DIS_FLAGS) &
       CCFG_SIZE_AND_DIS_FLAGS_DIS_ALT_DCDC_SETTING) == 0)
    {
      /* ADI_3_REFSYS:DCDCCTL5[3] (=DITHER_EN) = CCFG_MODE_CONF_1[19]
       * (=ALT_DCDC_DITHER_EN) ADI_3_REFSYS:DCDCCTL5[2:0](=IPEAK ) =
       * CCFG_MODE_CONF_1[18:16](=ALT_DCDC_IPEAK ) Using a single 4-bit masked
       * write since layout is equal for both source and destination
       */

      regval = getreg32(TIVA_CCFG_MODE_CONF_1);
      regval = (0xf0 | (regval >> CCFG_MODE_CONF_1_ALT_DCDC_IPEAK_SHIFT));
      putreg8((uint8_t)regval, TIVA_ADI3_MASK4B + (ADI_3_REFSYS_DCDCCTL5_OFFSET * 2));
    }

  /* Enable for JTAG to be powered down(will still be powered on if debugger
   * is connected)
   */

 AONWUCJtagPowerOff();

  /* read the MODE_CONF register in CCFG */

  ccfg_modeconf = getreg32(TIVA_CCFG_MODE_CONF);

  /* First part of trim done after cold reset and wakeup from shutdown:
   * -Configure cc13x0 boost mode. -Adjust the VDDR_TRIM_SLEEP value.
   * -Configure DCDC.
   */

  SetupAfterColdResetWakeupFromShutDownCfg1(ccfg_modeconf);

  /* Second part of trim done after cold reset and wakeup from shutdown:
   * -Configure XOSC.
   */

#if CCFG_BASE == CCFG_BASE_DEFAULT
  SetupAfterColdResetWakeupFromShutDownCfg2(fcfg1_revision,
                                            ccfg_modeconf);
#else
  NOROM_SetupAfterColdResetWakeupFromShutDownCfg2(fcfg1_revision,
                                                  ccfg_modeconf);
#endif

  /* Increased margin between digital supply voltage and VDD BOD during
   * standby. VTRIM_UDIG: signed 4 bits value to be incremented by 2 (max = 7)
   * VTRIM_BOD: unsigned 4 bits value to be decremented by 1 (min = 0) This
   * applies to chips with mp1rev < 542 for cc13x0 and for mp1rev < 527 for
   * cc26x0
   */

  mp1rev =
    ((getreg32(TIVA_FCFG1_TRIM_CAL_REVISION) &
      FCFG1_TRIM_CAL_REVISION_MP1_M) >> FCFG1_TRIM_CAL_REVISION_MP1_SHIFT);
  if (mp1rev < 542)
    {
      uint32_t ldoTrimReg = getreg32(TIVA_FCFG1_BAT_RC_LDO_TRIM);
      uint32_t vtrim_bod;
      uint32_t vtrim_udig;

      /* bit[27:24] unsigned */

      vtrim_bod = ((ldoTrimReg & FCFG1_BAT_RC_LDO_TRIM_VTRIM_BOD_M) >>
                  FCFG1_BAT_RC_LDO_TRIM_VTRIM_BOD_SHIFT);

      /* bit[19:16] signed but treated as unsigned */

      vtrim_udig = ((ldoTrimReg & FCFG1_BAT_RC_LDO_TRIM_VTRIM_UDIG_M) >>
                   FCFG1_BAT_RC_LDO_TRIM_VTRIM_UDIG_SHIFT);

      if (vtrim_bod > 0)
        {
          vtrim_bod -= 1;
        }

      if (vtrim_udig != 7)
        {
          if (vtrim_udig == 6)
            {
              vtrim_udig = 7;
            }
          else
            {
              vtrim_udig = ((vtrim_udig + 2) & 0xf);
            }
        }

      regval8 = (vtrim_udig << ADI_2_REFSYS_SOCLDOCTL0_VTRIM_UDIG_SHIFT) |
                (vtrim_bod << ADI_2_REFSYS_SOCLDOCTL0_VTRIM_BOD_SHIFT);
      putreg8(regval, TIVA_ADI2_SOCLDOCTL0);
    }

  /* Third part of trim done after cold reset and wakeup from shutdown:
   * -Configure HPOSC. -Setup the LF clock.
   */

#if ( CCFG_BASE == CCFG_BASE_DEFAULT )
  SetupAfterColdResetWakeupFromShutDownCfg3(ccfg_modeconf);
#else
  NOROM_SetupAfterColdResetWakeupFromShutDownCfg3(ccfg_modeconf);
#endif

  /* Allow AUX to power down */

  AUXWUCPowerCtrl(AUX_WUC_POWER_DOWN);

  /* Leaving on AUX and clock for AUX_DDI0_OSC on but turn off clock for
   * AUX_ADI4
   */

  putreg32(AUX_WUC_MODCLKEN0_AUX_DDI0_OSC, TIVA_AON_WUC_MODCLKEN0);

  /* Disable EFUSE clock */

  regval  = getreg32(TIVA_FLASH_CFG);
  regval |= FLASH_CFG_DIS_EFUSECLK;
  putreg32(regval, TIVA_FLASH_CFG)
}

/******************************************************************************
 * Name: trim_coldreset
 *
 * Description:
 *   Trims to be applied when coming from PIN_RESET.
 *
 * Returned Value:
 *   None
 *
 ******************************************************************************/

static void trim_coldreset(void)
{
  /* Currently no specific trim for Cold Reset */
}

/******************************************************************************
 * Public Functions
 ******************************************************************************/

/******************************************************************************
 * Name: cc13xx_trim_device
 *
 * Description:
 *   Perform the necessary trim of the device which is not done in boot code
 *
 *   This function should only execute coming from ROM boot. The current
 *   implementation does not take soft reset into account. However, it does no
 *   damage to execute it again. It only consumes time.
 *
 ******************************************************************************/

void cc13xx_trim_device(void)
{
  uint32_t fcfg1_revision;
  uint32_t aon_sysresetctrl;

  /* Get layout revision of the factory configuration area (Handle undefined
   * revision as revision = 0)
   */

  fcfg1_revision = getreg32(TIVA_FCFG1_FCFG1_REVISION);
  if (fcfg1_revision == 0xffffffff)
    {
      fcfg1_revision = 0;
    }

  /* This setup file is for CC13x0 PG2.0 and later. Halt if violated */

  chipinfo_verify();

  /* Enable standby in flash bank */

  regval  = getreg32(TIVA_FLASH_CFG);
  regval &= ~FLASH_CFG_DIS_STANDBY;
  putreg32(regval, TIVA_FLASH_CFG)

  /* Clock must always be enabled for the semaphore module (due to ADI/DDI HW
   * workaround)
   */

  putreg32(AUX_WUC_MODCLKEN1_SMPH, TIVA_AON_WUC_MODCLKEN1);

  /* Warm resets on CC13x0 and CC26x0 complicates software design because much
   * of our software expect that initialization is done from a full system
   * reset. This includes RTC setup, oscillator configuration and AUX setup. To
   * ensure a full reset of the device is done when customers get e.g. a
   * Watchdog reset, the following is set here:
   */

  regval  = getreg32(TIVA_PRCM_WARMRESET);
  regval |= PRCM_WARMRESET_WR_TO_PINRESET;
  putreg32(regval, TIVA_PRCM_WARMRESET)

  /* Select correct CACHE mode and set correct CACHE configuration */

#if CCFG_BASE == CCFG_BASE_DEFAULT
  SetupSetCacheModeAccordingToCcfgSetting();
#else
  NOROM_SetupSetCacheModeAccordingToCcfgSetting();
#endif

  /* 1. Check for powerdown 2. Check for shutdown 3. Assume cold reset if none
   * of the above. It is always assumed that the application will freeze the
   * latches in AON_IOC when going to powerdown in order to retain the values
   * on the IOs. NB. If this bit is not cleared before proceeding to
   * powerdown, the IOs will all default to the reset configuration when
   * restarting.
   */

  if ((getreg32(TIVA_AON_IOC_IOCLATCH) & AON_IOC_IOCLATCH_EN) == 0)
    {
      /* NB. This should be calling a ROM implementation of required trim and
       * compensation e.g.
       * trim_wakeup_frompowerdown()
       */

      trim_wakeup_frompowerdown();
    }

  /* Check for shutdown When device is going to shutdown the hardware will
   * automatically clear the SLEEPDIS bit in the SLEEP register in the
   * AON_SYSCTL module. It is left for the application to assert this bit when
   * waking back up, but not before the desired IO configuration has been
   * re-established.
   */

  else if ((getreg32(TIVA_AON_SYSCTL_SLEEPCTL) & AON_SYSCTL_SLEEPCTL_IO_PAD_SLEEP_DIS) == 0)
    {
      /* NB. This should be calling a ROM implementation of required trim and
       * compensation e.g. trim_wakeup_fromshutdown() -->
       * trim_wakeup_frompowerdown();
       */

      trim_wakeup_fromshutdown(fcfg1_revision);
      trim_wakeup_frompowerdown();
    }
  else
    {
      /* Consider adding a check for soft reset to allow debugging to skip this
       * section!!! NB. This should be calling a ROM implementation of
       * required trim and compensation e.g. trim_coldreset() -->
       * trim_wakeup_fromshutdown() -->
       * trim_wakeup_frompowerdown()
       */

      trim_coldreset();
      trim_wakeup_fromshutdown(fcfg1_revision);
      trim_wakeup_frompowerdown();

    }

  /* Set VIMS power domain control. PDCTL1VIMS = 0 ==> VIMS power domain is
   * only powered when CPU power domain is powered
   */

  putreg32(0, TIVA_PRCM_PDCTL1VIMS);

  /* Configure optimal wait time for flash FSM in cases where flash pump wakes
   * up from sleep
   */

  regval = getreg32(TIVA_FLASH_FPAC1);
  regval &= ~FLASH_FPAC1_PSLEEPTDIS_MASK;
  regval |= (0x139 << FLASH_FPAC1_PSLEEPTDIS_SHIFT);
  putreg32(regval, TIVA_FLASH_FPAC1);

  /* And finally at the end of the flash boot process: SET BOOT_DET bits in
   * AON_SYSCTL to 3 if already found to be 1 Note: The BOOT_DET_x_CLR/SET bits
   * must be manually cleared
   */

  if (((getreg32(TIVA_AON_SYSCTL_RESETCTL) &
        (AON_SYSCTL_RESETCTL_BOOT_DET_1_MASK | AON_SYSCTL_RESETCTL_BOOT_DET_0_MASK))
       >> AON_SYSCTL_RESETCTL_BOOT_DET_0_SHIFT) == 1)
    {
      aon_sysresetctrl = (getreg32(TIVA_AON_SYSCTL_RESETCTL) &
                            ~(AON_SYSCTL_RESETCTL_BOOT_DET_1_CLR_MASK |
                              AON_SYSCTL_RESETCTL_BOOT_DET_0_CLR_MASK |
                              AON_SYSCTL_RESETCTL_BOOT_DET_1_SET_MASK |
                              AON_SYSCTL_RESETCTL_BOOT_DET_0_SET_MASK));

      putreg32(aon_sysresetctrl | AON_SYSCTL_RESETCTL_BOOT_DET_1_SET_MASK,
               TIVA_AON_SYSCTL_RESETCTL);
      putreg32(aon_sysresetctrl, TIVA_AON_SYSCTL_RESETCTL);
    }

  /* Make sure there are no ongoing VIMS mode change when leaving
   * cc13x0_trim_device() (There should typically be no wait time here, but
   * need to be sure)
   */

  while ((getreg32(TIVA_VIMS_STAT) & VIMS_STAT_MODE_CHANGING) != 0)
    {
      /* Do nothing - wait for an eventual ongoing mode change to complete. */

    }
}