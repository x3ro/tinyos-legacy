
typedef struct BitArray_t {
	uint32_t maxSize;
	uint8_t *items;
} BitArray_t;

typedef BitArray_t *BitArrayPtr;

// #define BITARRAY_SIZE(x) (sizeof(struct BitArray_t) + 1 + x/8)


