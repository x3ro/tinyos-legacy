/*									tab:4
 * parseschema.yacc
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:  Sam Madden

 Yacc definition for simple mote schema grammar.
 Uses parseschema.lex for lexical input.

 Program reads from standard input, produces on standard output a .h file
 which defines the statically initialized object "schema" which corresponds
 to a c-data structure representing the schema of this mote.

 Simple sample mote grammar:

 field {
       name : "temp"   #optional
       type : int
       units : farenheight
       min : 0
       max : 128
       bits : 8
       sample_cost : 10.0 J  #optional -- for use in costing
       sample_time : 10.0 ms #optional -- for use in costing
       input : adc4   #optional  :  read from adc channel 4
       direction : onrequest
 }

 The constants for input, units, sample_cost, and sample_time are defined in 
 units.h.
 
 Schema.h defines the data structure which will be filled in by the execution of
 this program.

*/

%{  //c-definitions for this program
#include <stdlib.h>

#define null 0
#define kMAX_FIELDS 4
  char *name = null, *units = null, *time_unit, *cost_unit, *input_type = null, *direction = null, *accessor = null, *response=null; 
 char *static_string = null;
int hasMax = 0, hasMin = 0;
int min = -1, max = -1, bits = -1, type = -1;
 float cost = -1, samp_time = -1;
 int numflds =0;
 char *prototypes[kMAX_FIELDS];
 char *responses[kMAX_FIELDS];
 char *types[kMAX_FIELDS];

 void write_file();  //generate the .h file for this schema
 void write_field(); //generate a single static initializer for a schema field
 void write_prototype(char *file_name, char *prototypes_file);  //write out the ACCESSORS.c file
 void write_component(char *file_name); //write out the ACCESSORS.comp file
%}

%start schema
%union { char *string;
	 int val;
	 int fval;
       }
%token <string> STRING
%token <val>  NUMBER BYTE_TYPE INT_TYPE LONG_TYPE STRING_TYPE FLOAT_TYPE DOUBLE_TYPE
%token <fval> FLOAT
%token LEFTBRAC RIGHTBRAC FIELD NAME TYPE UNITS MIN MAX BITS COST TIME INPUT COLON DIRECTION ACCESSOR RESPONSE

%%

schema : field schema | field
field : FIELD LEFTBRAC rows RIGHTBRAC {  
  printf ("writing %d \n", numflds); 
  fflush(stdout); 
  write_field();
  printf ("wrote %d \n", numflds); 
  fflush(stdout); 
}
rows: row rows | row
row: name | type | units | min | max | bits | cost | time | input | direction | accessor | response

name: NAME COLON STRING 
			{ if (name != null)
				yyerror("Duplicate field 'name' not allowed.");
			  name = malloc(strlen(yylval.string) + 1);
			  strcpy(name, $3);
			}


type: TYPE COLON typeid { if (type >= 0)
				yyerror("Duplicate field 'type' not allowed.");
                             type = yylval.val;
			    if (type < 0) yyerror("Unknown field type.");
			 }
units: UNITS COLON STRING { if (units != null)
				yyerror("Duplicate field 'units' not allowed.");
			    units = (char *)strdup( $3);
			 }
min: MIN COLON NUMBER { if (hasMin) 
				yyerror("Duplicate field 'min' not allowed.");
			     min = $3;
			     if (hasMax && max <= min)
				yyerror("Max must be greater than min.");
			     hasMin = 1;
			   }

max:MAX COLON NUMBER { if (hasMax) 
				yyerror("Duplicate field 'max' not allowed.");
			     max = $3;
			     if (hasMin && max <= min)
				yyerror("Max must be greater than min.");
			     hasMax = 1;
			   }
bits: BITS COLON NUMBER { if (bits > 0) 
				yyerror("Duplicate field 'bits' not allowed.");
			     bits = $3;
			     if (bits <= 0)
				yyerror("Bits must be greater than 0");
			   }
cost: COST COLON FLOAT STRING
			   { if (cost > 0)
				yyerror("Duplicate field 'sample_cost' not allowed.");
			     cost = $3;
			     cost_unit = (char *)strdup($4);
			     if (cost <= 0)
				yyerror("Cost must be greater than 0");
			   }

time: TIME COLON FLOAT STRING
			   { if (samp_time > 0)
				yyerror("Duplicate field 'sample_time' not allowed.");
			     samp_time = $3;
			     time_unit = (char *)strdup($4);
			     if (samp_time <= 0)
				yyerror("Sample time must be greater than 0");
			   }


input: INPUT COLON STRING { if (input_type != null)
				yyerror("Duplicate field 'input' not allowed.");
			     input_type = (char *)strdup($3);
			   }


direction: DIRECTION COLON STRING 
			   { if (direction != null)
				yyerror("Duplicate field 'direction' not allowed.");
			     direction = (char *)strdup($3);
			   }

