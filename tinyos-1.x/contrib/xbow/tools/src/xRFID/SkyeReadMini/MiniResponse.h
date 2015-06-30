/**
 * Handles conversion to engineering units of SkyeRead Mini packets.
 *
 * @file      MiniResponse.h
 * @author    Michael Li
 *
 * @version   2004/9/14    mli      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: MiniResponse.h,v 1.1 2005/03/31 07:51:06 husq Exp $
 */

#ifndef MINI_RESPONSE_H
#define MINI_RESPONSE_H

#include "SkyeReadMini.h"

// parses mini response packets
void skyeread_mini_print_parsed (uint8_t *packet);
void skyeread_mini_print_cooked (uint8_t *packet); 
void skyeread_mini_initialize ();

#endif
