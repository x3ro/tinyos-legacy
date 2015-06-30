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
 * @file PMIC.h
 * @author Lama Nachman, Robbie Adler
 *
 * The file provices PMIC intialization and settings together with
 * the interrupts from the PMIC.
 */
#ifndef PMIC_H
#define PMIC_H

#include <hardware.h>
#include <PMICDefines.h>

#define RESET_DELAY 10000  // delay in 1/3.25 MHz increments = ~3 ms

/**
 * PMIC_Init
 *
 * Setup the I2C to talk to the PMIC and allocate the I2C interrupt.
 * This code is ported from the tinyos repository and combines both
 * the init and the start routine of the tinyos version.
 *
 */
void PMIC_Init();

/**
 * PMIC_Stop
 *
 * Disable the interrupts related to the PMIC and undo
 * all the register settings.
 *
 * @return SUCCESS | FAIL
 */
result_t PMIC_Stop();


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
result_t readPMIC(uint8_t address, uint8_t *value, uint8_t numBytes);


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
result_t writePMIC (uint8_t address, uint8_t value);

/**
 * startLDOs
 *
 * Code ported from TinyOS,
 *
 * @@@@FIXME I am not sure which of the LDOs we will need and
 * which ones we dont care about. need to fix it.
 */
void startLDOs();

/**
 * PMIC_SetCoreVoltage
 * 
 * The Buck2 controls the core voltage, set to appropriate trim value
 *
 * @param trimValue
 *
 * @return SUCCESS | FAIL
 */
result_t PMIC_SetCoreVoltage (uint8_t trimValue);

/**
 * PMICInterrupt_Fired
 *
 * The init routine enables only the reset interrupt and
 * all the other interrupts are explicitly disabled. So
 * the function is invoked only when the reset button is
 * activated.
 *
 */
void PMICInterrupt_Fired();

/**
 * PI2CInterrupt_Fired
 *
 * The settings to the PMIC chip is through the
 * I2C. The interrupt indicates either a write
 * or read done from the I2C bus.
 */
void PI2CInterrupt_Fired();

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
void WDReset (int delay);

#endif
