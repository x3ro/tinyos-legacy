// $Id: SensorEnergyModel.nc,v 1.1 2010/06/25 11:17:10 pineapple_liu Exp $

/*
 * Copyright (c) 2010 Data & Knowledge Engineering Research Center,
 *                    Harbin Institute of Technology, P. R. China.
 * All rights reserved.
 */

/**
 * Sensor devices energy consumption model.
 *
 * @author LIU Yu <pineapple.liu@gmail.com>
 * @date   June 24, 2010
 */

interface SensorEnergyModel
{
    command double getReadEnergy(void);
}