accessor: ACCESSOR COLON STRING 
			   { if (accessor != null)
				yyerror("Duplicate field 'accessorEvent' not allowed.");
			     accessor = (char *)strdup($3);
			   }
response: RESPONSE COLON STRING
			   { if (response != null)
				yyerror("Duplicate field 'responseEvent' not allowed.");
			     response = (char *)strdup($3);
			   }

typeid: BYTE_TYPE {}
        | INT_TYPE {}
        | LONG_TYPE {}
        | STRING_TYPE {}
        | FLOAT_TYPE {}
        | DOUBLE_TYPE {}

	
%%
//functions to drive the parsing
#include "lex.yy.c"

int lineno = 1;
char *schemafile, *outfile, *accessors = null, *outaccessors = null;

main(int argc, char *argv[]) {
  int i;
  
  for (i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-h") == 0) {
      printf ("USAGE: parseschema schemafile outfile [accessors outaccessors]\n");
      printf ("  schemafile : File specifying mote schema \n");
      printf ("  outfile : .h file containing schema data structure \n");
      printf ("  accessors : .c file containing sensor access routines references in accessors fields of outfile\n");
      printf ("  outaccessors : .c file defining access routines for mote sensor readings \n");
      exit(1);
    }
  }
  if (argc < 3 || argc > 5) {
    printf ("Invalid number of arguments (%d).\n", argc);
    printf ("USAGE: parseschema schemafile outfile [outaccessors | accessors outaccessors]\n");
    exit(1);
  }
  
  schemafile = argv[1];
  outfile = argv[2];
  
  if (argc == 4) {
    outaccessors = argv[3];
  } else if (argc == 5) {    
    outaccessors = argv[4];
    accessors = argv[3];
  }
  
  for (i = 0; i < kMAX_FIELDS; i++) {
    prototypes[i] = (char *)malloc(1);
    prototypes[i][0] = 0;
    responses[i] = (char *)malloc(1);
    responses[i][0] = 0;
  }

  yyin = fopen(schemafile,"r");
  if (yyin == null) {
    printf("Couldn't open file '%s' for reading.\n", schemafile);
    exit(1);
  }
  //parse all the rows
  yyparse();

  //write the output (.h) file
  write_file(outfile);

  //if needed, write the .comp and .c files for the prototypes
  if (outaccessors != null) {
    char *componentFile;

    write_prototype(outaccessors,accessors);
    componentFile = malloc(strlen(outaccessors) + 4);
    strcpy(componentFile, outaccessors);
    strcat(componentFile, "omp");
    printf ("writing to %s\n", componentFile);fflush(stdout);
    write_component(componentFile);
  }
  fclose(yyin);
  exit(0);
}

/* Write the .comp file representing the
   events which are fired when this mote is queried
   and the handlers invoked to retrieve the results
   of sensor readings
*/
void write_component(char *file_name) {

  FILE *f;
  int i;

  f =  fopen(file_name,"w");
  if (f == null) {
    fprintf(stderr, "Couldn't open output file '%s'.", file_name);
    exit(1);
  }
  fprintf(f, "/*------------------------------------------------------------*/\n");
  fprintf(f, "/*   This file autogenerated by the TinyOS parseschema tool   */\n");
  fprintf(f, "/*------------------------------------------------------------*/\n");

  fprintf(f, "TOS_MODULE ACCESSORS;\n");
  fprintf(f, "ACCEPTS{\n");
  fprintf(f, "\tchar INIT();\n");
  fprintf(f, "};\n");

  fprintf(f, "SIGNALS{\n");

  fprintf(f, "};\n");
  fprintf(f, "HANDLES{\n");
  fprintf(f, "\tTOS_MsgPtr SENSOR_QUERY(TOS_MsgPtr msg);\n");
  fprintf(f, "\tTOS_MsgPtr SENSOR_QUERY_REPLY(TOS_MsgPtr msg);\n");	
  fprintf(f, "\tchar SENSOR_SUB_MSG_SEND_DONE(TOS_MsgPtr sentBuffer);\n");
  for (i = 0; i < numflds; i++) {
    fprintf(f, "\tchar %s(%s data);\n", responses[i], types[i]);
  }
  fprintf(f, "};\n");

  fprintf(f, "USES{\n");
  fprintf(f, "\tchar SENSOR_SUB_SEND_MSG(short addr,char type, TOS_MsgPtr data);\n");
  for (i = 0; i < numflds; i++) {
    fprintf(f, "\tchar %s();\n", prototypes[i]);
  }
  fprintf(f, "};\n");
  
  fclose(f);
}

