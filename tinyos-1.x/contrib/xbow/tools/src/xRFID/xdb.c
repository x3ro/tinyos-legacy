/**
 * Utility functions for database logging.
 *
 * @file      xdb.c
 * @author    Martin Turon
 *
 * @version   2004/7/29    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xdb.c,v 1.1 2005/03/31 07:51:06 husq Exp $
 */

#include <libpq-fe.h>

static char *g_server = "localhost";       //!< Postgres server IP or hostname 
static char *g_port   = "5432";            //!< Postgres server port
static char *g_user   = "tele";            //!< Postgres server user
static char *g_passwd = "tiny";            //!< Postgres server password
static char *g_dbname = "task";            //!< Postgres database to use
static char *g_table  = "enviro_results";  //!< Postgres table to use

char * xdb_get_table()            { return g_table; }
void   xdb_set_table(char *table) { g_table = table; }

PGconn *xdb_exit(PGconn *conn)
{
    PQfinish(conn);
    return NULL;
}

/** 
 * Connect to Postgres with the current settings through libpq.
 *
 * @author    Martin Turon
 *
 * @return    Error code from Postgres after executing command
 *
 * @version   2004/8/8       mturon      Initial version
 *
 */
PGconn *xdb_connect() 
{
     char       *pgoptions, *pgtty;
     PGconn     *conn;
 
     /*
      * begin, by setting the parameters for a backend connection if the
      * parameters are null, then the system will try to use reasonable
      * defaults by looking up environment variables or, failing that,
      * using hardwired constants
      */
     pgoptions = NULL;           /* special options to start up the backend
                                  * server */
     pgtty = NULL;               /* debugging tty for the backend server */
 
     /* make a connection to the database */
     conn = PQsetdbLogin(g_server, g_port, pgoptions, pgtty, 
			 g_dbname, g_user, g_passwd);
     /*
      * check to see that the backend connection was successfully made
      */
     if (PQstatus(conn) == CONNECTION_BAD)
     {
         fprintf(stderr, "error: Connection to database '%s' failed.\n", 
		 g_dbname);
         fprintf(stderr, "%s", PQerrorMessage(conn));
         conn = xdb_exit(conn);
     }
     
     return conn;
}

/** 
 * Executes the given SQL command through the Postgres library (libpq)
 *
 * @author    Martin Turon
 *
 * @return    Error code from Postgres after executing command
 *
 * @version   2004/8/8       mturon      Initial version
 *
 */
int xdb_execute(char *command)
{
    int errno = 0;
    PGconn *conn = xdb_connect();
    PQsendQuery(conn, command);
    PGresult *res = PQgetResult(conn);
    printf("%s\n", command);
    while (res != NULL)
    {
	errno = PQresultStatus(res); 
	if (errno > 1) 
	    fprintf(stderr, "error: INSERT command failed: %i\n", errno);
	res = PQgetResult(conn);
	PQclear(res);
    }
    /* close the connection to the database and cleanup */
    PQfinish(conn);
    return errno;
}

