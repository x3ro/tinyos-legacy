
interface I2CSwitchCmds
{
       command result_t PowerSwitch(uint8_t PowerState);  
       /* 0 =>  power off; 1 =>  power on */

//notify that I2C power switch has been set.
//PowerState = 0 => power is off; PowerState = 1 => power is on
       event result_t SwitchesSet(uint8_t PowerState);                //notify that I2C switches are set 
}

