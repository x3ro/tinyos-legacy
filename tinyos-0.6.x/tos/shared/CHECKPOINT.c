/*
 * checkpoint.c - provide a reliable checkpoint to eeprom facility
 *
 * Authors: David Gay
 * History: created 12/19/01
 */

#include "tos.h"
#include "dbg.h"
#include "CHECKPOINT.h"

#define DBG(act) TOS_CALL_COMMAND(CHECKPOINT_LEDS)(led_ ## act)

typedef unsigned char bool;
#define FALSE 0
#define TRUE 1

typedef unsigned char u8;
typedef signed char i8;
typedef unsigned short u16;
typedef short i16;
typedef unsigned long u32;
typedef long i32;

#define COOKIE 0x6f776c73
#define EEPROM_LINE_SIZE 16
#define EEPROM_LINES 2048

#define MAX_DATA_SETS EEPROM_LINE_SIZE

static void dbgn(int i)
{
  if (i & 1)
    DBG(r_on);
  else
    DBG(r_off);
  if (i & 2)
    DBG(g_on);
  else
    DBG(g_off);
  if (i & 4)
    DBG(y_on);
  else
    DBG(y_off);
}

#define TOS_FRAME_TYPE CHECKPOINT_frame
TOS_FRAME_BEGIN(CHECKPOINT_frame) {
  u16 eeprom_base;
  u16 data_length;
  u8 ndata_sets;
  u8 no_header;

  u8 current_index;
  u8 free_data_set;
  u8 index[MAX_DATA_SETS];

  u8 eeprom_line[EEPROM_LINE_SIZE];
  u8 *read_dest;

  u8 *user_data;
  u16 user_bytes;
  u16 user_line;

  enum { s_init, 
	 s_load_config_1, s_load_config_2, s_load_config_3,
         s_ready,
	 s_reading,
	 s_writing, s_writing_index, s_writing_selector, s_writing_header } state;
}
TOS_FRAME_END(CHECKPOINT_frame);

#define HEADER_OFFSET 0
#define SELECTOR_OFFSET 1
#define INDEX_OFFSET 2
#define DATA_OFFSET 4

struct header {
  u32 cookie;
  u8 ndata_sets;
  u16 data_length;
};

static void set_state(int n)
{
  VAR(state) = n;
  /*dbgn(n);*/
}

static void memcpy(void *to, void *from, unsigned int n)
{
  char *cto = to, *cfrom = from;

  while (n--) *cto++ = *cfrom++;
}

static u16 lines_per_set(u16 data_length)
{
  return (data_length + EEPROM_LINE_SIZE - 1) / EEPROM_LINE_SIZE;
}

static void clear_data(void)
{
  u8 i;

  set_state(s_ready);
  VAR(current_index) = 0;
  VAR(free_data_set) = VAR(ndata_sets);
  VAR(no_header) = TRUE;

  for (i = 0; i < VAR(ndata_sets); i++)
    VAR(index)[i] = i;
  for (; i < MAX_DATA_SETS; i++)
    VAR(index)[i] = 42;

  TOS_SIGNAL_EVENT(INITIALISED)(TRUE);
}

static void load_config(void)
{
  set_state(s_load_config_1);
  VAR(read_dest) = VAR(eeprom_line);
  if (!TOS_CALL_COMMAND(READ_EEPROM)((short)(VAR(eeprom_base) + HEADER_OFFSET),
				     VAR(eeprom_line)))
      clear_data(); /* For TOSSIM */
}

static void load_config_1(void)
{
  struct header *config = (struct header *)VAR(eeprom_line);

  if (config->cookie != COOKIE ||
      config->ndata_sets != VAR(ndata_sets) ||
      config->data_length != VAR(data_length))
    {
      clear_data();
    }
  else
    {
      set_state(s_load_config_2);
      TOS_CALL_COMMAND(READ_EEPROM)((short)(VAR(eeprom_base) + SELECTOR_OFFSET),
				    VAR(eeprom_line));
    }
}

static void load_config_2(void)
{
  set_state(s_load_config_3);
  VAR(current_index) = VAR(eeprom_line)[0] != 0;
  VAR(read_dest) = VAR(index);
  TOS_CALL_COMMAND(READ_EEPROM)((short)(VAR(eeprom_base) + INDEX_OFFSET +
				VAR(current_index)), VAR(index));
}

static void load_config_3(void)
{
#if MAX_DATA_SETS >= 31
#error Code below limited to 31 data sets
#endif
  u32 free_sets = (1 << (VAR(ndata_sets) + 1)) - 1;
  u8 i, bitcount;
  bool valid = TRUE;
  u8 *line = VAR(index);
  u8 nsets = VAR(ndata_sets);

  for (i = 0; i < nsets; i++)
    if (line[i] > nsets)
      valid = FALSE;
    else
      free_sets &= ~(1 << line[i]);

  /* More sanity checking, unused entries should be 42 */
  for (; i < MAX_DATA_SETS; i++)
    if (line[i] != 42)
      valid = FALSE;

  /* Should be only one free bit in free_sets */
  bitcount = 0;
  for (i = 0; i <= nsets; i++)
    if (free_sets & (1 << i))
      {
	bitcount++;
	VAR(free_data_set) = i;
      }

  if (bitcount != 1)
    valid = FALSE;

  if (!valid)
    {
      clear_data();
    }
  else
    {
      set_state(s_ready);
      VAR(no_header) = FALSE;
      TOS_SIGNAL_EVENT(INITIALISED)(FALSE);
    }
}

