library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu2j0_pack.all;

package cpu2j0_components_pack is

type arith_func_t is (ADD, SUB);
-- when to set the t bit. UGRTER_EQ is "unsigned greater or equal"
type arith_sr_func_t is (ZERO,
                         OVERUNDERFLOW,
                         UGRTER_EQ, SGRTER_EQ,
                         UGRTER, SGRTER,
                         DIV0S, DIV1);
type logic_func_t is (LOGIC_NOT, LOGIC_AND, LOGIC_OR, LOGIC_XOR);
type logic_sr_func_t is (ZERO, BYTE_EQ);
-- logic: don't sign extend. arith: shift right duplicates sign bit
-- rotate: rotate leftmost/rightmost bit around, rotc: rotate through carry bit
type shiftfunc_t is (LOGIC, ARITH, ROTATE, ROTC);
-- endianness and sign extend, extract = unaligned access, thing for tas.b
type alumanip_t is (SWAP_BYTE, SWAP_WORD, EXTEND_UBYTE, EXTEND_UWORD, EXTEND_SBYTE, EXTEND_SWORD, EXTRACT, SET_BIT_7);

type sr_t is record
   t, s, q, m : std_logic; -- test, sign for MAC, q&m are for divider
   int_mask : std_logic_vector(3 downto 0); -- interrupt level (not bitmask)
end record;

-- Adds or subtracts a and b with carry-in and carry-out. The carry-out
-- (borrow for subtraction) bit is in the left-most bit of the result, which is
-- one bit wider than the inputs
function arith_unit( a, b : std_logic_vector; func : arith_func_t;
                     ci : std_logic)
return std_logic_vector;

-- based on the input and output of the arith_unit, update the SR register
-- flags for different operations
function arith_update_sr( sr_in : sr_t; a_msb : std_logic; b_msb : std_logic;
                          value : std_logic_vector; co_or_borrow : std_logic;
                          arithfunc : arith_func_t;
                          func : arith_sr_func_t)
return sr_t;

-- Returns either the bitwise AND, OR or XOR of a and b or the NOT of b
function logic_unit( a : std_logic_vector; b : std_logic_vector;
                     func : logic_func_t)
return std_logic_vector;

-- based on the output of the logic_unit, update the SR register flags for
-- different operations
function logic_update_sr( sr_in : sr_t; value : std_logic_vector;
                          func : logic_sr_func_t;
                          constant byte_width : integer := 8)
return sr_t;

function is_zero(a : std_logic_vector)
return std_logic;

function bshifter(a,b : std_logic_vector; c : std_logic; ops : shiftfunc_t)
return std_logic_vector;

function manip(x, y : std_logic_vector(31 downto 0); func : alumanip_t)
return std_logic_vector;

end package;

package body cpu2j0_components_pack is

  constant NO_WARNING: BOOLEAN := FALSE; -- default to emit warnings

function or_reduce(a : std_logic_vector) return std_logic is
  variable r : std_logic := '0';
begin
  for i in a'range loop
    r := r or a(i);
  end loop;
  return r;
end;

