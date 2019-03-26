-- A simple non initalized bulk RAM.
-- single 32 bit read/write port.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bulk_ram is
  generic (
    -- 32-bit read/write port.  ADDR_WIDTH is in bytes, not words.
    ADDR_WIDTH : integer := 17 -- default 128k
    );
  port (
    clk : in std_logic;

    en : in std_logic;
    addr : in std_logic_vector(ADDR_WIDTH - 3 downto 0);
    do : out std_logic_vector(31 downto 0);

    we : in std_logic_vector(3 downto 0);
    di : in std_logic_vector(31 downto 0)
    );
end bulk_ram;

architecture behavioral of bulk_ram is
  constant NUM_WORDS : integer :=  2**(ADDR_WIDTH - 2);
  type ram_t is array (0 to NUM_WORDS-1) of std_logic_vector(31 downto 0);
  signal ram : ram_t;
begin

  process (clk, en)
  begin
    if clk'event and clk = '1' and en = '1' then
      if we = "0000" then
        do <= ram(to_integer(unsigned(addr)));
      else
        if we(3) = '1' then
          ram(to_integer(unsigned(addr)))(31 downto 24) <= di(31 downto 24);
        end if;
        if we(2) = '1' then
          ram(to_integer(unsigned(addr)))(23 downto 16) <= di(23 downto 16);
        end if;
        if we(1) = '1' then
          ram(to_integer(unsigned(addr)))(15 downto 8 ) <= di(15 downto 8 );
        end if;
        if we(0) = '1' then
          ram(to_integer(unsigned(addr)))(7  downto 0 ) <= di(7  downto 0 );
        end if;
      end if;
    end if;
  end process;
end behavioral;
