-- A simple pre-initalized RAM, which reads from a binary file at synthesis time
-- single 32 bit read/write port.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simple_ram is
  generic (
    -- 32-bit read/write port.  ADDR_WIDTH is in bytes, not words.
    ADDR_WIDTH : integer := 15 -- default 32k
    );
  port (
    clk : in std_logic;

    en : in std_logic;
    raddr : in std_logic_vector(ADDR_WIDTH - 3 downto 0);
    do : out std_logic_vector(31 downto 0);

    we : in std_logic_vector(3 downto 0);
    waddr : in std_logic_vector(ADDR_WIDTH - 3 downto 0);
    di : in std_logic_vector(31 downto 0)
    );
end simple_ram;

architecture behavioral of simple_ram is
  constant NUM_WORDS : integer :=  2**(ADDR_WIDTH - 2);
  type ram_type is array (0 to NUM_WORDS-1) of std_logic_vector(31 downto 0);

  impure function load_binary(filename : string) return ram_type is
    type binary_file is file of character;
    file f : binary_file;
    variable c : character;
    variable mem : ram_type;
  begin
    file_open(f, filename, read_mode);
    for i in ram_type'range loop
      mem(i) := (others => '0');
      -- read 4 bytes and store in big endian order
      for bi in 3 downto 0 loop
        if not endfile(f) then
          read(f, c);
          mem(i)((bi+1)*8 - 1 downto bi*8) :=
            std_logic_vector(to_unsigned(character'pos(c), 8));
        end if;
      end loop;
    end loop;
    file_close(f);
    return mem;
  end;

  signal ram : ram_type := load_binary("ram.img");
begin

  process (clk)
    variable read : std_logic_vector(31 downto 0);
  begin
    if clk'event and clk = '1' and en = '1' then
      if we(3) = '1' then
        ram(to_integer(unsigned(waddr)))(31 downto 24) <= di(31 downto 24);
      end if;
      if we(2) = '1' then
        ram(to_integer(unsigned(waddr)))(23 downto 16) <= di(23 downto 16);
      end if;
      if we(1) = '1' then
        ram(to_integer(unsigned(waddr)))(15 downto 8 ) <= di(15 downto 8 );
      end if;
      if we(0) = '1' then
        ram(to_integer(unsigned(waddr)))(7  downto 0 ) <= di(7  downto 0 );
      end if;
      read := ram(to_integer(unsigned(raddr)));
      do <= read;
    end if;
  end process;
end behavioral;
