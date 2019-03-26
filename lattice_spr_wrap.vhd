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

component SB_SPRAM256KA is  
          Port (  CLOCK   : in std_logic ;
                ADDRESS : in std_logic_vector(13 downto 0);
                DATAIN  : in std_logic_vector(15 downto 0);
                MASKWREN : in std_logic_vector(3 downto 0);
                WREN    : in std_logic;
                CHIPSELECT: in std_logic ;
                STANDBY : in std_logic := 'L' ;
                SLEEP   : in std_logic := 'L' ;
                POWEROFF: in std_logic := 'H' ;         --  Note : 1'b0 to POWEROFF RAM  , 1'b1 to POWERON RAM block at wrapper level.
                DATAOUT : out std_logic_vector(15 downto 0)
             );
end component;

  signal wren : std_logic;
  signal cs0, cs1 : std_logic;
  signal rd0  : std_logic_vector(31 downto 0);
  signal rd1  : std_logic_vector(31 downto 0);

begin

  cs0  <= en and not addr(14);
  cs1  <= en and     addr(14);
  wren <= we(3) or we(2) or we(1) or we(0);

  r0 : SB_SPRAM256KA port map (clock => clk, address => addr(13 downto 0), datain => di(31 downto 16), 
                               maskwren => we(3) & we(3) & we(2) & we(2),
                               wren => wren, chipselect => cs0, dataout => rd0(31 downto 16),
                               standby => '0', sleep => '0', poweroff => '1');

  r1 : SB_SPRAM256KA port map (clock => clk, address => addr(13 downto 0), datain => di(15 downto  0), 
                               maskwren => we(1) & we(1) & we(0) & we(0),
                               wren => wren, chipselect => cs0, dataout => rd0(15 downto 0),
                               standby => '0', sleep => '0', poweroff => '1');

  r2 : SB_SPRAM256KA port map (clock => clk, address => addr(13 downto 0), datain => di(31 downto 16), 
                               maskwren => we(3) & we(3) & we(2) & we(2),
                               wren => wren, chipselect => cs1, dataout => rd1(31 downto 16),
                               standby => '0', sleep => '0', poweroff => '1');

  r3 : SB_SPRAM256KA port map (clock => clk, address => addr(13 downto 0), datain => di(15 downto  0), 
                               maskwren => we(1) & we(1) & we(0) & we(0),
                               wren => wren, chipselect => cs1, dataout => rd1(15 downto 0),
                               standby => '0', sleep => '0', poweroff => '1');

  do <= rd0 when addr(14) = '0' else rd1;
end behavioral;
