//Mohammad Rahimi
interface Sampler {
    command result_t done(char *msg);
    event result_t dataReady(char *dataBuf, uint8_t length);
}
