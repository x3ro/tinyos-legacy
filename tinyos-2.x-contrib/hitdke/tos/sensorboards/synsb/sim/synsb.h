// $Id: synsb.h,v 1.5 2010/06/25 14:03:30 pineapple_liu Exp $

/*
 * Copyright (c) 2010 Data & Knowledge Engineering Research Center,
 *                    Harbin Institute of Technology, P. R. China.
 * All rights reserved.
 */

/**
 * Demo sensor for synthetic sensorboard.
 *
 * @author LIU Yu <pineapple.liu@gmail.com>
 * @date   Jun 18, 2010
 */

#ifndef __SYNSB_H__
#define __SYNSB_H__

#ifdef TOSSIM
#include <sim_synsb.h>
#else
#error "This sensorboard *synsb* only compiles in TOSSIM DB mode (aka. "sim", "sim-sf", etc.)."
#endif

#endif /* __SYN_SB_H__ */

