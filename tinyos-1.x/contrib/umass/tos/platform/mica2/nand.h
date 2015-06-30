/*
 * file:        nand.h
 * description: pin assignments for NAND flash board.
 *              wired: /CE -- ADC6    CLE -- ADC0
 *                     ALE -- ADC1    /WE -- ADC2  /WP -- ADC3
 *                     /RE -- ADC5    RY/BY -- INT1
 */

#define OLD_NAND

TOSH_ASSIGN_PIN(NAND_CE, F, 6);
TOSH_ASSIGN_PIN(NAND_CLE, F, 0);
TOSH_ASSIGN_PIN(NAND_ALE, F, 1);

#ifdef OLD_NAND
//old board pin assignments
TOSH_ASSIGN_PIN(NAND_WE, D, 0);
TOSH_ASSIGN_PIN(NAND_RE, D, 1);
TOSH_ASSIGN_PIN(NAND_RY, E, 5);
#endif

#ifdef NEW_NAND_WIRE
//new board with modified assignments
TOSH_ASSIGN_PIN(NAND_WE, F, 2);
TOSH_ASSIGN_PIN(NAND_RE, F, 5);
TOSH_ASSIGN_PIN(NAND_RY, B, 6);
#endif

#ifdef NEW_NAND
//new board without modifications
TOSH_ASSIGN_PIN(NAND_WE, F, 2);
TOSH_ASSIGN_PIN(NAND_RE, F, 5);
TOSH_ASSIGN_PIN(NAND_RY, D, 1);
#endif

TOSH_ASSIGN_PIN(NAND_WP, F, 3);


static inline void MAKE_PWBUS_OUTPUT() { outp(0xff, DDRC); }
static inline void MAKE_PWBUS_INPUT() { outp(0, DDRC); }
static inline uint8_t READ_PWBUS() { return inp(PINC); }
static inline void WRITE_PWBUS(uint8_t val) { outp(val, PORTC); }

enum {
    NAND_DATA_IN = 0x80,
    NAND_PROGRAM = 0x10,
    NAND_READ_1 = 0x00,
    NAND_READ_2 = 0x01,
    NAND_READ_3 = 0x50,
    NAND_RESET = 0xFF,
    NAND_ERASE = 0x60,
    NAND_ERASE_CONFIRM = 0xD0,
    NAND_STATUS = 0x70,
    NAND_ID_READ = 0x90
};

