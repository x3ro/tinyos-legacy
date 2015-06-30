module XnpC
{
  provides interface Xnp;
  provides interface XnpConfig;
  provides interface StdControl;
  
}

implementation{

	command result_t StdControl.init() {return SUCCESS;}
	command result_t StdControl.start() {return SUCCESS;}
	command result_t StdControl.stop() {return SUCCESS;}

	command uint16_t XnpConfig.getProgramID() {return 0;}
	command result_t Xnp.NPX_DOWNLOAD_ACK(uint8_t cAck ) {return FAIL;} 
  	command result_t Xnp.NPX_SENDSTATUS(uint16_t wAck ) {return FAIL;}
   	command result_t Xnp.NPX_ISP_REQ(uint16_t wProgID, uint16_t wEEPageStart, uint16_t nwProgID) {return FAIL;}
    	command result_t Xnp.NPX_SET_IDS() {return FAIL;}
	default event result_t Xnp.NPX_DOWNLOAD_REQ(uint16_t wProgramID, uint16_t wEEStartP, uint16_t wEENofP) {return FAIL;}
      	default event result_t Xnp.NPX_DOWNLOAD_DONE(uint16_t wProgramID, uint8_t bRet, uint16_t wENofP) {return FAIL;}
	command void XnpConfig.saveGroupID() {}
}
