
includes app_header;

interface FileSystem
{
    //command result_t init();
    event void initDone(result_t res);

    command result_t lookup(char *fileName, fileptr_t *id);

    command result_t create(char *fileName);
    event void createDone(result_t res);

    command result_t delete(fileptr_t id);
    event void deleteDone(result_t res);

    command result_t move(fileptr_t id, char *fileName2);

    command uint16_t getLength(fileptr_t id);
    command result_t updateLength(fileptr_t id, uint16_t length);

    command result_t getFileData(fileptr_t id, file_header *ptr);
    command result_t updateFileData(fileptr_t id, file_header *ptr);
    event void updateFileDataDone(result_t res);

    command result_t flush();
    event void flushDone(result_t res);
}
