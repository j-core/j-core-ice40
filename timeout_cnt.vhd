library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.monitor_pkg.all;

entity timeout_cnt is
generic ( timeout_cc : integer := 3); -- clock cycles timeout

port(
    clk : in std_logic;
    rst : in std_logic;
    enable : in std_logic;
    ack : in std_logic;
    timeout : out timeout_t;
    fault : out std_logic
    );

end timeout_cnt;

architecture structure of timeout_cnt is

signal this_c : cnt_reg_t;
signal this_r : cnt_reg_t := CNT_REG_RESET;

begin
   counter : process(this_r,enable,ack)
    variable this : cnt_reg_t;
    begin
       this := this_r;

    if (enable = '1') then
       if (ack = '1') then
          this.cnt := 0;
       else
            if (this.cnt /= timeout_cc) then
               this.cnt := this.cnt + 1; -- start counting
            end if;
       end if;
    else
 this.cnt := 0;
    end if;


this_c <= this;
end process;

counter_r0 : process(clk, rst)
begin
   if rst = '1' then
      this_r <= CNT_REG_RESET;
   elsif clk = '1' and clk'event then
      this_r <= this_c;
   end if;
end process;

--timeout <= '1' when (this.cnt = timeout_cc) else '0';

timeout.cnt <= this_r.cnt;

fault <= '1' when (this_r.cnt = timeout_cc) else '0';

end structure;
