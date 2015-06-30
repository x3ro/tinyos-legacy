// $Id: DataSource.h,v 1.2 2010/06/22 08:32:17 pineapple_liu Exp $

/*
 * Copyright (c) 2010 Data & Knowledge Engineering Research Center,
 *                    Harbin Institute of Technology, P. R. China.
 * All rights reserved.
 */

/**
 * HITDKE Synthetic DataSource (SDS).
 * 
 * @author LIU Yu <pineapple.liu@gmail.com>
 * @date   Jun 21, 2010
 */

#ifndef __HITDKE_DATA_SOURCE_H__
#define __HITDKE_DATA_SOURCE_H__

#ifdef __cplusplus
extern "C"
{
#endif

typedef struct
{
    int __unused__;
} DataSource;

typedef struct
{
    unsigned int count;
    int __unused__;
} RecordSet;

#ifdef __cplusplus
}
#endif

#endif /* __HITDKE_DATA_SOURCE_H__ */


