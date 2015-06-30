// @author Jaein Jeong

includes sensorboard;
includes hardware;

module TestVHM
{
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as PreInitControl;
    interface SplitInit as Init;
  }
}

implementation
{
  command result_t StdControl.init() {
    call PreInitControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call PreInitControl.start();
    call Init.init();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event void Init.initDone() {

  }


}










