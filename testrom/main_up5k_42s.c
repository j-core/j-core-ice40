#define KEYPORT (*(volatile unsigned long  *)0xabcd0000)
#define KEY_PRECHARGE_READ 0x80
#define KEY_PRECHARGE_ALL  0xC0
#define KEY_IDLE           0x00
#define KEY_NONE           0x7F
#define KEY_ALL            0xFF
#define KEY_ON             0x80

#define LCDDATA (*(volatile unsigned long  *)0xabcd0044)
#define LCDINST (*(volatile unsigned long  *)0xabcd0040)

#include "font5x7.h"

extern char version_string[];

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
key_precharge()
{
  volatile int i;

  KEYPORT = KEY_NONE;
  for (i=0; i<3; i++) {}
  KEYPORT = KEY_PRECHARGE_ALL;
  for (i=0; i<3; i++) {}
}
 
int
key_wait(int h)
{
  volatile int i;
  int res;

  key_precharge();
  while (1) {
    KEYPORT = KEY_IDLE;
    for (i=0; i<12000; i++) {;} /* about 20ms */
    KEYPORT = KEY_PRECHARGE_READ;
    for (i=0; i<12; i++) {;}    /* about 20us */

    KEYPORT = KEY_IDLE;
    for (i=0; i<12; i++) {;}    /* about 20us */
    res=KEYPORT & KEY_ALL;

    if ((res == KEY_ALL && !h) || (res != KEY_ALL && h)) break;
  }

  return res ^ KEY_ALL;
}

int
key()
{
  volatile int i;
  int x, res;

  key_precharge();
  for (x=0; x<7; x++) {
    KEYPORT = KEY_NONE ^ (1<<x);
    for (i=0; i<120; i++) {;}
    res=KEYPORT & KEY_ALL;
    KEYPORT = KEY_PRECHARGE_ALL;
    for (i=0; i<12; i++) {;}
    if ((res & KEY_NONE) != KEY_NONE) return (x<<8) | (res ^ KEY_ALL);
  }
  return res ^ KEY_ALL;
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
  unsigned int stat = 600000;

  key_precharge();
#if 0
  uart_set_baudrate ();

#ifndef NO_TESTS
  putstr ("CPU tests passed\n");

  putstr ("GDB Stub for HS-2J0 SH2 ROM\n");
  putstr (version_string);
#endif

#endif
  if (march((void *)0x10000000, 3, 0) != -1) stat = 120000;
  else if (march((void *)0x10000000, 3, 1) != -1) stat = 240000;
    else if (march((void *)0x10000000, 3, 2) != -1) stat = 480000;

  for (i=0; i<1200000; i++) {}

  for (i=0; lcd_init[i] != 0xff; i++) lcd_inst(lcd_init[i]);

  lcd_loc(0, 1);
  lcd_puts ("LCD init\n");

  lcd_loc(0, 0); lcd_puts("main() = "); lcd_puts(hex( main_sh ));
  for (i=0; i<8; i++) {
    lcd_data(
              (1<<(i+0 )) |
              (1<<(i+8 )) |
              (1<<(i+16)) |
              (1<<(i+24)));
  }

#if 1
  for (;;) {
    lcd_loc(0,2); lcd_puts("Wait...   ");

    lcd_puts(hex(key_wait(1)));
    lcd_loc(0,2); lcd_puts("Key !!!   ");

    lcd_loc(0,3); lcd_puts(hex(key()));

    lcd_puts(hex(key_wait(0)));
  }
#endif
}
