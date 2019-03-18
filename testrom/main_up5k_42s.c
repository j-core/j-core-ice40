#define LEDPORT (*(volatile unsigned long  *)0xabcd0000)
#define LCDDATA (*(volatile unsigned long  *)0xabcd0044)
#define LCDINST (*(volatile unsigned long  *)0xabcd0040)

#include "font5x7.h"

extern char version_string[];

char ram0[256]; /* working ram for CPU tests */

void
putstr (char *str)
{
  while (*str)
    {
      if (*str == '\n')
	uart_tx ('\r');
      uart_tx (*(str++));
    }
}

#ifndef NO_DDR

#define DDR_BASE 0x10000000
#define MemoryRead(A) (*(volatile int*)(A))
#define MemoryWrite(A,V) *(volatile int*)(A)=(V)

//SD_A  <= address_reg(25 downto 13);  --address row
//SD_BA <= address_reg(12 downto 11);  --bank_address
//cmd   := address_reg(6 downto 4);    --bits RAS & CAS & WE
int DdrInitData[] = {
// AddressLines    Bank        Command
#ifndef LPDDR
  (0x000 << 13) | (0 << 11) | (7 << 4),	//CKE=1; NOP="111"
  (0x400 << 13) | (0 << 11) | (2 << 4),	//A10=1; PRECHARGE ALL="010"
  (0x001 << 13) | (1 << 11) | (0 << 4),	//EMR disable DLL; BA="01"; LMR="000"
#ifndef DDR_BL4
  (0x121 << 13) | (0 << 11) | (0 << 4),	//SMR reset DLL, CL=2, BL=2; LMR="000"
#else
  (0x122 << 13) | (0 << 11) | (0 << 4),	//SMR reset DLL, CL=2, BL=4; LMR="000"
#endif
  (0x400 << 13) | (0 << 11) | (2 << 4),	//A10=1; PRECHARGE ALL="010" 
  (0x000 << 13) | (0 << 11) | (1 << 4),	//AUTO REFRESH="001"
  (0x000 << 13) | (0 << 11) | (1 << 4),	//AUTO REFRESH="001
#ifndef DDR_BL4
  (0x021 << 13) | (0 << 11) | (0 << 4)	//clear DLL, CL=2, BL=2; LMR="000"
#else
  (0x022 << 13) | (0 << 11) | (0 << 4)	//clear DLL, CL=2, BL=4; LMR="000"
#endif
#else	// LPDDR
  (0x000 << 13) | (0 << 11) | (7 << 4),	//CKE=1; NOP="111"
  (0x000 << 13) | (0 << 11) | (7 << 4),	//NOP="111" after 200 uS
  (0x400 << 13) | (0 << 11) | (2 << 4),	//A10=1; PRECHARGE ALL="010"
  (0x000 << 13) | (0 << 11) | (1 << 4),	//AUTO REFRESH="001"
  (0x000 << 13) | (0 << 11) | (1 << 4),	//AUTO REFRESH="001"
  (0x021 << 13) | (0 << 11) | (0 << 4),	//SMR CL=2, BL=2; LMR="000"
  (0x000 << 13) | (1 << 11) | (0 << 4),	//EMR BA="01"; LMR="000" Full strength full array
  (0x000 << 13) | (0 << 11) | (7 << 4)	//NOP="111" after ? uS
#endif
};

int
ddr_init (void)
{
  volatile int i, j, k = 0;
  for (i = 0; i < sizeof (DdrInitData) / sizeof (int); ++i)
    {
      MemoryWrite (DDR_BASE + DdrInitData[i], 0);
      for (j = 0; j < 4; ++j)
	++k;
    }
  for (j = 0; j < 100; ++j)
    ++k;
  k += MemoryRead (DDR_BASE);	//Enable DDR
  return k;
}

#endif /* NO_DDR */

void
led(int v)
{
  LEDPORT = v;
}

void
lcd_data(unsigned int v)
{
  while((LCDDATA) & 1) {led(0x81); led(0x82);}
  LCDDATA = v;
}

void
lcd_inst(unsigned int v)
{
  while((LCDDATA) & 1) {led(0x83); led(0x84);}
  LCDINST = v;
}

void
lcd_loc(unsigned int x, unsigned int y)
{
  lcd_inst(0xB0 | (y & 3));
  lcd_inst(0x10 | (((x*6) & 0xf0) >> 4));
  lcd_inst(0x00 |  ((x*6) & 0x0f));
}

void
lcd_puts(char *s)
{
  int i, j;
  unsigned char v[4];
  unsigned int *l = v;

  i = 0;
  for (;*s;s++) {
    for (j=0; j<6; j++) {
      v[i++] = j == 5 ? 0 : font[(*s - FONT5X7_START)*5 + j];
      if (i>3) {
        lcd_data(*l);
        i = 0;
      }
    }
  }
  for (;i<4;i++) v[i] = 0;
  lcd_data(*l);
}

unsigned char lcd_init[] = { 0x40, 0xA1, 0xC0, 0xA6, 0xA2, 0x2F, 0xF8, 0x00, 0x23, 0x81, 0x1F, 0xAC, 0x00, 0xAF, 0xFF };

void
main_sh (void)
{
  volatile int i;
  led(0x40);

  uart_set_baudrate ();
  led(0x042);

#ifndef NO_TESTS
  putstr ("CPU tests passed\n");
  led(0x043);
#endif

#ifndef NO_DDR
  putstr ("DDR Init\n");
  led(0x042);
  ddr_init ();
#endif /* NO_DDR */

  putstr ("GDB Stub for HS-2J0 SH2 ROM\n");
  putstr (version_string);
  led(0x50);

  for (i=0; lcd_init[i] != 0xff; i++) lcd_inst(lcd_init[i]);

  lcd_loc(0, 1);
  lcd_puts("Hello 123!");

  for (i=0; i<8; i++) {
    lcd_data(
              (1<<(i+0 )) |
              (1<<(i+8 )) |
              (1<<(i+16)) |
              (1<<(i+24)));
  }
  led(0x51);

  for (i=0; i<800; i++) {}
  led(0x55);
  for (i=0; i<800; i++) {}
  led(0xaa);

  for (;;) {
    for (i=0; i<1200000; i++) {}
    led(0x55);
    for (i=0; i<1200000; i++) {}
    led(0xaa);
  } 
}
