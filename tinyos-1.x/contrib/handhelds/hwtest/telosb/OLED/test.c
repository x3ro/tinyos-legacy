#include <stdio.h>

typedef unsigned char uint8_t;

main()
{
  int i;  
  uint8_t color;
  uint8_t c;
  int j;
  int row;
  

  printf("HLINE\n");  
  c = 0x0f;
  for(i=0; i < 31; i++){
    color = (c<<4)|c;      
    printf("i=%d)  c=0x%x color = 0x%x \n",i,c,color);    
    if (i < 15)
      c--;
    else
      c++;
    
  }

  printf("\n\nVLINE\n");  
  for (row = 0; row < 64; row++){
    c = 0x0f;
#if 0
    send_lcd_cmd(LCD_ROW_SET);
    send_lcd_cmd(row);
    send_lcd_cmd(63);
#endif

    for(i=0; i < 32; i++){
      color = (c<<4)|c;      
      if (i < 15)
        c--;
      else if (i==15)
        c=0;
      else
        c++;

      printf("row=%d  i=%d  c=0x%x color = 0x%x \n",row,i,c,color);    
      //set_lcd_byte(color);
    }
  }
      

  
}