/* Write the .c file representing routines to handle
   queries against this mote.
*/
void write_prototype(char *file_name, char *prototypes_file) {

  FILE *f;
  int i;


  f =  fopen(file_name,"w");
  if (f == null) {
    fprintf(stderr, "Couldn't open output file '%s'.", file_name);
    exit(1);
  }

  fprintf(f, "/*------------------------------------------------------------*/\n");
  fprintf(f, "/*   This file autogenerated by the TinyOS parseschema tool   */\n");
  fprintf(f, "/*------------------------------------------------------------*/\n");

  fprintf(f, "#include \"tos.h\"\n");
  fprintf(f, "#include \"SensorQuery.h\"\n");
  fprintf(f, "#include \"ACCESSORS.h\"\n");
  fprintf(f, "#include \"moteschema.h\"\n");

  fprintf (f, "SchemaRecord gMoteSchema = \n\t{%d,{\n%s\n\t}};\n", numflds, static_string);

  fprintf(f, "#define TOS_FRAME_TYPE ACCESSOR_frame\n");
  fprintf(f, "TOS_FRAME_BEGIN(ACCESSOR_frame) {\n");
  fprintf(f, "\tchar pending_query;\n");
  fprintf(f, "\tchar pending_data;\n");
  fprintf(f, "\tchar src;\n");
  fprintf(f, "\tchar fieldId;\n");
  fprintf(f, "\tTOS_Msg query_msg;\n");
  fprintf(f, "}\n");
  fprintf(f, "TOS_FRAME_END(ACCESSOR_frame);\n\n");

  fprintf(f, "char TOS_COMMAND(INIT)(){\n");
  fprintf(f, "\tVAR(pending_query) = 0;\n");
  fprintf(f, "\tVAR(pending_data) = 0;\n");
  fprintf(f, "\treturn 1;\n");
  fprintf(f, "}\n\n");

  fprintf(f, "TOS_MsgPtr TOS_EVENT(SENSOR_QUERY)(TOS_MsgPtr msg) {\n");
  fprintf(f, "\tif (!VAR(pending_query)) {\n");
  fprintf(f, "\t\tsensor_msg* message = (sensor_msg*)msg->data;\n");
  fprintf(f, "\t\tVAR(src) = message->src;\n");
  fprintf(f, "\t\tVAR(fieldId) = message->fieldId;\n");
  fprintf(f, "\t\tswitch (message->fieldId) {\n");
  for (i = 0; i < numflds; i++) {
    fprintf(f, "\t\tcase %d:\n",i);
    if (strlen(prototypes[i]) > 0) {
      fprintf(f, "\t\t\tTOS_CALL_COMMAND(%s)();\n",prototypes[i]);

    } else {
      //autogen prototype, or ?
      fprintf(f, "\t\t\t\\*INSERT PROTOTYPE TO RETRIEVE VALUE FOR FIELD %d HERE*\\\n", i);
    }
    fprintf(f, "\t\t\tVAR(pending_data) = 1;\n");	    
    fprintf(f, "\t\t\tbreak;\n");
  }
  fprintf(f, "\t\t}\n");

  fprintf(f, "\t}\n");
  fprintf(f, "\treturn msg;\n");
  fprintf(f, "}	\n\n");

  fprintf(f, "char TOS_EVENT(SENSOR_DATA)(char *data, int len) {\n");
  fprintf(f, "\tint i;\n");
  fprintf(f, "\tif (VAR(pending_data)) {\n");
  fprintf(f, "\t\tVAR(query_msg).data[0] = TOS_LOCAL_ADDRESS & 0x00FF;\n");
  fprintf(f, "\t\tVAR(query_msg).data[1] = (char)((TOS_LOCAL_ADDRESS & 0xFF00) >> 8);\n");
  fprintf(f, "\t\tVAR(query_msg).data[2] = VAR(fieldId);\n");
  fprintf(f, "\t\tfor (i = 0; i < len; i++)\n");
  fprintf(f, "\t\t\tVAR(query_msg).data[i + 3] = data[i];\n");
    fprintf(f, "\t\tif (TOS_COMMAND(SENSOR_SUB_SEND_MSG)(VAR(src), \n");
  fprintf(f, "\t\t\t\t\t\t AM_MSG(SENSOR_QUERY_REPLY),\n");
  fprintf(f, "\t\t\t\t\t\t &VAR(query_msg))) {\n");
  fprintf(f, "\t\t\tVAR(pending_query) = 1;\n");
  fprintf(f, "\t\t}\n");
  fprintf(f, "\t\tVAR(pending_data) = 0;\n");
  fprintf(f, "\t}\n");
  fprintf(f, "\treturn 1;\n");
  fprintf(f, "}	\n\n");      

  fprintf(f, "char TOS_EVENT(SENSOR_SUB_MSG_SEND_DONE)(TOS_MsgPtr sentBuffer){\n");
  fprintf(f, "\tif (VAR(pending_query) && sentBuffer == &VAR(query_msg)) {\n");
  fprintf(f, "\t\tVAR(pending_query) = 0;\n");
  fprintf(f, "\t}\n");
  fprintf(f, "\treturn 1;\n");
  fprintf(f, "}\n\n");

  fprintf(f, "TOS_MsgPtr TOS_EVENT(SENSOR_QUERY_REPLY)(TOS_MsgPtr sentBuffer){\n");
  fprintf(f, "\treturn sentBuffer;\n");
  fprintf(f, "}\n");

  if (prototypes_file != null)
    fprintf(f, "#include \"%s\"\n", prototypes_file);

  fclose(f);
}

