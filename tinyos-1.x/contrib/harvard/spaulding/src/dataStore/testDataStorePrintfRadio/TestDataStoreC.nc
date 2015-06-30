#include "PrintfUART.h"
#include "PrintfRadio.h"

configuration TestDataStoreC 
{
} 
implementation 
{
    components Main, TestDataStoreM, LedsC;
    Main.StdControl -> TestDataStoreM;
    TestDataStoreM.Leds -> LedsC;

    components TimerC;
    Main.StdControl -> TimerC;
    TestDataStoreM.Timer -> TimerC.Timer[unique("Timer")];

    components DataStoreC;
    Main.StdControl -> DataStoreC;
    TestDataStoreM.DataStore -> DataStoreC;

    components PrintfRadioC;
    TestDataStoreM.PrintfRadio -> PrintfRadioC;   
}


