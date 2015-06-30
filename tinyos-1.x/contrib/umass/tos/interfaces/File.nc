
includes app_header;

interface File
{
    command result_t create(char *fileName);
    event void createDone(result_t res);

    command result_t delete(char *fileName);
    event void deleteDone(result_t res);

    command result_t move(char *fileName1, char *fileName2);

    command result_t open(char *fileName);
    event void openDone(result_t res);

    command result_t close();
    event void closeDone(result_t res);

    command result_t append(void *data, uint16_t length);
    event void appendDone(result_t res);

    command result_t readStart();
    command result_t readNext(void *data, uint16_t length, 
                              uint16_t *read_length);
    event void readDone(result_t res);

    command uint16_t length();

    command result_t flush();
    event void flushDone(result_t res);
}
