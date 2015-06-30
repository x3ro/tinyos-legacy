// Internal interface between ByteEEPROM and the PersistentLogger component
includes PageEEPROM;
interface IPersistent
{
  command result_t finishPage(eeprompage_t page, eeprompageoffset_t lastRecord);
  event result_t finishPageDone(result_t success);
}
