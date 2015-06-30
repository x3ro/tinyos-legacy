module AttrMergeM {
   provides interface StdControl;
   uses {
      interface AttrRegister;
      interface HSNValue;
   }
}
implementation {

   command result_t StdControl.init() {

      dbg(DBG_BOOT, ("MERGY is initialized.\n"));
      return call AttrRegister.registerAttr("merge", UINT16, 2);
   }

   command result_t StdControl.start(){
      return SUCCESS;
   }

   command result_t StdControl.stop() {
      return SUCCESS;
   }

   event result_t AttrRegister.getAttr
            (char *name, char *resultBuf, SchemaErrorNo *err) {
      *err = SCHEMA_RESULT_READY;
      *(uint16_t*)resultBuf = call HSNValue.getNumMerges();
      return SUCCESS;
   }

   event result_t AttrRegister.setAttr(char *name, char *attrVal) {
      return FAIL;
   }

   event result_t AttrRegister.startAttr() {
      return call AttrRegister.startAttrDone();
   }

   event void HSNValue.adjuvantValueReset() {
      return;
   }
} // end of implemnetation
