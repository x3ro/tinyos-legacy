configuration MotllePrimitives {
  provides interface MateBytecode as Primitives[uint16_t id];
} implementation {
  components OPputled, OPsettimer0;

  Primitives[0] = OPputled;
  Primitives[1] = OPsettimer0;
}
