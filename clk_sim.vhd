library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package components is
   
component SB_HFOSC is
  generic (clkhf_div : string := "0b00");
  port (clkhfen : in  std_logic;
        clkhf   : out std_logic;
        clkhfpu : in  std_logic);
end component SB_HFOSC;

end components;

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SB_HFOSC is
  generic (clkhf_div : string := "0b00");
  port (clkhfen : in  std_logic;
        clkhf   : out std_logic;
        clkhfpu : in  std_logic);
end SB_HFOSC;

architecture beh of SB_HFOSC is

  function set_clk_period(s: in string(1 to 4)) return time is
  constant base_t : time := 20.833 ns;
  begin
    case s is
      when "0b01" => return base_t * 2;
      when "0b10" => return base_t * 4;
      when "0b11" => return base_t * 8;
      when others => return base_t;
    end case;
  end set_clk_period;

  signal clk : std_logic;
  signal clk_period : time := set_clk_period(clkhf_div);
begin

  clk_gen : process
  begin
      clk <= '0';
      wait for (clk_period / 2);
      clk <= '1';
      wait for (clk_period / 2);
  end process;

  clkhf <= clk when clkhfen = '1' else '0';
end beh;
