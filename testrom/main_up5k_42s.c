#define KEYPORT (*(volatile unsigned long  *)0xabcd0000)
#define KEY_PRECHARGE 0xC0
#define KEY_ON        0x80

#define LCDDATA (*(volatile unsigned long  *)0xabcd0044)
#define LCDINST (*(volatile unsigned long  *)0xabcd0040)

#include "font5x7.h"

extern char version_string[];

char ram0[256]; /* working ram for CPU tests */

void
led(unsigned long v)
{
   KEYPORT = v;
}

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

void
key_wait()
{
  volatile int i;

  KEYPORT = KEY_PRECHARGE;
  for (i=0; i<10; i++) {}
putstr("key wait...");
  KEYPORT = 0;
  while((KEYPORT & 0x7f) == 0x7f) {}
putstr(" detect\n");
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

int march(void *base, int addrs, int sz);

void
main_sh (void)
{
  volatile int i;
  unsigned int stat = 0x50;

  KEYPORT = KEY_PRECHARGE;

  uart_set_baudrate ();

#ifndef NO_TESTS
  putstr ("CPU tests passed\n");

  putstr ("GDB Stub for HS-2J0 SH2 ROM\n");
  putstr (version_string);
#endif

  led(0xe1);

  if (march((void *)0x10000000, 3, 0) != -1) stat = 0xe2;
  else if (march((void *)0x10000000, 3, 1) != -1) stat = 0xe3;
    else if (march((void *)0x10000000, 3, 2) != -1) stat = 0xe4;

//  for (i=0; i<1200000; i++) {}

  for (i=0; lcd_init[i] != 0xff; i++) lcd_inst(lcd_init[i]);

  putstr ("LCD init\n");
#if 0
  lcd_loc(0, 1);
  lcd_puts("Hit a Key!");

  putstr ("LCD Welcome\n");

  key_wait();
  key();

  lcd_loc(0, 1);
  lcd_puts("Hello 123!");
#endif
#if 0

  lcd_loc(0, 0); lcd_puts(hex(0x123ab678));
#endif
  for (i=0; i<8; i++) {
    lcd_data(
              (1<<(i+0 )) |
              (1<<(i+8 )) |
              (1<<(i+16)) |
              (1<<(i+24)));
  }
  for (i=0; i<800; i++) {}
  led(stat);
  for (i=0; i<800; i++) {}
  led(0xaa);

  for (;;) {
    for (i=0; i<1200000; i++) {}
    led(stat);
    for (i=0; i<1200000; i++) {}
    led(0xaa);
  }
#if 0
  for (;;) {
    key_wait();
    lcd_loc(0,1); lcd_puts("Key...");
    lcd_loc(0,2); lcd_puts(hex(key()));
  }
#endif
}
