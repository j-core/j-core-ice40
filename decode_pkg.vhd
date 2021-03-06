-- ******************************************************************
-- ******************************************************************
-- ******************************************************************
-- This file is generated. Changing this file directly is probably
-- not what you want to do. Any changes will be overwritten next time
-- the generator is run.
-- ******************************************************************
-- ******************************************************************
-- ******************************************************************
library ieee;
use ieee.std_logic_1164.all;
use work.cpu2j0_components_pack.all;
use work.mult_pkg.all;
use work.cpu2j0_pack.all;
package decode_pack is

    -- Here beginnith the hand written instruction classification RTL
    type isa_fmt_t is (NX, MX, NM, NMX, NM4, N8, NX4, X8, I12);

    type isa_type_t is record
        ln   : std_logic_vector(3 downto 0);
        col  : std_logic_vector(1 downto 0);
        op   : std_logic_vector(3 downto 0);
        fmt  : isa_fmt_t;
        sz   : mem_size_t;
        rm   : std_logic_vector(3 downto 0);
        rn   : std_logic_vector(3 downto 0);
        imm  : std_logic_vector(11 downto 0);
    end record;
    function isa_fmt (code : std_logic_vector(15 downto 0)) return isa_type_t;

    type aluinx_sel_t is (SEL_XBUS, SEL_FC, SEL_ROTCL, SEL_ZERO);
    type aluiny_sel_t is (SEL_YBUS, SEL_IMM, SEL_R0);
    type cpu_decode_type_t is (SIMPLE, REVERSE, MICROCODE);
    type immval_t is (IMM_ZERO, IMM_P1, IMM_P2, IMM_P4, IMM_P8, IMM_P16, IMM_N16, IMM_N8, IMM_N2, IMM_N1, IMM_U_4_0, IMM_U_4_1, IMM_U_4_2, IMM_U_8_0, IMM_U_8_1, IMM_U_8_2, IMM_S_8_1, IMM_S_12_1, IMM_S_8_0);
    type instruction_plane_t is (NORMAL_INSTR, SYSTEM_INSTR);
    type mac_busy_t is (NOT_BUSY, EX_NOT_STALL, WB_NOT_STALL, EX_BUSY, WB_BUSY);
    type macin1_sel_t is (SEL_XBUS, SEL_ZBUS, SEL_WBUS);
    type macin2_sel_t is (SEL_YBUS, SEL_ZBUS, SEL_WBUS);
    type mem_addr_sel_t is (SEL_XBUS, SEL_YBUS, SEL_ZBUS);
    type mem_wdata_sel_t is (SEL_ZBUS, SEL_YBUS);
    type reg_sel_t is (SEL_R0, SEL_R15, SEL_RA, SEL_RB);
    type sr_sel_t is (SEL_PREV, SEL_WBUS, SEL_ZBUS, SEL_DIV0U, SEL_ARITH, SEL_LOGIC, SEL_INT_MASK, SEL_SET_T);
    type t_sel_t is (SEL_CLEAR, SEL_SET, SEL_SHIFT, SEL_CARRY);
    type xbus_sel_t is (SEL_IMM, SEL_REG, SEL_PC);
    type ybus_sel_t is (SEL_IMM, SEL_REG, SEL_MACH, SEL_MACL, SEL_PC, SEL_SR);
    type zbus_sel_t is (SEL_ARITH, SEL_LOGIC, SEL_SHIFT, SEL_MANIP, SEL_YBUS, SEL_WBUS);
    type operation_t is
        record
            plane : instruction_plane_t;
            code : std_logic_vector(15 downto 0);
            addr : std_logic_vector(7 downto 0);
        end record;
    type alu_ctrl_t is
        record
            manip : alumanip_t;
            inx_sel : aluinx_sel_t;
            iny_sel : aluiny_sel_t;
        end record;
    type arith_ctrl_t is
        record
            func : arith_func_t;
            ci_en : std_logic;
            sr : arith_sr_func_t;
        end record;
    type buses_ctrl_t is
        record
            x_sel : xbus_sel_t;
            y_sel : ybus_sel_t;
            z_sel : zbus_sel_t;
            imm_val : std_logic_vector(31 downto 0);
        end record;
    type func_ctrl_t is
        record
            alu : alu_ctrl_t;
            shift : shiftfunc_t;
            arith : arith_ctrl_t;
            logic_func : logic_func_t;
            logic_sr : logic_sr_func_t;
        end record;
    type instr_ctrl_t is
        record
            issue : std_logic;
            addr_sel : std_logic;
        end record;
    type mac_ctrl_t is
        record
            com1 : std_logic;
            wrmach : std_logic;
            wrmacl : std_logic;
            s_latch : std_logic;
            sel1 : macin1_sel_t;
            sel2 : macin2_sel_t;
            com2 : mult_state_t;
        end record;
    type mem_ctrl_t is
        record
            issue : std_logic;
            wr : std_logic;
            lock : std_logic;
            size : mem_size_t;
            addr_sel : mem_addr_sel_t;
            wdata_sel : mem_wdata_sel_t;
        end record;
    type pc_ctrl_t is
        record
            wr_z : std_logic;
            wrpr : std_logic;
            inc : std_logic;
        end record;
    subtype regnum_t is std_logic_vector(4 downto 0);
    type reg_ctrl_t is
        record
            num_x : regnum_t;
            num_y : regnum_t;
            num_z : regnum_t;
            num_w : regnum_t;
            wr_z : std_logic;
            wr_w : std_logic;
        end record;
    type sr_ctrl_t is
        record
            sel : sr_sel_t;
            t : t_sel_t;
            ilevel : std_logic_vector(3 downto 0);
        end record;
    type pipeline_ex_stall_t is
        record
            wrpc_z : std_logic;
            wrsr_z : std_logic;
            ma_issue : std_logic;
            wrpr_pc : std_logic;
            zbus_sel : zbus_sel_t;
            sr_sel : sr_sel_t;
            t_sel : t_sel_t;
            mem_addr_sel : mem_addr_sel_t;
            mem_wdata_sel : mem_wdata_sel_t;
            wrreg_z : std_logic;
            wrmach, wrmacl : std_logic;
            shiftfunc : shiftfunc_t;
            mulcom1 : std_logic;
            mulcom2 : mult_state_t;
            macsel1 : macin1_sel_t;
            macsel2 : macin2_sel_t;
        end record;
    type pipeline_ex_t is
        record
            imm_val : std_logic_vector(31 downto 0);
            xbus_sel : xbus_sel_t;
            ybus_sel : ybus_sel_t;
            regnum_z, regnum_x, regnum_y : regnum_t;
            alumanip : alumanip_t;
            aluinx_sel : aluinx_sel_t;
            aluiny_sel : aluiny_sel_t;
            arith_func : arith_func_t;
            arith_ci_en : std_logic;
            arith_sr_func : arith_sr_func_t;
            logic_func : logic_func_t;
            logic_sr_func : logic_sr_func_t;
            mac_busy : std_logic;
            ma_wr : std_logic;
            mem_lock : std_logic;
            mem_size : mem_size_t;
        end record;
    type pipeline_id_t is
        record
            incpc : std_logic;
            if_issue : std_logic;
            ifadsel : std_logic;
        end record;
    type pipeline_wb_stall_t is
        record
            mulcom1 : std_logic;
            wrmach, wrmacl : std_logic;
            wrreg_w, wrsr_w : std_logic;
            macsel1 : macin1_sel_t;
            macsel2 : macin2_sel_t;
            mulcom2 : mult_state_t;
        end record;
    type pipeline_wb_t is
        record
            regnum_w : regnum_t;
            mac_busy : std_logic;
        end record;
    type pipeline_t is
        record
            ex1 : pipeline_ex_t;
            ex1_stall : pipeline_ex_stall_t;
            wb1 : pipeline_wb_t;
            wb2 : pipeline_wb_t;
            wb3 : pipeline_wb_t;
            wb1_stall : pipeline_wb_stall_t;
            wb2_stall : pipeline_wb_stall_t;
            wb3_stall : pipeline_wb_stall_t;
        end record;
    component decode
        port (
            clk : in std_logic;
            enter_debug : in std_logic;
            event_i : in cpu_event_i_t;
            ibit : in std_logic_vector(3 downto 0);
            if_dr : in std_logic_vector(15 downto 0);
            if_stall : in std_logic;
            illegal_delay_slot : in std_logic;
            illegal_instr : in std_logic;
            mac_busy : in std_logic;
            mask_int : in std_logic;
            rst : in std_logic;
            slot : in std_logic;
            t_bcc : in std_logic;
            buses : out buses_ctrl_t;
            debug : out std_logic;
            event_ack : out std_logic;
            func : out func_ctrl_t;
            instr : out instr_ctrl_t;
            mac : out mac_ctrl_t;
            mem : out mem_ctrl_t;
            pc : out pc_ctrl_t;
            reg : out reg_ctrl_t;
            slp : out std_logic;
            sr : out sr_ctrl_t
        );
    end component;
    component decode_core
        port (
            clk : in std_logic;
            debug : in std_logic;
            delay_jump : in std_logic;
            dispatch : in std_logic;
            enter_debug : in std_logic;
            event_ack_0 : in std_logic;
            event_i : in cpu_event_i_t;
            ex : in pipeline_ex_t;
            ex_stall : in pipeline_ex_stall_t;
            ibit : in std_logic_vector(3 downto 0);
            id : in pipeline_id_t;
            if_dr : in std_logic_vector(15 downto 0);
            if_stall : in std_logic;
            ilevel_cap : in std_logic;
            illegal_delay_slot : in std_logic;
            illegal_instr : in std_logic;
            mac_busy : in std_logic;
            mac_stall_sense : in std_logic;
            maskint_next : in std_logic;
            p : in pipeline_t;
            rst : in std_logic;
            slot : in std_logic;
            t_bcc : in std_logic;
            event_ack : out std_logic;
            if_issue : out std_logic;
            ifadsel : out std_logic;
            ilevel : out std_logic_vector(3 downto 0);
            incpc : out std_logic;
            next_id_stall : out std_logic;
            op : out operation_t
        );
    end component;
    component decode_table
        port (
            clk : in std_logic;
            next_id_stall : in std_logic;
            op : in operation_t;
            t_bcc : in std_logic;
            debug : out std_logic;
            delay_jump : out std_logic;
            dispatch : out std_logic;
            event_ack_0 : out std_logic;
            ex : out pipeline_ex_t;
            ex_stall : out pipeline_ex_stall_t;
            id : out pipeline_id_t;
            ilevel_cap : out std_logic;
            mac_s_latch : out std_logic;
            mac_stall_sense : out std_logic;
            maskint_next : out std_logic;
            slp : out std_logic;
            wb : out pipeline_wb_t;
            wb_stall : out pipeline_wb_stall_t
        );
    end component;
    function check_illegal_delay_slot (code : std_logic_vector(15 downto 0)) return std_logic;
    function check_illegal_instruction (code : std_logic_vector(15 downto 0)) return std_logic;
    type decode_core_reg_t is
        record
            maskint : std_logic;
            delay_slot : std_logic;
            id_stall : std_logic;
            instr_seq_zero : std_logic;
            op : operation_t;
            ilevel : std_logic_vector(3 downto 0);
        end record;
    constant DEC_CORE_RESET : decode_core_reg_t := (maskint => '0', delay_slot => '0', id_stall => '0', instr_seq_zero => '0', op => (plane => SYSTEM_INSTR, code => x"0300", addr => x"01"), ilevel => x"0");
    -- Reset vector specific to the microcode ROM. Uses a different starting addr.
    constant DEC_CORE_ROM_RESET : decode_core_reg_t := (maskint => '0', delay_slot => '0', id_stall => '0', instr_seq_zero => '0', op => (plane => SYSTEM_INSTR, code => x"0300", addr => x"da"), ilevel => x"0");
    type system_instr_t is (BREAK_I, ERROR_I, GENERAL_ILLEGAL_I, INTERRUPT_I, RESET_CPU_I, SLOT_ILLEGAL_I);
    type system_instr_addr_array is array (system_instr_t range <>) of std_logic_vector(7 downto 0);
    constant system_instr_rom_addrs : system_instr_addr_array := (BREAK_I => x"f2", ERROR_I => x"e9", GENERAL_ILLEGAL_I => x"c9", INTERRUPT_I => x"e0", RESET_CPU_I => x"d9", SLOT_ILLEGAL_I => x"d1");
    type system_instr_code_array is array (system_instr_t range <>) of std_logic_vector(11 downto 8);
    constant system_instr_codes : system_instr_code_array := (BREAK_I => x"2", ERROR_I => x"1", GENERAL_ILLEGAL_I => x"7", INTERRUPT_I => x"0", RESET_CPU_I => x"3", SLOT_ILLEGAL_I => x"6");
    type system_event_code_array is array (cpu_event_cmd_t range <>) of std_logic_vector(11 downto 8);
    constant system_event_codes : system_event_code_array := (INT => x"0", ERR => x"1", BREAK => x"2", RST => x"3");
    type system_event_instr_array is array (cpu_event_cmd_t range <>) of system_instr_t;
    constant system_event_instrs : system_event_instr_array := (INT => INTERRUPT_I, ERR => ERROR_I, BREAK => BREAK_I, RST => RESET_CPU_I);
