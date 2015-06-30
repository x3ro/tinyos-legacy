
module TestTaskSchedM
{
  provides interface StdControl;
  uses interface TaskSched as task_count_leds;
  uses interface Leds;
}
implementation
{
  int m_count;

  command result_t StdControl.init()
  {
    call Leds.init();
    m_count = 0;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call task_count_leds.queue();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  event void task_count_leds.fired()
  {
    call Leds.set( ++m_count );
    call task_count_leds.queue();
  }
}

