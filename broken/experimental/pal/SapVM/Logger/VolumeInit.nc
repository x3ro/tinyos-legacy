interface VolumeInit {
  command result_t init();
  event   void     initDone(storage_result_t result);
}
