library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu2j0_pack.all;

entity cpu_sram is 
  generic ( ADDR_WIDTH : natural := 15 );
  port (
    clk : in std_logic;
    ibus_i : in cpu_instruction_o_t;
    ibus_o : out cpu_instruction_i_t;
    db_i : in cpu_data_o_t;
    db_o : out cpu_data_i_t
    );
end;

architecture struc of cpu_sram is
  signal db_we : std_logic_vector(3 downto 0);
  signal rd    : std_logic_vector(31 downto 0);
  signal ra    : std_logic_vector(ADDR_WIDTH-1 downto 2);
  signal en    : std_logic;
  signal iclk : std_logic;
      
begin

  db_we <= (db_i.wr and db_i.we(3)) &
           (db_i.wr and db_i.we(2)) &
           (db_i.wr and db_i.we(1)) &
           (db_i.wr and db_i.we(0));

  ra <= db_i.a(ADDR_WIDTH-1 downto 2) when db_i.en = '1' else ibus_i.a(ADDR_WIDTH-1 downto 2);

  -- clk memory on negative edge to avoid wait states
  iclk <= not clk;
  en <= db_i.en or ibus_i.en;

  r : entity work.simple_ram
    generic map (ADDR_WIDTH => ADDR_WIDTH)
    port map(clk => iclk,
             en => en,
             we => db_we,
             waddr => db_i.a(ADDR_WIDTH-1 downto 2),
             di => db_i.d,

             raddr => ra,
             do =>    rd);

  -- (too) simple output mux
  db_o.d   <= rd;
  ibus_o.d <= rd(31 downto 16) when ibus_i.a(1) = '0' else rd(15 downto 0);

  -- simply ack immediately. Should this simulate different delays?
  db_o.ack <= db_i.en;
  ibus_o.ack <= ibus_i.en when db_i.en = '0' else '0';

end architecture struc;
