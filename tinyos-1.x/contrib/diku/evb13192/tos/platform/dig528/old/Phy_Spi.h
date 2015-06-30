/************************************************************************************
* This is the header file for the Abel SPI access.
*
* Author(s):
*
* (c) Copyright 2004, Freescale, Inc.  All rights reserved.
*
* Freescale Confidential Proprietary
*
* No part of this document must be reproduced in any form - including copied,
* transcribed, printed or by any electronic means - without specific written
* permission from Freescale.
*
* Last Inspected:
* Last Tested:
************************************************************************************/
#ifndef _PHY_SPI_H_
#define _PHY_SPI_H_

#include "DigiType.h"

#ifndef WIN32
  #pragma MESSAGE DISABLE C4002
#endif

/************************************************************************************
* Public prototypes
************************************************************************************/

/************************************************************************************
* Public type definitions
************************************************************************************/

/************************************************************************************
* Public memory declarations
************************************************************************************/

/**********************************************************************
* Public PHY_SPI.C functions                                          *
* Interface function used to read SPI                                 *
* Tranceiver Access Drivers via SPI                                   *
**********************************************************************/
extern void phy_read_spi(uint8_t addr, uint8_t *pb);
extern void phy_read_spi_int(uint8_t addr, uint8_t *pb);
extern void phy_read_spi_int_swap(uint8_t addr, uint8_t *pb);

extern void phy_write_spi(uint8_t addr, uint16_t content);
extern void phy_write_spi_int(uint8_t addr, uint16_t content);
extern void phy_write_spi_int_fast(uint8_t addr, uint16_t content);


#define ABEL_READ(abelReg, retReg)            phy_read_spi          ((abelReg | 0x80),(uint8_t *)&retReg);
#define ABEL_READ_INT(abelReg, retReg)        phy_read_spi_int      ((abelReg | 0x80),(uint8_t *)&retReg);
#define ABEL_READ_INT_SWAP(abelReg, retReg)   phy_read_spi_int_swap ((abelReg | 0x80),(uint8_t *)&retReg);


#define ABEL_WRITE(abelReg, content)          phy_write_spi         (abelReg, content);
#define ABEL_WRITE_INT(abelReg, content)      phy_write_spi_int     (abelReg, content);
#define ABEL_WRITE_INT_FAST(abelReg, content) phy_write_spi_int_fast(abelReg, content);


// Burst SPI Read/Write
#define ABEL_READ_BURST_L(abelReg, srcMem)      ABEL_READ           ((abelReg+0 | 0x80),((uint16_t*)srcMem)[0]); \
                                                ABEL_READ           ((abelReg+1 | 0x80),((uint16_t*)srcMem)[1]);
#define ABEL_READ_BURST_L_INT(abelReg, srcMem)  ABEL_READ_INT       ((abelReg+0 | 0x80),((uint16_t*)srcMem)[0]); \
                                                ABEL_READ_INT       ((abelReg+1 | 0x80),((uint16_t*)srcMem)[1]);

#define ABEL_WRITE_BURST_L(abelReg, srcMem)     ABEL_WRITE          (abelReg+0, ((uint16_t*)srcMem)[0]); \
                                                ABEL_WRITE          (abelReg+1, ((uint16_t*)srcMem)[1])
#define ABEL_WRITE_BURST_L_INT(abelReg, srcMem) ABEL_WRITE_INT      (abelReg+0, ((uint16_t*)srcMem)[0]); \
                                                ABEL_WRITE_INT      (abelReg+1, ((uint16_t*)srcMem)[1])


#endif /* _PHY_SPI_H_ */


