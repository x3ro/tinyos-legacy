
generic configuration TaskBasicC()
{
  provides interface TaskBasic;
}
implementation
{
  components SchedulerBasicP;
  TaskBasic = SchedulerBasicP.TaskBasic[unique("TinySchedulerC.TaskBasic")];
}

