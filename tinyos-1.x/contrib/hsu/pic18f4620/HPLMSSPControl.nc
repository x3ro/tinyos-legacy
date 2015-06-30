// $Id: HPLMSSPControl.nc,v 1.2 2005/12/07 18:59:19 hjkoerber Exp $

/*
 * Copyright (c) 2004-2005, Technische Universit√t Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universit√§t Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * 
 * Byte-level interface to control a Master Synchronous Serial Port Module
 * (MSSP). 
 * The MSSP can be switched to SPI- or I2C-mode. The interface follows
 * the convention of being stateless, thus a higher layer has to maintain
 * state information. 
 * In the current version just I2C Master-mode is supported
 *
 * @author Jan Hauer (hauer@tkn.tu-berlin.de)
 * @author Joe Polastre
 * @author Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	     (+49)40-6541-2638/2627
 *
 * $Date: 2005/12/07 18:59:19 $
 * $Revision: 1.2 $ 
 *
 */
 
includes pic18f4620mssp;

interface HPLMSSPControl {

  /**
   * Returns an enum value corresponding to the current mode of the MSSP
   * module. Allows one to read the module mode, change it, and then
   * reset it back to its original state after use.
   */
  async command pic18f4620_msspmode_t getMode();

  /**
   * Sets the MSSP mode to one of the options from pic18f4620_msspmode_t
   * defined in pic18f4620mssp.h
   *
   * @return SUCCESS if the mode was changed
   */
  async command void setMode(pic18f4620_msspmode_t mode); 
  
  /*
   * Enables the I2C module 
   */
  async command void enableI2C();

  /*
   * Enables the SPI module 
   */
  async command void enableSPI();


  /**
   * Disables the I2C module
   */
  async command void disableI2C();

  /**
   * Disables the SPI module
   */
  async command void disableSPI();


  /**
   * Returns TRUE if the module is set to I2C mode 
   */
  async command bool isI2C();


  /**
   * Returns TRUE if the module is set to SPI mode 
   */
  async command bool isSPI();


  /**
   * Switches MSSP to I2C mode.
   */
  async command void setModeI2C();
 
  /**
   * Switches MSSP to SPI mode.
   */
  async command void setModeSPI();


 }

