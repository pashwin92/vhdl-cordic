LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE IEEE.std_logic_signed.ALL;

LIBRARY work;
USE work.cordic_stage_pkg.ALL;

ENTITY cordic IS
  PORT (
    clk    : IN std_logic;
    reset  : IN std_logic; -- active high due tto NIOS II limitation
    --
    -- clock enable required by Nios II custom components.  When asserted
    -- high the CORDIC component can move forwared with its processing
    clk_en : IN std_logic;
    --
    -- Angle in degrees. The angle is formatted as a fixed point notation
    -- with 9-bit allocated for the integer and 8-bits for the decimal.
    ANGLE  : IN std_logic_vector(31 DOWNTO 0);
    --
    -- this signal is asserted high to start the CORDIC process
    START  : IN std_logic;
    --
    -- This signal is asserted high when CORDIC process is done
    done   : OUT std_logic;
    --
    -- The result of the CORDIC process.  The output values contains the
    -- sin result on bits [31:16] and cos result on bits [15:0].  Both the
    -- sine and cosine results are in fixed point notation with one sign bit
    -- followed by 8-bits behind decimal point.
    result : OUT std_logic_vector(31 DOWNTO 0)
  );
END ENTITY cordic;



ARCHITECTURE rtl OF cordic IS



  TYPE signed_array IS ARRAY(natural RANGE <> ) OF signed(16 DOWNTO 0);
  CONSTANT atan_table : signed_array := (
    -- Q0.15 Fixed Point, Scale Factor (K) = 1024
      to_signed(23040, 17)   -- 22.5
    , to_signed(11520, 17)   -- 11.25
    , to_signed(5760, 17)   -- 5.625
    , to_signed(2880, 17)    -- 2.8125
    , to_signed(1440, 17)    -- 1.40625
    , to_signed(720, 17)    -- 0.703125
    , to_signed(360, 17)     -- 0.3515625
    , to_signed(180, 17)     -- 0.3515625
    -- , to_signed(57, 17)
    -- , to_signed(29, 17)
    -- , to_signed(14, 17)
    -- , to_signed(7, 17)
    -- , to_signed(4, 17)
    -- , to_signed(2, 17)
    -- , to_signed(1, 17)
    -- , to_signed(0, 17)

  );

  CONSTANT K : signed(8 DOWNTO 0) := to_signed(622, 9); -- magic number 0.60725293 * (K = 1024)

  SIGNAL x : signed(8 DOWNTO 0)   := (OTHERS => '0');
  SIGNAL y : signed(8 DOWNTO 0)   := (OTHERS => '0');
  SIGNAL z : signed(16 DOWNTO 0)  := (OTHERS => '0');

  ALIAS sin IS result(31 DOWNTO 16);
  ALIAS cos IS result(15 DOWNTO 0);

  TYPE xy_stage_array IS ARRAY(0 TO atan_table'length) OF signed(x'range);
  TYPE  z_stage_array IS ARRAY(0 TO atan_table'length) OF signed(z'range);

  SIGNAL x_stages : xy_stage_array := (OTHERS => (OTHERS => '0'));
  SIGNAL y_stages : xy_stage_array := (OTHERS => (OTHERS => '0'));
  SIGNAL z_stages : z_stage_array  := (OTHERS => (OTHERS => '0'));

  SIGNAL i_angle : std_logic_vector(angle'range) := (OTHERS => '0');
  SIGNAL i_sin   : std_logic_vector(sin'range) := (OTHERS => '0');
  SIGNAL i_cos   : std_logic_vector(cos'range) := (OTHERS => '0');

BEGIN

  x_stages(0) <= K;
  y_stages(0) <= (OTHERS => '0');
  z_stages(0) <= (OTHERS => '0');

  i_sin <= "0000000" & std_logic_vector(y_stages(8));
  i_cos <= "0000000" & std_logic_vector(x_stages(8));

PROCESS(clk) BEGIN
IF rising_edge(clk) THEN
  i_angle <= angle;
  sin     <= i_sin;
  cos     <= i_cos;
END IF;
END PROCESS;


  
stage_generate: FOR i in 0 to atan_table'high GENERATE
    stage : cordic_stage
    GENERIC MAP(
      STAGE     => i,
      ATAN_VAL  => atan_table(i)
    )
    PORT MAP(
      angle => i_angle,
      
      x_in  => x_stages(i),
      y_in  => y_stages(i),
      z_in  => z_stages(i),

      x_out => x_stages(i+1),
      y_out => y_stages(i+1),
      z_out => z_stages(i+1)
    );
  END GENERATE;
  
END ARCHITECTURE rtl;