includes GridTreeMsg;

module ParTunerM
{
	provides{
		interface StdControl;
		  }
	uses{
		interface BroadcastingNP;
	    }
}

implementation{

command result_t StdControl.init(){
	return SUCCESS;
}

command result_t StdControl.start(){
	return SUCCESS;
}
command result_t StdControl.stop(){
	return SUCCESS;
}

event result_t BroadcastingNP.setLocalParameters(uint8_t vnum, netParam plist){
  
  	return SUCCESS;
}
} 	