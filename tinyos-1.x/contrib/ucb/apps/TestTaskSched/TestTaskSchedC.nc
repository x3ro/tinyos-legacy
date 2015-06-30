
configuration TestTaskSchedC
{
}
implementation
{
  components TelosMain2 as Main, TestTaskSchedM, TaskSchedC, LedsC;

  Main.TaskControl -> TaskSchedC;
  Main.StdControl -> TestTaskSchedM;

  TestTaskSchedM.task_count_leds -> TaskSchedC.TaskSched[unique("TaskSched")];
  TestTaskSchedM.Leds -> LedsC;
}

