//$Id: IdentM.nc,v 1.10 2005/07/28 20:33:12 gtolle Exp $

includes Ident;
includes Attrs;

module IdentM {

  provides {
    interface StdControl;

    interface Attr<uint16_t> 
      as AMAddress @nucleusAttr("AMAddress", ATTR_AMAddress);
    interface AttrSet<uint16_t> 
      as AMAddressSet @nucleusAttr("AMAddress", ATTR_AMAddress);

    interface Attr<uint8_t> 
      as AMGroup @nucleusAttr("AMGroup", ATTR_AMGroup);
    interface AttrSet<uint8_t> 
      as AMGroupSet @nucleusAttr("AMGroup", ATTR_AMGroup);

    interface Attr<programName_t> 
      as ProgramName @nucleusAttr("ProgramName", ATTR_ProgramName);
    interface Attr<uint32_t> 
      as ProgramCompilerID @nucleusAttr("ProgramCompilerID", ATTR_ProgramCompilerID);
    interface Attr<uint32_t> 
      as ProgramCompileTime @nucleusAttr("ProgramCompileTime", ATTR_ProgramCompileTime);

#ifdef PLATFORM_TELOSB
    //    interface Attr<hardwareID_t>
    //      as HardwareID @nucleusAttr(ATTR_HardwareID);
#endif
  }
  
#ifdef PLATFORM_TELOSB
  //  uses interface DS2411;
#endif
  
}

implementation {

  command result_t StdControl.init() {
#ifdef PLATFORM_TELOSB
    //    call DS2411.init();
#endif
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t AMAddress.get(uint16_t* buf) {
    memcpy(buf, &TOS_LOCAL_ADDRESS, sizeof(TOS_LOCAL_ADDRESS));
    signal AMAddress.getDone(buf);
    return SUCCESS;
  }

  command result_t AMAddressSet.set(uint16_t* buf) {
    memcpy(&TOS_LOCAL_ADDRESS, buf, sizeof(TOS_LOCAL_ADDRESS));
    signal AMAddressSet.setDone(buf);
    return SUCCESS;
  }
  
  command result_t AMGroup.get(uint8_t* buf) {
    memcpy(buf, &TOS_AM_GROUP, sizeof(TOS_AM_GROUP));
    signal AMGroup.getDone(buf);
    return SUCCESS;
  }

  command result_t AMGroupSet.set(uint8_t* buf) {
    memcpy(&TOS_AM_GROUP, buf, sizeof(TOS_AM_GROUP));
    signal AMGroupSet.setDone(buf);
    return SUCCESS;
  }

  command result_t ProgramName.get(programName_t *buf) {
    strncpy(buf->programName, G_Ident.program_name, sizeof(programName_t));
    signal ProgramName.getDone(buf);
    return SUCCESS;
  }

  command result_t ProgramCompileTime.get(uint32_t *buf) {
    memcpy(buf, &G_Ident.unix_time, sizeof(uint32_t));
    signal ProgramCompileTime.getDone(buf);
    return SUCCESS;
  }
  
  command result_t ProgramCompilerID.get(uint32_t *buf) {
    memcpy(buf, &G_Ident.user_hash, sizeof(uint32_t));
    signal ProgramCompilerID.getDone(buf);
    return SUCCESS;
  }

#if defined(PLATFORM_TELOSB)
  /*
  command result_t HardwareID.get(hardwareID_t *buf) {
    call DS2411.copy_id((uint8_t*) buf);
    signal HardwareID.getDone(buf);
    return SUCCESS;
  }
  */
#endif
}


