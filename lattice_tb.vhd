library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity lattice_tb is
end lattice_tb;

architecture beh of lattice_tb is

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

  signal clk : std_logic;
  signal led : std_logic_vector(7 downto 0) := x"00";
  signal ol  : std_logic_vector(7 downto 0) := x"00";
begin

   c0: process
   begin 
      clk <= '0';
      wait for 10 ns;
      clk <= '1';
      wait for 10 ns;
   end process;

   fp: entity work.cpu_lattice
      port map(clk => clk, led => led);

   p0: process(led)
   variable l : line;
   begin
      if led /= ol then
         ol <= led;
         write(l, string'("LED: Write "));
         write(l, to_hex_string(led));
         write(l, " at " & time'image(now));
         writeline(output, l);
      end if;
   end process;

end beh;
