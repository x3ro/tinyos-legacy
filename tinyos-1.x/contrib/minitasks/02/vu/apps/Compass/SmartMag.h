typedef struct {
    uint16_t X;
    uint16_t Y;
    uint8_t  biasX;
    uint8_t  biasY;
} MagValue;

enum {
  SM_BIAS_CENTER = 800,
  SM_BIAS_SCALE = 32
};
