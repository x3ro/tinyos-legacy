/*
  M i n M a x M . n c

  $Id: MinMaxM.nc,v 1.1 2004/05/18 18:58:18 ssbapat Exp $

  (c) Copyright 2004 The MITRE Corporation (MITRE)

   Permission is hereby granted, without payment, to copy, use, modify,
   display and distribute this software and its documentation, if any,
   for any purpose, provided, first, that the US Government and any of
   its agencies will not be charged any license fee and/or royalties for
   the use of or access to said copyright software, and provided further
   that the above copyright notice and the following three paragraphs
   shall appear in all copies of this software, including derivatives
   utilizing any portion of the copyright software.  Use of this software
   constitutes acceptance of these terms and conditions.

   IN NO EVENT SHALL MITRE BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
   SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE
   OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF MITRE HAS BEEN ADVISED
   OF THE POSSIBILITY OF SUCH DAMAGE.

   MITRE SPECIFICALLY DISCLAIMS ANY EXPRESS OR IMPLIED WARRANTIES
   INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
   NON-INFRINGEMENT.

   THE SOFTWARE IS PROVIDED "AS IS."  MITRE HAS NO OBLIGATION TO PROVIDE
   MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

*/

module MinMaxM {
  provides interface MinMax;
}

implementation {

  /* Prototypes */

  task void DoItU8();
  task void DoIt16();

  /* Module fields */

  bool busy = FALSE;
  uint8_t *dataU8 = NULL;
  int16_t *data16 = NULL;
  uint16_t len;

  /*
    8-bit unsigned data type
  */

  /* Blocking implementation */

  command void MinMax.OpU8
    (uint8_t *dataArg, uint16_t lenArg, uint8_t *min, uint8_t *max)
  {
    uint8_t minValue, maxValue;
    uint16_t i;

    minValue = 255;
    maxValue = 0;

    for (i = 0; i < lenArg; i++) {
      if (dataArg[i] < minValue)
        minValue = dataArg[i];
      if (maxValue < dataArg[i])
        maxValue = dataArg[i];
    }

    *min = minValue;
    *max = maxValue;
  } // OpU8

  /* Non-blocking implementation */

  command result_t MinMax.StartU8(uint8_t *dataArg, uint16_t lenArg)
  {
    if (busy)
      return FAIL;

    busy = TRUE;
    dataU8 = dataArg;
    data16 = NULL;
    len = lenArg;
    post DoItU8();

    return SUCCESS;
  }

  /* Private methods */

  /* Task wrapper */

  task void DoItU8()
  {
    uint8_t min, max;

    call MinMax.OpU8(dataU8,len, &min,&max);
    signal MinMax.DoneU8(min,max);

    busy = FALSE;
  }

  /* Defalut methods */
  default event void MinMax.DoneU8(uint8_t minArg, uint8_t maxArg)
    { /* Nothing */ }

  /*
    16-bit signed data type
  */

  /* Blocking implementation */

  command void MinMax.Op16
    (int16_t *dataArg, int16_t lenArg, int16_t *min, int16_t *max)
  {
    int16_t i;
    int16_t minValue,maxValue;

    minValue = 32767;
    //    maxValue = -32768;
    maxValue = 0xffff;

    for (i = 0; i < lenArg; i++) {
      if (dataArg[i] < minValue)
        minValue = dataArg[i];
      if (maxValue < dataArg[i])
        maxValue = dataArg[i];
    }

    *min = minValue;
    *max = maxValue;
  }

  /* Non-blocking implementation */

  command result_t MinMax.Start16(int16_t *dataArg, int16_t lenArg)
  {
    if (busy)
      return FAIL;

    busy = TRUE;
    dataU8 = NULL;
    data16 = dataArg;
    len = lenArg;
    post DoIt16();

    return SUCCESS;
  }

  /* Private methods */

  task void DoIt16()
  {
    int16_t min, max;

    call MinMax.Op16(data16,len, &min,&max);
    signal MinMax.Done16(min,max);

    busy = FALSE;
  }

  /* Defalut methods */
  default event void MinMax.Done16(int16_t minArg, int16_t maxArg)
    { /* Nothing */ }
} // MinMaxM
