/* $Id: at32uc3b_pdca.h,v 1.1 2008/03/09 16:36:17 yuecelm Exp $ */

/* @author Mustafa Yuecel <mustafa.yuecel@alumni.ethz.ch> */

#ifndef __AT32UC3B_PDCA_H__
#define __AT32UC3B_PDCA_H__

#include "at32uc3b.h"

#define get_avr32_pdca_baseaddress(pdca)       (AVR32_PDCA_ADDRESS + (AVR32_PDCA_MAR1 * pdca))

#endif /*__AT32UC3B_PDCA_H__*/
