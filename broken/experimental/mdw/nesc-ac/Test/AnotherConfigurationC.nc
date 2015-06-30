configuration AnotherConfigurationC {
  provides interface TestIF;
} implementation {
  components AbstractTestM(42);

  TestIF = AbstractTestM;
}
