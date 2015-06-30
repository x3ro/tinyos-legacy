/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2005 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
 * @author Konrad Lorincz
 * @version 1.0, August 15, 2005
 */
#ifndef KAC9648_H
#define KAC9648_H


// GPIO pin assignment.  Should this be defined in /beta/imote2/hardware.h?
TOSH_ASSIGN_PIN(SNAPSHOT, A, 10);

// ----------- I2C Slave Addresses, 7-bit! --------------             
enum {CAMERA_SLAVEADDR = 85};   // 0b1010101


/******************************************************************************/
/* KAC9648 Camera registers */
/******************************************************************************/
#define DEVID	    (0)                 /* Device ID register */
#define REV         (0x01)              /* Revision register */
#define VCLKGEN     (0x05)              /* Clock Generation register */
#define PWDRST      (0x06)              /* Power Down and Reset register */
#define OPCTRL      (0x09)              /* Operation Control register */
#define WROWS       (0x19)              /* Active Window Row Start register */
#define WROWE       (0x1A)              /* Active Window Row End register */
#define WROWLSB     (0x1B)              /* Active Window Row LSB register */
#define WCOLS       (0x1C)              /* Active Window Column Start register */
#define WCOLE       (0x1D)              /* Active Window Column End register */
#define WCOLLSB     (0x1E)              /* Active Window Column LSB register */

#define SNAPMODE    (0x30)              /* Snapshot Mode Configuration register */
#define DVBUSCONFIG2 (0x54)             /* Video Output Adjustment Register */
#define POWCTRL     (0x85)              /* Power Down Control register */
#define INTREG2     (0x88)              /* Initialization register 2 */


#define PWDRST_SenReset         (1)	    /* Sensor Reset */
#define PWDRST_PwDn             (0)	    /* Power Down Chip */

#define OPCTRL_LowLight         (3)	    /* LowLight vs. NormalLight gain */
#define OPCTRL_MasterMode       (2)	    /* Master-mode: for the digital video port's synch. signals */
#define OPCTRL_RstzSoft         (0)	    /* Resets all state machines ... */

#define WROWS_WStartRow         (3)     
#define WROWE_WEndRow           (3)
#define WROWLSB_WStartRow       (3)
#define WROWLSB_WEndRow         (0)

#define WCOLS_WStartCol         (3)
#define WCOLE_WEndCol           (3)
#define WCOLLSB_WStartCol       (5)
#define WCOLLSB_WEndCol         (0)

#define SNAPMODE_SnapEnable     (5)	    /* Camera Mode: Snapshot or Video */
#define SNAPMODE_SnapshotMode   (4)	    /* Snapshot Mode: Pulse or Level */
#define SNAPMODE_ShutterMode    (3)	    /* Shutter Mode: External signal or not */


#endif
