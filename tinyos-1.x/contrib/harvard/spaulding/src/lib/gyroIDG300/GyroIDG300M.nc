module GyroIDG300M 
{
    provides interface GyroIDG300;
    uses interface Timer;
}
implementation 
{
    // NOTE: On Shimmer, the Gyro board enable/disable pin is the
    // same as the BSL_TX pin!        
    enum {PIN_MAKE_DELAY = 500};

    
    command void GyroIDG300.init()
    {
TOSH_ASSIGN_PIN(GYRO_PWREN_N, 1, 1);
TOSH_MAKE_GYRO_PWREN_N_OUTPUT();
TOSH_SEL_GYRO_PWREN_N_IOFUNC();
TOSH_CLR_GYRO_PWREN_N_PIN();  // active low
signal GyroIDG300.initDone(SUCCESS);

    }

    command void GyroIDG300.enable()
    {        
    }

    command void GyroIDG300.disable()
    {
    }

    event result_t Timer.fired()
    {
        return SUCCESS;
    }                                       
}




