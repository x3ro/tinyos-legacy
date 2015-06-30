////////////////////////////////////////////////////////////////////////////
//
// CENS
//
// Contents: 
//
// Purpose: 
//
////////////////////////////////////////////////////////////////////////////
//
// $Id: EssDefs.h,v 1.1.1.2 2004/03/06 03:01:06 mturon Exp $
//
// $Log: EssDefs.h,v $
// Revision 1.1.1.2  2004/03/06 03:01:06  mturon
// Initial import.
//
// Revision 1.1.1.1  2003/06/12 22:11:28  mmysore
// First check-in of TinyDiffusion
//
// Revision 1.7  2003/05/09 21:32:21  eoster
// Increased period for neighbor list to 180 seconds (on the same order as the
// neighbor list logic's period.
//
// Revision 1.6  2003/05/09 19:39:34  eoster
// Unifed types for TinyDiff.
//
// Revision 1.5  2003/05/08 00:47:46  eoster
// Touched up formatting, and added support for configurable state.
//
// Revision 1.4  2003/05/06 04:19:52  mmysore
// Checking in first-cut working versions of EssM, EssFilter and EssTest;
// Small modifications to OnePhasePull
//
// Revision 1.3  2003/04/30 22:43:24  eoster
// Added enums.
//
// Revision 1.2  2003/04/29 01:32:23  eoster
// EMO
//
// Revision 1.1  2003/04/25 23:23:54  eoster
// Initial checkin
//
////////////////////////////////////////////////////////////////////////////

#ifndef _ESS_DEFS_H
#define _ESS_DEFS_H

#include "OnePhasePull.h"

enum
{
  ESS_MAX_CLUSTER_HEADS = 10,
  ESS_MAX_NEIGHBORS = 10
};

enum
{
  ESS_DEFAULT_MAX_HOPS = 10
};

enum
{
  ESS_DEFAULT_MAX_LOAD_FACTOR = 10
};

enum
{
  ESS_EMPTY = 0xFFFF
};

enum
{
  ESS_NUM_HOPS_METRIC = 0,
  ESS_LOAD_FACTOR_METRIC,
  ESS_NUM_METRICS
};

// Mohan's note: is this being used? can we remove it.
enum
{
  ESS_LOAD_FACTOR = 0,
  ESS_NUM_HOPS
};

enum
{
  // a small multiple of interest transmission interval -- so that we can
  // handle care of lost beacons and not send data packets with 0 clusterhead
  // id and have it dropped since it doesn't match any interest...
  ESS_CH_TIMEOUT = DFLT_INTEREST_EXP_TIME * 2 ,
  ESS_ADJ_LIST_PERIOD = 180
};

enum
{
  ESS_ATTR_BUFF_SIZE = MAX_ATT
};

// These are the key values for TinyDiffusion.
enum
{
  ESS_ADJ_LIST_KEY = 20,
  ESS_BATTERY_KEY
};

struct ClusterHead_s
{
  // Mohan's note: id has to be a 16bit unsigned
  uint16_t m_iId;
  int8_t m_iLoad;
  int8_t m_iNumHops;
  uint8_t m_iLast;
};

#endif
