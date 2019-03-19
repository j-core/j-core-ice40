#define KEYPORT (*(volatile unsigned long  *)0xabcd0000)
#define KEY_PRECHARGE 0xC0
#define KEY_ON        0x80

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
key_wait()
{
  volatile int i;

  KEYPORT = KEY_PRECHARGE;
  for (i=0; i<100; i++) {}

  KEYPORT = 0;
  while((KEYPORT & 0x7f) == 0x7f) {}
  KEYPORT = KEY_PRECHARGE;
}

int
key()
{
  volatile int i;
  int b;

  KEYPORT = KEY_PRECHARGE;
  for (i=0; i<10; i++) {}

  for (b=0; b<6; b++) {
    KEYPORT = 0x3f ^ (1<<b);
    for (i=0; i<10; i++) {}
    if ((KEYPORT & 0x7f) != 0x7f) return (b<<4) | (KEYPORT & 0x7f);
  }
  return 0;
}

char hv[9];
char *
hex(unsigned int v)
{
  int n;

  for (n=8; n; n--)
    hv[8-n] = ((v>>(4*(n-1))) & 0xf) > 0x9 ? 'A' + ((v>>(4*(n-1))) & 0xf) - 0xa : '0' + ((v>>(4*(n-1))) & 0xf); 
  hv[8] = 0;

  return hv;
}

void
lcd_data(unsigned int v)
{
  while((LCDDATA) & 1) {;}
  LCDDATA = v;
}

void
lcd_inst(unsigned int v)
{
  while((LCDDATA) & 1) {;}
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

  uart_set_baudrate ();

#ifndef NO_TESTS
  putstr ("CPU tests passed\n");
#endif

#ifndef NO_DDR
  putstr ("DDR Init\n");
  ddr_init ();
#endif /* NO_DDR */

  putstr ("GDB Stub for HS-2J0 SH2 ROM\n");
  putstr (version_string);

  for (i=0; lcd_init[i] != 0xff; i++) lcd_inst(lcd_init[i]);

  lcd_loc(0, 1);
  lcd_puts("Hit a Key!");
#if 0
  key_wait();
  key();

  lcd_loc(0, 1);
  lcd_puts("Hello 123!");

  lcd_loc(0, 0); lcd_puts(hex(0x123ab678));
#endif
  for (i=0; i<8; i++) {
    lcd_data(
              (1<<(i+0 )) |
              (1<<(i+8 )) |
              (1<<(i+16)) |
              (1<<(i+24)));
  }
  for (;;) {
#if 0
    key_wait();
    lcd_loc(0,1); lcd_puts("Key...");
    lcd_loc(0,2); lcd_puts(hex(key()));
#endif
  }
}
