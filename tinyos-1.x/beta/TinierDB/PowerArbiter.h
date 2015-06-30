#ifndef _SR_PWR_ARBITER__
#define _SR_PWR_ARBITER__

// List the power-managed resources managed by the
// PowerArbiter
enum {
  PWR_RADIO = 0,
  PWR_SENSORB,

  // Leave this one last
  PWR_RESOURCE_MAX
};

#endif
