/**
 * MSP430-recommended method for generating random numbers using LCG
 * and the hardware multiplier.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module MSP430RandomLCG {
  provides interface Random;
}
implementation {

  enum {
    RANDOM_INC = 13849,
    RANDOM_MPY = 31821
  };

  uint16_t m_value;

  void init(uint16_t val) {
    m_value = val;
  }

  uint16_t next() {
    uint16_t _value;
    atomic {
     MPY = RANDOM_MPY;
     OP2 = m_value;
     m_value = RESLO;
     m_value += RANDOM_INC;
     _value = m_value;
    }
    return _value;
  }

  async command result_t Random.init() {
    init(TOS_LOCAL_ADDRESS);
    return SUCCESS;
  }

  async command uint16_t Random.rand() {
    return next();
  }

}