-- Like or_reduce, but doesn't not completely reduce to a single bit. Instead
-- it splits the input into bytes, reduces each, and returns a vector
function or_reduce_bytes(a : std_logic_vector; constant byte_width : integer)
  return std_logic_vector is
  constant num_bytes : integer := natural((real(a'length) / real(byte_width)));
  variable r : std_logic_vector(num_bytes - 1 downto 0);
begin
  for i in r'range loop
    r(i) := or_reduce(a((i + 1) * byte_width - 1 downto i * byte_width));
  end loop;
  return r;
end;

function is_zero(a : std_logic_vector) return std_logic is
  variable r : std_logic := '0';
begin
  return not or_reduce(a);
end;

-- xor every bit in vector a by bit b
function xor_all(a : std_logic_vector; b : std_logic) return std_logic_vector is
  alias av : std_logic_vector(a'length - 1 downto 0) is a;
  variable bv : std_logic_vector(a'length - 1 downto 0) := (others => b);
begin
  return av xor bv;
end;

function to_bit(b: boolean) return std_logic is
begin
  if b then
    return '1';
  else
    return '0';
  end if;
end;

function arith_unit(
  a, b : std_logic_vector;
  func : arith_func_t;
  ci : std_logic)
return std_logic_vector is
  alias xa : std_logic_vector(a'length - 1 downto 0) is a;
  alias xb : std_logic_vector(b'length - 1 downto 0) is b;

  variable is_sub : std_logic;
  variable b2 : std_logic_vector(xb'range);
  variable sum : unsigned(a'length downto 0);
  variable carry_in : unsigned(a'length downto 0);
begin
  if a'length /= b'length then
    assert NO_WARNING
      report "arith_unit: Arg size mismatch. Returning 0"
      severity WARNING;
    sum := to_unsigned(0, sum'length);
    return std_logic_vector(sum);
  end if;
  is_sub := to_bit(func = SUB);
  -- if ADD, then r = A+B+ci
  -- if SUB, then r = A-B-ci = A+not(B)+1-ci

  -- Perform a subtraction by negating the B operand. Take the twos complement
  -- by first flipping the bits and then xor-ing the ci to implement the +1.
  b2 := xor_all(xb, is_sub);
  -- If is_sub=0, then ci behaves normally. If is_sub=1 then
  -- r = A+not(B)+1-ci = A+not(B)+1-1 = A+not(B) when ci = 1
  --                   = A+not(B)+1              when ci = 0
  -- Xor-ing the ci by is_sub gives the correct calculation.
  carry_in := (others => '0');
  carry_in(0) := is_sub xor ci;

  sum := ('0' & unsigned(xa)) + ('0' & unsigned(b2)) + carry_in;

  -- convert left-most bit to a borrow instead of carry out when doing a subtraction
  sum(sum'left) := sum(sum'left) xor is_sub;
  return std_logic_vector(sum);
end;

function logic_unit(
  a : std_logic_vector;
  b : std_logic_vector;
  func : logic_func_t)
return std_logic_vector is
  alias xa : std_logic_vector(a'length - 1 downto 0) is a;
  alias xb : std_logic_vector(b'length - 1 downto 0) is b;
  variable r : std_logic_vector(xa'range);
begin
  if a'length /= b'length then
    assert NO_WARNING
      report "logic_unit: Arg size mismatch. Returning 0"
      severity WARNING;
    r := (others => '0');
    return r;
  end if;
  case func is
    when LOGIC_NOT =>
      r := xor_all(xb, '1');
    when LOGIC_AND =>
      r := xa and xb;
    when LOGIC_OR =>
      r := xa or xb;
    when LOGIC_XOR =>
      r := xa xor xb;
  end case;
  return r;
end;

function arith_update_sr(
  sr_in : sr_t;
  a_msb : std_logic;
  b_msb : std_logic;
  value : std_logic_vector;
  co_or_borrow : std_logic;
  arithfunc : arith_func_t;
  func : arith_sr_func_t)
return sr_t is
  alias v : std_logic_vector(value'length - 1 downto 0) is value;
  variable sr_out : sr_t := sr_in;
  variable v_msb : std_logic := v(v'left);
  variable is_sub : std_logic := to_bit(arithfunc = SUB);
  variable value_zero : std_logic := is_zero(v);
  variable common_gr_eq, sign_gr_eq, unsign_gr_eq : std_logic;
begin
  -- logic common to both signed and unsigned comparisons.
  -- common_gr = '1' => a >= b, but not the converse
  common_gr_eq := (not(a_msb) and not(b_msb) and not(v_msb)) or
                  (a_msb and b_msb and not(v_msb));
  sign_gr_eq := common_gr_eq or (not(a_msb) and b_msb);
  unsign_gr_eq := common_gr_eq or (a_msb and not(b_msb));
  case func is
    when ZERO =>
      sr_out.t := is_zero(v);
    when OVERUNDERFLOW =>
      sr_out.t := (not(a_msb) and not(b_msb xor is_sub) and v_msb) or
                  (a_msb and (b_msb xor is_sub) and not(v_msb));
    when UGRTER =>
      sr_out.t := unsign_gr_eq and not(value_zero);
    when UGRTER_EQ =>
      sr_out.t := unsign_gr_eq;
    when SGRTER =>
      sr_out.t := sign_gr_eq and not(value_zero);
    when SGRTER_EQ =>
      sr_out.t := sign_gr_eq;
    when DIV0S =>
      sr_out.q := a_msb;
      sr_out.m := b_msb;
      sr_out.t := a_msb xor b_msb;
    when DIV1 =>
      sr_out.q := a_msb xor sr_in.m xor co_or_borrow;
      sr_out.t := not (sr_out.q xor sr_in.m);
  end case;
  return sr_out;
end;

function logic_update_sr(
  sr_in : sr_t;
  value : std_logic_vector;
  func : logic_sr_func_t;
  constant byte_width : integer := 8)
return sr_t is
  alias v : std_logic_vector(value'length - 1 downto 0) is value;
  variable sr_out : sr_t := sr_in;
begin
  case func is
    when ZERO =>
      sr_out.t := is_zero(v);
    when BYTE_EQ =>
      -- assumes the value is a xor b
      sr_out.t := or_reduce(xor_all(or_reduce_bytes(v, byte_width), '1'));
  end case;
  return sr_out;
end;

function left_rotate(a : std_logic_vector; b : std_logic_vector) return std_logic_vector is
   constant num_bits : integer := a'length;
   variable sr, yr : std_logic_vector(a'range);
   variable offset : integer range 0 to num_bits/2;
   variable k : integer;
   begin

   yr := a;
   offset := num_bits/2;

   for i in b'range loop
      if b(i) = '1' then
         for j in a'range loop
            if j + offset >= num_bits then k := j + offset - num_bits;
            else                           k := j + offset;            end if;

            sr(k) := yr(j);
         end loop;
      else
         for j in a'range loop
            sr(j) := yr(j);
         end loop;
      end if;

      offset := offset/2;
      yr := sr;
   end loop;

   return yr;
end function;

function calf_fcn(b : unsigned) return std_logic_vector is
   constant b_left : integer := b'length - 1;
   constant result_bits : integer := 2 ** b'length;
   --variable ib : natural range 0 to result_bits-1 := to_integer(b);
   variable ib : natural := to_integer(b);
   variable f : std_logic_vector(result_bits-1 downto 0) := (others => '0');
   begin

   for i in f'range loop
      if i < ib then f(i) := '1'; end if;
   end loop;
   return f;
end function;

function calp_fcn(f : std_logic_vector; rot, left : std_logic) return std_logic_vector is
   variable p : std_logic_vector(f'range);
   begin

   for i in f'range loop
      p(i) := (f(i) xor left) or rot;
   end loop;
   return p;
end function;

function caly_fcn(y, p : std_logic_vector; ops : shiftfunc_t; left, c, a : std_logic) return std_logic_vector is
   variable t : std_logic_vector(y'range);
   variable s : std_logic := '0';
   -- assumes y and p have the same range and that their 'right is 0
   constant num_bits : integer := p'length;
   begin

   if ops = arith and left = '0' then s := a; end if;

   if p(0) = '1'                   then t(0) := y(0);
   elsif left = '1' and ops = rotc then t(0) := c;
   else                                 t(0) := s;      end if;

   if p(num_bits-1) = '1'          then t(num_bits-1) := y(num_bits-1);
   elsif left = '0' and ops = rotc then t(num_bits-1) := c;
   else                                 t(num_bits-1) := s; end if;

   for i in 1 to num_bits-2 loop
      if p(i) = '1' then t(i) := y(i);
      else               t(i) := s;    end if;
   end loop;

   return t;
end function;

-- Barrel shifter implementation for efficient logic, as per:
-- http://www.princeton.edu/~rblee/ELE572Papers/Fall04Readings/Shifter_Schulte.pdf

function bshifter(a,b : std_logic_vector; c : std_logic; ops : shiftfunc_t)
return std_logic_vector is
   variable left, rot : std_logic := '0';
   constant a_left : integer := a'length - 1;
   constant b_left : integer := b'length - 1;
   alias xa : std_logic_vector(a_left downto 0) is a;
   alias xb : std_logic_vector(b_left downto 0) is b;
   variable b_mag : std_logic_vector(b_left-1 downto 0);
   variable f, p, y1, y : std_logic_vector(a_left downto 0);
   begin
   -- Verify argument lengths match. The b argument is a sign bit plus
   -- N bits, and the a arg must be 2^N bits.
   if integer(a'length) /= integer(2 ** (b'length - 1)) then
     assert NO_WARNING
       report "BSHIFTER: Arg size mismatch, returning A"
       severity WARNING;
     return a;
   end if;

   -- split b into a shift magnitude and shift direction
   b_mag := xb(b_mag'range);
   left := not xb(b_left);

   if ops = rotate then rot := '1'; end if;

   f  := calf_fcn(unsigned(b_mag));
   p  := calp_fcn(f, rot, left);
   y1 := left_rotate(xa, b_mag);

   y  := caly_fcn(y1, p, ops, left, c, xa(a_left));
   return y;
end function;

function manip(x, y : std_logic_vector(31 downto 0); func : alumanip_t)
  return std_logic_vector is
  variable b0, b1, b2, b3 : std_logic_vector(7 downto 0);
  variable sign_bit : std_logic;
  variable sign_byte : std_logic_vector(7 downto 0);
begin
  if func = EXTEND_SBYTE then
    sign_bit := y(7);
  else
    sign_bit := y(15);
  end if;
  sign_byte := (others => sign_bit);

  -- assign each byte of output separately to group same cases
  case func is
    when SWAP_BYTE
       | SET_BIT_7    => b3 := y(31 downto 24);
    when EXTEND_UBYTE
       | EXTEND_UWORD => b3 := (others => '0');
    when EXTEND_SBYTE
       | EXTEND_SWORD => b3 := sign_byte;
    -- others is SWAP_WORD or EXTRACT
    when others       => b3 := y(15 downto  8);
  end case;
  case func is
    when SWAP_BYTE
       | SET_BIT_7    => b2 := y(23 downto 16);
    when EXTEND_UBYTE
       | EXTEND_UWORD => b2 := (others => '0');
    when EXTEND_SBYTE
       | EXTEND_SWORD => b2 := sign_byte;
     -- others is SWAP_WORD  or EXTRACT
    when others       => b2 := y(7  downto  0);
  end case;
  case func is
    when SWAP_BYTE    => b1 := y(7  downto  0);
    when SWAP_WORD    => b1 := y(31 downto 24);
    when EXTEND_UBYTE => b1 := (others => '0');
    when EXTEND_UWORD
       | EXTEND_SWORD
       | SET_BIT_7    => b1 := y(15 downto  8);
    when EXTEND_SBYTE => b1 := sign_byte;
    -- others is EXTRACT
    when others       => b1 := x(31 downto 24);
  end case;
  case func is
    when SWAP_BYTE    => b0 := y(15 downto  8);
    when SWAP_WORD    => b0 := y(23 downto 16);
    when EXTEND_UBYTE
       | EXTEND_UWORD
       | EXTEND_SBYTE
       | EXTEND_SWORD => b0 := y(7  downto  0);
    when SET_BIT_7    => b0 := '1' & y(6  downto  0);
    -- others is EXTRACT
    when others       => b0 := x(23 downto 16);
  end case;
  return b3 & b2 & b1 & b0;
end function;

end cpu2j0_components_pack;
