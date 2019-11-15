library ieee;
use ieee.std_logic_1164.all;

use work.cpu2j0_pack.all;
use work.decode_pack.all;
use work.cpu2j0_components_pack.all;
use work.mult_pkg.all;

package datapath_pack is

   -- SR bit Positions
   constant T   : integer range 0 to 9 := 0;
   constant S   : integer range 0 to 9 := 1;
   constant I0  : integer range 0 to 9 := 4;
   constant I1  : integer range 0 to 9 := 5;
   constant I2  : integer range 0 to 9 := 6;
   constant I3  : integer range 0 to 9 := 7;
   constant Q   : integer range 0 to 9 := 8;
   constant M   : integer range 0 to 9 := 9;

   component datapath is port (
      clk         : in  std_logic;
      rst         : in  std_logic;
      debug       : in  std_logic;
      enter_debug : out std_logic;
      slot        : out std_logic;
      reg         : in  reg_ctrl_t;
      func        : in  func_ctrl_t;
      sr_ctrl     : in  sr_ctrl_t;
      mac         : in  mac_ctrl_t;
      mem         : in  mem_ctrl_t;
      instr       : in  instr_ctrl_t;
      pc_ctrl     : in  pc_ctrl_t;
      buses       : in  buses_ctrl_t;
      db_lock     : out std_logic;
      db_o        : out cpu_data_o_t;
      db_i        : in  cpu_data_i_t;
      inst_o      : out cpu_instruction_o_t;
      inst_i      : in  cpu_instruction_i_t;
      debug_o     : out cpu_debug_o_t;
      debug_i     : in  cpu_debug_i_t;
      macin1      : out std_logic_vector(31 downto 0);
      macin2      : out std_logic_vector(31 downto 0);
      mach        : in std_logic_vector(31 downto 0);
      macl        : in std_logic_vector(31 downto 0);
      mac_s       : out std_logic;
      t_bcc       : out std_logic;
      ibit        : out std_logic_vector(3 downto 0);
      if_dr       : out std_logic_vector(15 downto 0);
      if_stall    : out std_logic;
      mask_int    : out std_logic;
      illegal_delay_slot : out std_logic;
      illegal_instr : out std_logic);
   end component datapath;

  type ybus_val_pipeline_t is array (2 downto 0) of bus_val_t;

  type datapath_reg_t is record
     pc         : std_logic_vector(31 downto 0);
     sr         : sr_t;
     mac_s      : std_logic;
     data_o_size: mem_size_t;
     data_o_lock: std_logic;
     data_o     : cpu_data_o_t;
     inst_o     : cpu_instruction_o_t;
     pc_inc     : std_logic_vector(31 downto 0);
     if_dr      : std_logic_vector(15 downto 0);
     if_dr_next : std_logic_vector(15 downto 0);
     illegal_delay_slot : std_logic;
     illegal_instr : std_logic;
     if_en      : std_logic;
     m_dr       : std_logic_vector(31 downto 0);
     m_dr_next  : std_logic_vector(31 downto 0);
     m_en       : std_logic;
     slot       : std_logic;
     -- pipelines the enter_debug signal to delay it so that single stepping
     -- instructions works and debug mode is re-entered after one instruction.
     -- The length of this depends on how many microcode lines there are in the
     -- break instruction after it has raised the debug control line.
     enter_debug: std_logic_vector(3 downto 0);
     old_debug : std_logic;
     stop_pc_inc : std_logic;
     debug_state: debug_state_t;
     debug_o    : cpu_debug_o_t;
     -- pipeline of inserted values to override y-bus. Values go in at 'left and
     -- move downto 'right
     ybus_override : ybus_val_pipeline_t;
  end record;

  constant DATAPATH_RESET : datapath_reg_t := (
    pc => (others => '0'),
    sr => (int_mask => "1111", others => '0'),
    mac_s => '0',
    data_o_size => BYTE,
    data_o_lock => '0',
    data_o => NULL_DATA_O,
    inst_o => NULL_INST_O,
    pc_inc => (others => '0'),
    if_dr => (others => '0'),
    if_dr_next => (others => '0'),
    illegal_delay_slot => '0',
    illegal_instr => '0',
    if_en => '0',
    m_dr => (others => '0'),
    m_dr_next => (others => '0'),
    m_en => '0', slot => '1',
    enter_debug => (others => '0'),
    old_debug => '0',
    stop_pc_inc => '0',
    debug_state => RUN,
    debug_o => (ack => '0', d => (others => '0'), rdy => '0'),
    ybus_override => (others => BUS_VAL_RESET)
  );
end package;
