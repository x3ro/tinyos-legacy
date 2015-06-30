#ifndef _FONT_H_
#define _FONT_H_

/******************************************************************************
 * MSP-FET430P140 - Metro Clip ADC Demo 
 * Based on TI example code, performs ADC12 conversion on AN0 and outputs to
 * Breakout of the lcd code

 * Benjamin Kuris
 * Hewlett-Packard 
 * 2003
 * Built with IAR Embedded Workbench Version: 2.31E
 ****************************************************************************/
#if defined (MANY_FONTS)
#include "Helvetica_Medium_R_10.h"
#include "Helvetica_Medium_O_10.h"
#include "Helvetica_Medium_R_12.h"
#include "Helvetica_Medium_O_12.h"
#include "Helvetica_Medium_R_14.h"
#include "Helvetica_Medium_R_18.h"
#include "Helvetica_Medium_R_24.h"



  
const static struct FONT  *MWfonts[] = {
  &Helvetica_Medium_R_10_font,
  &Helvetica_Medium_O_10_font,
  &Helvetica_Medium_R_12_font,
  &Helvetica_Medium_O_12_font,
  &Helvetica_Medium_R_14_font,
  &Helvetica_Medium_R_18_font,
  &Helvetica_Medium_R_24_font

};
#else
#include "Helvetica_Medium_R_12.h"
#include "Helvetica_Medium_R_18.h"

const static struct FONT  *MWfonts[] = {
  &Helvetica_Medium_R_12_font,
  &Helvetica_Medium_R_18_font

};


#endif





#endif // _FONT_H_
