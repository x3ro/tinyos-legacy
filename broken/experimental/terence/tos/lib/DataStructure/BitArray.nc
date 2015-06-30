includes BitArray;
interface BitArray {
	command BitArrayPtr initBitArray(uint8_t emptyint[], uint8_t size);
	command uint8_t saveBitInArray(uint8_t bitIndex, uint8_t success, BitArrayPtr array);
	command uint8_t readBitInArray(uint8_t bitIndex, BitArrayPtr array);
	command uint8_t isEmpty(BitArrayPtr bitarray);
	command void print(BitArrayPtr bitarray);
}
