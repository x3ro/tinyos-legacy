/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * @file PMIC.c
 * @author Lama Nachman, Robbie Adler
 *
 * The file provices PMIC intialization and settings together with
 * the interrupts from the PMIC.
 */
#include <PMIC.h>
#include <PXA27XInterrupt.h>
#include <PXA27XGPIOInt.h>
#include <HPLInit.h>


bool gotReset = FALSE;
TOSH_ASSIGN_PIN(PMIC_TXON, A, 108);

#define PMI_GPIO 1

/**
 * PMIC_Init
 *
 * Setup the I2C to talk to the PMIC and allocate the I2C interrupt.
 * This code is ported from the tinyos repository and combines both
 * the init and the start routine of the tinyos version.
 *
 * @return SUCCESS | ERROR
 */
void PMIC_Init()
{
  uint8_t val[3];

  CKEN |= CKEN15_PMI2C;
  PCFR |= PCFR_PI2C_EN;
  PICR = ICR_IUE | ICR_SCLE;
    
  TOSH_MAKE_PMIC_TXON_OUTPUT();
  TOSH_CLR_PMIC_TXON_PIN();
    
  gotReset=FALSE;
  
  PXA27XIrq_Allocate (PPID_PWR_I2C);

  //irq is apparently active low...however trigger on both for now
  //call PMICInterrupt.enable(TOSH_FALLING_EDGE);
  PXA27XGPIOInt_Enable (PMI_GPIO, TOSH_FALLING_EDGE);
  PXA27XIrq_Enable (PPID_PWR_I2C);
  
  /*
   * Reset the watchdog, switch it to an interrupt, so we can disable it
   * Ignore SLEEP_N pin, enable H/W reset via button
   */
  writePMIC(PMIC_SYS_CONTROL_A,
         SCA_RESET_WDOG | SCA_WDOG_ACTION | SCA_HWRES_EN);

  // Disable all interrupts from PMIC except for ONKEY button
  writePMIC(PMIC_IRQ_MASK_A, ~IMA_ONKEY_N);
  writePMIC(PMIC_IRQ_MASK_B, 0xFF);
  writePMIC(PMIC_IRQ_MASK_C, 0xFF);

  //read out the EVENT registers so that we can receive interrupts
  readPMIC(PMIC_EVENTS, val, 3);

  // Set default core voltage to 0.85 V
  //call PMIC.setCoreVoltage(B2R1_TRIM_P85_V);
  PMIC_SetCoreVoltage (B2R1_TRIM_P95_V);

  //startLDOs ();
}

/**
 * PMIC_Stop
 *
 * Disable the interrupts related to the PMIC and undo
 * all the register settings.
 *
 * @return SUCCESS | FAIL
 */
result_t PMIC_Stop()
{
  PXA27XIrq_Disable (PPID_PWR_I2C);
  PXA27XGPIOInt_Disable (PMI_GPIO);
  CKEN &= ~CKEN15_PMI2C;
  PICR = 0;
    
  return SUCCESS;
}


/**
 * readPMIC
 *
 * The function reads data from the PMIC using the I2C
 * and stores it in a buffer ("value")
 *
 * @param address Address to read from.
 * @param value The data will be stored in this buffer.
 * @param numBytes Number of bytes to be read.
 *
 * @return SUCCESS | FAIL
 */
result_t readPMIC (uint8_t address, uint8_t *value, uint8_t numBytes)
{
  //send the PMIC the address that we want to read
  if(numBytes > 0)
  {
    PIDBR = PMIC_SLAVE_ADDR<<1; 
    PICR |= ICR_START;
    PICR |= ICR_TB;
    while(PICR & ICR_TB);
      
    //actually send the address terminated with a STOP
    PIDBR = address;
    PICR &= ~ICR_START;
    PICR |= ICR_STOP;
    PICR |= ICR_TB;
    while(PICR & ICR_TB);
    PICR &= ~ICR_STOP;
         
    //actually request the read of the data
    PIDBR = PMIC_SLAVE_ADDR<<1 | 1; 
    PICR |= ICR_START;
    PICR |= ICR_TB;
    while(PICR & ICR_TB);
    PICR &= ~ICR_START;
      
    //using Page Read Mode
    while (numBytes > 1)
    {
      PICR |= ICR_TB;
      while(PICR & ICR_TB);
      *value = PIDBR;
      value++;
      numBytes--;
    }
      
    PICR |= ICR_STOP;
    PICR |= ICR_ACKNAK;
    PICR |= ICR_TB;
    while(PICR & ICR_TB);
    *value = PIDBR;
    PICR &= ~ICR_STOP;
    PICR &= ~ICR_ACKNAK;
      
    return SUCCESS;
  }
  else
  {
    return FAIL;
  }
}

