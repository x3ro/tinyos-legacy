// $Id: sim_synsb.c,v 1.3 2010/06/25 14:22:34 pineapple_liu Exp $

/*
 * Copyright (c) 2010 Data & Knowledge Engineering Research Center,
 *                    Harbin Institute of Technology, P. R. China.
 * All rights reserved.
 */

/**
 * Local wrappers for the Synthetic DataSource (SDS) library routines.
 *
 * @author LIU Yu <pineapple.liu@gmail.com>
 * @date   June 24, 2010
 */

#include <sim_synsb.h>          /* struct sim_{time,event}_t */


static DataSource theDS;        /* global singleton data source object */


int
sim_synsb_initDataSource(bool forceConnect)
{
    static bool isConnected = false;
    
    if (!isConnected || forceConnect)
    {
        static char theDSDFile[] = SIM_SYNSB_DSD;
        printf("about to open file: %s\n", theDSDFile);
        
        /* TODO: connect to DataSource */
        
        isConnected = true;     /* avoid re-initialize */
    }
    
    return 0;
}


int 
sim_synsb_mapSensorId(const char * sensorName)
{
    return 0;
}


SensorValue 
sim_synsb_queryDataSource(sim_time_t readTime, int nodeId, int sensorId)
{
    SensorValue sv = {0, 0};

    /* TODO */

    return sv;
}

