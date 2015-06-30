module testTsyncM
{
  provides interface StdControl;
  uses interface StdControl as TsyncControl;
}
implementation
{
  command result_t StdControl.init() {
    return call TsyncControl.init();
    }
  command result_t StdControl.start() {
    return call TsyncControl.start();
    }
  command result_t StdControl.stop() {
    return call TsyncControl.stop();
    }
}
