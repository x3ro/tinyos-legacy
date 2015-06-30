configuration GyroIDG300C 
{
    provides interface GyroIDG300;
} 
implementation 
{
    components GyroIDG300M;
    components Main, TimerC;
    
    GyroIDG300 = GyroIDG300M;

    Main.StdControl -> TimerC;
    GyroIDG300M.Timer -> TimerC.Timer[unique("Timer")];
}
