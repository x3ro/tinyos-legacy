interface ServiceControl {
  command error_t start();
  command error_t stop();
  command bool isRunning();
  command bool isStarting();
  command bool isStopping();
}