end;

package body decode_pack is
    function isa_fmt (code : std_logic_vector(15 downto 0)) return isa_type_t is
        variable ret : isa_type_t := ( (others => '0'), (others => '0'), (others => '0'), 
                                       NX, LONG,
                                       (others => '0'), (others => '0'), (others => '0'));
    begin
        ret.ln  := code(15 downto 12);
        if   (ret.ln = "0000" and code(2) = '1') or (ret.ln(3) = '0' and ret.ln(1) = '1') then
            ret.fmt := NMX;
        elsif ret.ln = "0100" and code(3 downto 2) = "11" and code (1 downto 0) /= "10" then
            ret.fmt := NM;
        elsif ret.ln = "0001" or ret.ln = "0101" then
            ret.fmt := NM4;
        elsif ret.ln = "0111" or ret.ln = "1001" or ret.ln = "1101" or ret.ln = "1110" then
            ret.fmt := N8;
        elsif ret.ln(3 downto 1) = "101" then
            ret.fmt := I12;
        elsif ret.ln = "1000" and code(11) = '0' then
            ret.fmt := NX4;
        elsif (ret.ln = "1000" and code(11) = '1') or ret.ln = "1100" then
            ret.fmt := X8;
        elsif (ret.ln = "0000" and code (3 downto 0) = "0011") or (ret.ln = "0100" and code(1) = '1') then
            ret.fmt := MX;
        end if;

        ret.rn  := code(11 downto 8);
        ret.rm  := code(7 downto 4);
        if code(15 downto 10) = "100000" then ret.rm  := code(11 downto 8); end if; 
        if ret.fmt = MX                  then ret.rn  := code( 7 downto 4); end if;

        if    ret.fmt = I12                  then ret.imm :=         code(11 downto 0);
        elsif ret.fmt = N8  or ret.fmt = X8  then ret.imm := x"0"  & code( 7 downto 0);
        elsif ret.fmt = NM4 or ret.fmt = NX4 then ret.imm := x"00" & code( 3 downto 0); end if;


        if    ret.fmt = NX  or ret.fmt = MX then ret.col := code( 5 downto 4); 
        elsif ret.fmt = NMX                 then ret.col := code( 1 downto 0);
        elsif ret.fmt = NX4 or ret.fmt = X8 then ret.col := code( 9 downto 8); end if; 

        if    ret.fmt = NX  or ret.fmt = MX then ret.op  := code( 3 downto 0);
        elsif ret.fmt = NMX                 then ret.op  := "00" & code( 3 downto  2);
        elsif ret.fmt = NX4 or ret.fmt = X8 then ret.op  := "00" & code(11 downto 10); end if;

        if    ret.col = "00" then ret.sz := BYTE;
        elsif ret.col = "01" then ret.sz := WORD; end if;

        return ret;
    end function;

    function check_illegal_delay_slot (code : std_logic_vector(15 downto 0)) return std_logic is
    begin
        -- Check for instructions that assign to PC:
        -- RTE, RTS, JMP @Rm, JSR @Rm, BRAF Rm, BSRF Rm, BF label, BF /S label, BT label, BT /S label, BRA label, BSR label, TRAPA #imm
        if ((code(15 downto 12) = "0000" and code(3 downto 2) = "00" and code(0) = '1') or (code(15 downto 14) = "10" and code(12 downto 11) = "01" and code(8) = '1') or code(15 downto 13) = "101" or (code(15) = '1' and code(13 downto 8) = "000011") or (code(15) = '0' and code(13 downto 12) = "00" and code(4 downto 0) = "01011")) then
            return '1';
        else
            return '0';
        end if;
    end;
    function check_illegal_instruction (code : std_logic_vector(15 downto 0)) return std_logic is
    begin
        -- TODO: Improve detection of illegal instructions
        if code(15 downto 8) = x"ff" then
            return '1';
        else
            return '0';
        end if;
    end;
end decode_pack;
