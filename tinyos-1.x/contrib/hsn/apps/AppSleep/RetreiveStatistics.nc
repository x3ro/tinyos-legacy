/*									
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 */

/*
 * Authors:		Nithya Ramanathan
 *
 *
 */

/**
 * Generic Interface to report a countable event to the counter component
 */

includes PacketTypes;

interface RetreiveStatistics
{ 
  // Retreive current values of statistics counters
  command result_t Retreive(Statistics_t* stats);

  // Resets the counters 
  command result_t ResetStatistics();
}
