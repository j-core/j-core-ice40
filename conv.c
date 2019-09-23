#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
   int i, l;
   unsigned char v[4] = { 0, 0, 0, 0 };

   printf("-- Machine generated from ram.img.\n");
   printf("library ieee;\n use ieee.std_logic_1164.all;\nuse ieee.numeric_std.all;\n\n");
   printf("package bootrom is\n");
   printf("  type rom_t is array (0 to 16383) of std_logic_vector(31 downto 0);\n  constant rom : rom_t := (\n");

   l = read(0,v,4);
   for (i=0 ; l; i++) {
      printf ("    x\"%.2x%.2x%.2x%.2x\",\n", v[0], v[1], v[2], v[3]);
      l = read(0,v,4);
   }
   printf("    others => x\"00000000\" );\n\n");
   printf("end package;\n\npackage body bootrom is\nend package body;\n");
}
