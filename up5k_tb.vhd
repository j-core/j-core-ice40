library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity up5k_tb is
end up5k_tb;

architecture beh of up5k_tb is

  function to_hex_string(s: in std_logic_vector) return string is
  constant hex : string (1 to 16) := "0123456789ABCDEF";
  variable ss  : std_logic_vector(31 downto 0) := (others => '0');
  variable ret : string (1 to ss'left/4+1);
  begin
    ss(s'range) := s;
    for i in 0 to ss'left/4 loop
      ret(i+1) := hex(to_integer(unsigned(ss(ss'left - i*4 downto ss'left - i*4 -3)))+1);
    end loop;
   return ret;
  end to_hex_string;

  signal x     : std_logic_vector(6 downto 1);
  signal y     : std_logic_vector(7 downto 1);
  signal pon   : std_logic;
  signal mfsc  : std_logic;
  signal mfcs  : std_logic;
  signal mrcs  : std_logic;
  signal msck  : std_logic;
  signal msi   : std_logic;
  signal mso   : std_logic;
  signal mio2  : std_logic;
  signal mio3  : std_logic;
  signal lcs   : std_logic;
  signal la0   : std_logic;
  signal lscl  : std_logic;
  signal lsi   : std_logic;

  signal ox    : std_logic_vector(6 downto 1);
  signal oy    : std_logic_vector(7 downto 1);

  begin
   fp: entity work.cpu_up5k
      port map( x => x, y => y, pon => pon,
                mfcs => mfcs, mrcs => mrcs, msck => msck, msi => msi, mso => mso,
                mio2 => mio2, mio3 => mio3,
                lcs => lcs, la0 => la0, lscl => lscl, lsi => lsi);

   pon <= '1';
   y <= (others => 'H');

   k0: process
   begin
     y(3) <= 'H';
     wait for 650 us;
     while true loop
       y(3) <= x(2);
       wait until x'event;
     end loop;
     wait;
   end process;

   p0: process(x, y)
   variable l : line;
   begin
      if ox /= x then
         ox <= x;
         write(l, string'("X: Write"));
         write(l, to_hex_string(x));
         writeline(output, l);
      end if;
      if oy /= y then
         oy <= y;
         write(l, string'("Y: Write"));
         writeline(output, l);
      end if;
   end process;

end beh;
