
includes TuningKeys;

module TuningFileM {
  provides {
    interface StdControl;
    interface Tuning;
  }
  uses {
    interface TestRun;
  }
} implementation {

  bool didinit = FALSE;

  struct {
    tuning_value_t value;
    bool set;
  } values[256];

  static void readFile() {
/*    FILE *myfd;
    char fname[512], line[512]; 
    uint32_t key, value;

    sprintf(fname, "tuning/mote%d", TOS_LOCAL_ADDRESS);
    myfd = fopen(fname, "r");
    if (myfd == NULL) {
      myfd = fopen("tuning/default", "r");
      if (myfd == NULL) {
	dbg(DBG_USR1, "TuningFile: readFile: Cannot open tuning file");
	return;
      }
    }

    didinit = TRUE;
    dbg(DBG_USR2, "TuningFile: readFile: Reading %s\n", fname);
    while (fgets(line, 512, myfd) != NULL) {
      if (line[0] == '#') continue;
      sscanf(line, "%d %d", &key, &value);
      call Tuning.set((tuning_key_t)key, (tuning_value_t)value);
      dbg(DBG_USR2, "TuningFile: key %d = %d\n", key, value);
    }
    fclose(myfd);*/
  }

  command result_t StdControl.init() {
    readFile();
    return SUCCESS;
  }
  command result_t StdControl.start() {
    tuning_value_t val = 0;
    call Tuning.get(KEY_TESTRUN_START_CODE, &val);
    call TestRun.startRun(val);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event void TestRun.runComplete(uint32_t code) {
    dbg(DBG_USR1, "TestRun: run complete: code %d\n", code);
  }

  default result_t command TestRun.startRun(tuning_value_t val) {
    return SUCCESS;
  }
  
  command result_t Tuning.set(tuning_key_t key, tuning_value_t value) {
    if (!didinit) readFile();
    values[key].value = value;
    values[key].set = TRUE;
    return SUCCESS;
  }

  command result_t Tuning.get(tuning_key_t key, tuning_value_t *value) {
    if (!didinit) readFile();
    if (values[key].set) {
      *value = values[key].value;
      return SUCCESS;
    } else {
      return FAIL;
    }
  }

  command result_t Tuning.getDefault(tuning_key_t key, tuning_value_t *value,
      tuning_value_t defaultValue) {
    if (!didinit) readFile();
    if (values[key].set) {
      *value = values[key].value;
      return SUCCESS;
    } else {
      values[key].value = defaultValue;
      values[key].set = TRUE;
      *value = defaultValue;
      return SUCCESS;
    }
  }

}
