
interface GyroIDG300
{   
    command void init();
    event void initDone(result_t result);

    command void enable();
    command void disable();
}

