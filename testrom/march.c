/* A WOM March-C- algorithm.  Put in the base address and # of address bits, returns 0 if ok or fault addr */

#define SZ_BYTE 0
#define SZ_WORD 1
#define SZ_LONG 2

unsigned char  patterns_b[] = {0xff, 0x55, 0x33, 0x0f, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80};
unsigned short patterns_w[] = {0xffff, 0x5555, 0x3333, 0x0f0f, 0x00ff};
unsigned long  patterns_l[] = {0xffffffff, 0x55555555, 0x33333333, 0x0f0f0f0f, 0x00ff00ff, 0x0000ffff};

unsigned march(void *base, int addrs, int sz)
{
  volatile void *p = base;
  unsigned long i, pat[2];
  int len = 1<<(addrs-sz);
  int r, m, k, q, j;
  int patlen[3] = {sizeof(patterns_b), sizeof(patterns_w)/2, sizeof(patterns_l)/4};

  for (r=0; r<patlen[sz]; r++) {
    pat[0] = (sz == SZ_BYTE) ?  patterns_b[r] : (sz==SZ_WORD) ? patterns_w[r] : patterns_l[r];
    pat[1] = ~*pat;

    // alternate down/up sweeps (duuddu) swapping pat with nat, test previous
    // results first for all but first and last passes
    for (j=0; j<7;) {
      k = 2&++j;
      m = j&1;

      p = k ? base : base + (len-1) * (1<<sz);
      for (i=0; i<len; i++) {

        if (j!=1) {
          if      (sz==SZ_BYTE && *((unsigned char  *)p) == (unsigned char) pat[m]);
          else if (sz==SZ_WORD && *((unsigned short *)p) == (unsigned short)pat[m]);
          else if (sz==SZ_LONG && *((unsigned long  *)p) ==                 pat[m]);
          else return (((((i<<2)+sz)<<4)+r)<<3)+j;
        }
        if (j!=7) {
          q = pat[m^1];
          if (sz==SZ_BYTE)      *((unsigned char  *)p) = (unsigned char) q;
          else if (sz==SZ_WORD) *((unsigned short *)p) = (unsigned short)q;
          else                  *((unsigned long  *)p) =                 q;
        }
        p += (1<<sz) * (k ? 1 : -1);
      }
    }
  }
  return ~0;
}

#if 0
int march(void *base, int addrs)
{
  int ret;

  if ((ret = _march(base, addrs, SZ_BYTE)) != -1) return ret;
  if ((ret = _march(base, addrs, SZ_WORD)) != -1) return ret;
  return _march(base, addrs, SZ_LONG);
}

char mem[1<<17];

int
main(int argc, char *argv[])
{
   printf("March on memory at 0x%p returned %d\n", mem, march(mem, 3));
}
#endif
