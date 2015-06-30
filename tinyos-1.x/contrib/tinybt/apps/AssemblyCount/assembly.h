/*
  Assembly interface definitions. It is possible that these definitions should
  be somewhere else - in a interface file - but this works...

  Copyright (C) 2002 & 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>
  
  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/
#ifndef __ASSEMBLY_H__
#define __ASSEMBLY_H__
#include "btpackets.h"

/* Differentiate between the different devices 
   Per convention, device BT_DEV_0 is the _child_ device, 
   and bt_dev_1 is the _parent_ device. */
typedef enum { bt_dev_0 = 0x0, bt_dev_1 = 0x1 } btdevnum_t;

/* Data structure for information about connections */
typedef struct {
  /* State of this entry */
  enum {invalid, needAccept, connCompletePending, 
	connComplete, policyPending, policyComplete, 
	switchPending, connected} state; 
  btdevnum_t btdev; /* Device the connection is on */
  uint16_t handle;  /* Handle, if in connCompletePending++ state */
  bdaddr_t bdaddr;  /* Used for the needAccept action, valid if
		        needAccept++. NOTE, for PARENT_CONNECTION_NUM
		        (0) this is not valid untill connCompletePending++ */
} connectionInfo;

/* These are the same, but are used for different purposes.
   connectionInfos are used by the Assembly component, while connectionIds are
   the name the users of the Assembly interface uses for the same guys.
*/
typedef connectionInfo connectionId;

/* The maximum number of connections the Assembly layer supports */
#define MAX_NUM_CONNECTIONS 6

  /* An observation: We reserve the zero'th connection to the
     connection from the bluetooth child interface to its parent.  We can always
     fiddle with this later on, if we know we will never get a parent. */
#define PARENT_CONNECTION_NUM 0
#define FIRST_CHILD_NUM 1

/* Check if a connectionId pointer points to a connection that is valid */
inline bool isConnectionValid(connectionId * connection) { 
  return (connection->state == connected);
}
#endif