char TOS_COMMAND(CHECKPOINT_INIT)(u16 eeprom_base, u16 data_length,
				  u8 ndata_sets)
{
  unsigned int nlines_per_set;

  set_state(s_init);

  VAR(eeprom_base) = eeprom_base;
  VAR(ndata_sets) = ndata_sets;
  VAR(data_length) = data_length;

  if (ndata_sets >= MAX_DATA_SETS)
    return 0;

  /* Truly egregious values will overflow */
  nlines_per_set = lines_per_set(data_length);
  if (eeprom_base + 4 + nlines_per_set * (ndata_sets + 1) >= EEPROM_LINES)
    return 0;

  TOS_CALL_COMMAND(CHECKPOINT_SUB_INIT)();

  load_config();
  return 1;
}

static void start_next_read(void)
{
  VAR(read_dest) = VAR(eeprom_line);
  TOS_CALL_COMMAND(READ_EEPROM)((short)VAR(user_line), VAR(read_dest));
}

static void process_read(void)
{
  if (VAR(user_bytes) < EEPROM_LINE_SIZE)
    {
      memcpy(VAR(user_data), VAR(read_dest), VAR(user_bytes));
      set_state(s_ready);
      TOS_SIGNAL_EVENT(READ_DONE)(1, VAR(user_data) + VAR(user_bytes) - VAR(data_length));
    }
  else
    {
      memcpy(VAR(user_data), VAR(read_dest), EEPROM_LINE_SIZE);
      VAR(user_data) += EEPROM_LINE_SIZE;
      VAR(user_bytes) -= EEPROM_LINE_SIZE;
      VAR(user_line)++;
      start_next_read();
    }
}

char TOS_COMMAND(READ)(u8 data_set, u8 *data)
{
  if (VAR(state) != s_ready || data_set >= VAR(ndata_sets))
    return 0;

  VAR(user_data) = data;
  VAR(user_bytes) = VAR(data_length);
  VAR(user_line) = VAR(eeprom_base) + DATA_OFFSET +
    VAR(index)[data_set] * lines_per_set(VAR(data_length));
  set_state(s_reading);
  start_next_read();

  return 1;
}

char TOS_EVENT(READ_EEPROM_DONE)(char *packet, char success)
{
  if (success && packet == (char *)VAR(read_dest))
    {
      switch (VAR(state))
	{
	case s_load_config_1:
	  load_config_1();
	  break;
	case s_load_config_2:
	  load_config_2();
	  break;
	case s_load_config_3:
	  load_config_3();
	  break;
	case s_reading:
	  process_read();
	default:
	  /* BUG */
	  break;
	}
    }
  return 1;
}

static void commit_write(void)
{
  /* Write new index */
  set_state(s_writing_index);
  TOS_CALL_COMMAND(WRITE_EEPROM)((short)(VAR(eeprom_base) + INDEX_OFFSET +
				 !VAR(current_index)), VAR(index));
}

static void write_selector(void)
{
  VAR(current_index) = !VAR(current_index);
  VAR(eeprom_line)[0] = VAR(current_index);
  set_state(s_writing_selector);
  TOS_CALL_COMMAND(WRITE_EEPROM)((short)(VAR(eeprom_base) + SELECTOR_OFFSET),
				 VAR(eeprom_line));
}

static void write_finished(void)
{
  VAR(no_header) = FALSE;
  set_state(s_ready);
  TOS_SIGNAL_EVENT(WRITE_DONE)(1, VAR(user_data) + VAR(user_bytes) - VAR(data_length));
}

static void write_header(void)
{
  if (VAR(no_header))
    {
      struct header *config = (struct header *)VAR(eeprom_line);

      config->cookie = COOKIE;
      config->ndata_sets = VAR(ndata_sets);
      config->data_length = VAR(data_length);
      set_state(s_writing_header);
      TOS_CALL_COMMAND(WRITE_EEPROM)((short)(VAR(eeprom_base) + HEADER_OFFSET),
				     VAR(eeprom_line));
    }
  else
    write_finished();
}

static void start_next_write(void)
{
  /* Writing data from beyond the user's array should be fine ? */
  /* minor worry: what happens at end of SRAM ? */
  TOS_CALL_COMMAND(WRITE_EEPROM)((short)VAR(user_line), VAR(user_data));
}

static void write_done(void)
{
  if (VAR(user_bytes) < EEPROM_LINE_SIZE)
    {
      commit_write();
    }
  else
    {
      VAR(user_line)++;
      VAR(user_data) += EEPROM_LINE_SIZE;
      VAR(user_bytes) -= EEPROM_LINE_SIZE;
      start_next_write();
    }
}

char TOS_COMMAND(WRITE)(u8 data_set, u8 *data)
{
  u8 old_free_set;

  if (VAR(state) != s_ready || data_set >= VAR(ndata_sets))
    return 0;

  set_state(s_writing);

  /* Update index */
  old_free_set = VAR(free_data_set);
  VAR(free_data_set) = VAR(index)[data_set];
  VAR(index)[data_set] = old_free_set;

  VAR(user_data) = data;
  VAR(user_bytes) = VAR(data_length);
  VAR(user_line) = VAR(eeprom_base) + DATA_OFFSET +
    old_free_set * lines_per_set(VAR(data_length));
  start_next_write();

  return 1;
}

char TOS_EVENT(WRITE_EEPROM_DONE)(char success)
{
  if (success)
    {
      switch (VAR(state))
	{
	case s_writing:
	  write_done();
	  break;
	case s_writing_index:
	  write_selector();
	  break;
	case s_writing_selector:
	  write_header();
	  break;
	case s_writing_header:
	  write_finished();
	  break;
	default:
	  /* BUG */
	  break;
	}
    }
  return 1;
}