/* write the header file */
void write_file(char *filename)  {
  FILE *outf = fopen(filename,"w");
  if (outf == null) {
    printf("Coudln't open file '%s' for writing.\n", filename);
  }
  fprintf (outf,"#ifndef __MOTESCHEMA__\n");
  fprintf (outf,"#define __MOTESCHEMA__\n");
  fprintf (outf,"#include \"tools/units.h\"\n");
  fprintf (outf,"#include \"tools/schema.h\"\n");

  fprintf (outf,"#define kHAS_SCHEMA\n");
  
  fprintf (outf, "extern SchemaRecord gMoteSchema; \n");
  fprintf (outf,"#endif\n");
  fclose(outf);

}

/* add information about a just-parsed field to the global variable static_string,
   which contains the partially built static-initialization string corresponding
   to the fields we've read so far.
*/
void write_field() {
  char str[512];
  char cost_str[100];
  char time_str[100];
  int start = 0, i;

  //make sure all the required rows are specified
  if (type == -1)
    yyerror("Required field 'type' not specified.\n"); 
  if (!hasMin)
    yyerror("Required field 'min' not specified.\n"); 
  if (!hasMax)
    yyerror("Required field 'max' not specified.\n"); 
  if (bits == -1)
    yyerror("Required field 'bits' not specified.\n"); 
  if (units == null)
    yyerror("Required field 'units' not specified.\n"); 
  if (direction == null)
    yyerror("Required field 'direction' not specified.\n"); 
  if (response == null && accessor != null) {
    yyerror("Field 'responseEvent' must be specified when 'accessorEvent' is specified.\n");
  }
  if (cost != -1) {
    sprintf(cost_str, "%f * %s", cost, cost_unit);
  }

  if (samp_time != -1) {
    sprintf(time_str, "%f * %s", samp_time, time_unit);
  }
  sprintf(str, "\t{0,%d,%s,%d,%d,%d,%s,%s,%s,\"%s\",%s},\n",
	  type, units, min, max, bits, (cost == -1)?"-1":cost_str,
	  (samp_time== -1)?"-1":time_str, (input_type == null)?"-1":input_type,
	  (name == null)?"\"\"":name,direction);

  if (static_string == null) {
    static_string = (char *)strdup(str);
  } else {
    static_string = realloc(static_string, strlen(static_string) + strlen(str) + 1);
    memcpy(static_string + strlen(static_string), str, strlen(str) + 1);
  }
  printf ("types"); fflush(stdout);
  switch (type) {
  case BYTE_TYPE:
    types[numflds] = "char"; break;
  case INT_TYPE:
    types[numflds] = (char *)"int"; break;
  case LONG_TYPE:
    types[numflds] = (char *)"long"; break;
  case FLOAT_TYPE:
    types[numflds] = (char *)"float"; break;
  case DOUBLE_TYPE:
    types[numflds] = (char *)"double"; break;
  default:
    types[numflds] = (char *)"int"; break;
  }
  if (accessor != null) {
    free(prototypes[numflds]);
    prototypes[numflds] = accessor;
    accessor = null;
  }
  if (response != null) {
    free(responses[numflds]);
    responses[numflds] = response;
    response = null;
  }
  numflds++;
  if (numflds > kMAX_FIELDS) {
    char error[100];
    sprintf(error, "Schema exceeds maximum number of fields (max = %d).", kMAX_FIELDS);
    yyerror(error);
  }

  //reset everything for the next row
  type = -1;
  hasMin = hasMax = 0;
  bits = -1;
  cost = -1;
  samp_time = -1;
  free(units);
  units = null;

  free(direction);
  direction = null;

  if (name != null) {
    free(name);
    name = null;
  }
  if (input_type != null) {
    free(input_type);
    input_type = null;
  }
  if (time_unit != null) {
    free(time_unit);
    time_unit = null;
    samp_time = -1;
  }
  if (cost_unit != null) {
    free(cost_unit);
    cost_unit = null;
    cost = -1;
  }
  
}

yyerror(char *s) {
	fprintf(stderr, "ERROR: %s ", s);
	fprintf(stderr, "line %d\n", lineno);
	exit(1);
}