/**
 * writePMIC
 * 
 * Write a byte value to a particular address using I2C. The value and
 * the address has to be passed as parameter to the function.
 *
 * @param address
 * @param value
 *
 * @return SUCCESS | FAIL
 */
result_t writePMIC (uint8_t address, uint8_t value)
{
  PIDBR = PMIC_SLAVE_ADDR<<1;
  PICR |= ICR_START;
  PICR |= ICR_TB;
  while(PICR & ICR_TB);

  PIDBR = address;
  PICR &= ~ICR_START;
  PICR |= ICR_TB;
  while(PICR & ICR_TB);

  PIDBR = value;
  PICR |= ICR_STOP;
  PICR |= ICR_TB;
  while(PICR & ICR_TB);
  PICR &= ~ICR_STOP;

  return SUCCESS;
}

/**
 * startLDOs
 *
 * Code ported from TinyOS,
 *
 * @@@@FIXME I am not sure which of the LDOs we will need and
 * which ones we dont care about. need to fix it.
 */
void startLDOs() 
{
  uint8_t oldVal, newVal;

#if START_SENSOR_BOARD_LDO 
  // TODO : Need to move out of here to sensor board functions
  readPMIC(PMIC_A_REG_CONTROL_1, &oldVal, 1);
  newVal = oldVal | ARC1_LDO10_EN | ARC1_LDO11_EN;	// sensor board
  writePMIC(PMIC_A_REG_CONTROL_1, newVal);

  readPMIC(PMIC_B_REG_CONTROL_2, &oldVal, 1);
  newVal = oldVal | BRC2_LDO10_EN | BRC2_LDO11_EN;
  writePMIC(PMIC_B_REG_CONTROL_2, newVal);
#endif

#if START_RADIO_LDO
  // TODO : Move to radio start
  readPMIC(PMIC_B_REG_CONTROL_1, &oldVal, 1);
  newVal = oldVal | BRC1_LDO5_EN; 
  writePMIC(PMIC_B_REG_CONTROL_1, newVal);
#endif

#if (!ENABLE_BUCK2)  // Disable BUCK2 if VCC_MEM is not configured to use BUCK2
  readPMIC(PMIC_B_REG_CONTROL_1, &oldVal, 1);
  newVal = oldVal & ~BRC1_BUCK_EN;
  writePMIC(PMIC_B_REG_CONTROL_1, newVal);
#endif

}

/**
 * PMIC_SetCoreVoltage
 * 
 * The Buck2 controls the core voltage, set to appropriate trim value
 *
 * @param trimValue
 *
 * @return SUCCESS | FAIL
 */
result_t PMIC_SetCoreVoltage(uint8_t trimValue) 
{
  writePMIC(PMIC_BUCK2_REG1, (trimValue & B2R1_TRIM_MASK) | B2R1_GO);
  return SUCCESS;
}

/**
 * PMICInterrupt_Fired
 *
 * The init routine enables only the reset interrupt and
 * all the other interrupts are explicitly disabled. So
 * the function is invoked only when the reset button is
 * activated.
 *
 */
void PMICInterrupt_Fired()
{
  WDReset (RESET_DELAY);
}

/**
 * PI2CInterrupt_Fired
 *
 * The settings to the PMIC chip is through the
 * I2C. The interrupt indicates either a write
 * or read done from the I2C bus.
 */
void PI2CInterrupt_Fired()
{
  uint32_t status, update=0;
  status = PISR;
  if(status & ISR_ITE)
  {
    update |= ISR_ITE;
#if DEBUG
    trace(DBG_USR1,"sent data");
#endif
  }

  if(status & ISR_BED)
  {
    update |= ISR_BED;
#if DEBUG
    trace(DBG_USR1,"bus error");
#endif
  }
  PISR = update;
}

/**
 * WDReset
 * 
 * Enables the watchdog and sets the compare register
 * with the value of the first parameter and waits till
 * the timeout occurs. The processor reboots once a
 * timeout.
 *
 * @parm delay Value for a compare register.
 */
void WDReset (int delay) 
{
  // Set to short timeout and block to ensure reset
  OSMR3 = OSCR0 + delay;
  OWER = 1;
  while(1);
}
