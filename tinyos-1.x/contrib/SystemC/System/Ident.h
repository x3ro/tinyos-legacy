
#ifndef _H_Ident_h
#define _H_Ident_h

enum
{
  IDENT_MAX_PROGRAM_NAME_LENGTH = 10,
};

typedef struct
{
  char program_name[IDENT_MAX_PROGRAM_NAME_LENGTH];  //name of the installed program
  uint16_t xnp_program_id;  //the network programming id
  uint16_t install_id;  //random id created once per installation
  uint32_t unix_time;  //the unix time that the program was compiled
} Ident_t;

#endif//_H_Ident_h

