/**
 * Global definitions for Crossbow sensor boards.
 *
 * @file      xdb.h
 * @author    Martin Turon
 * @version   2004/8/1    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xdb.h,v 1.1 2005/03/31 07:51:06 husq Exp $
 */

#ifndef __XDB_H__
#define __XDB_H__

#include <libpq-fe.h>
#include "timestamp/timestamp.h"

PGconn *xdb_connect ();
PGconn *xdb_exit    (PGconn *conn);
int     xdb_execute (char *command);

char * xdb_get_table();
void   xdb_set_table(char *table);

#endif  /* __XDB_H__ */



