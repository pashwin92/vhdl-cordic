LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

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
    result : OUT std_logic_vector(31 DOWNTO 0);
  );
END ENTITY cordic;

ARCHITECTURE rtl OF cordic IS

  CONSTANT HIGH : std_logic := '1';
  CONSTANT LOW  : std_logic := '0';

  TYPE signed_array IS ARRAY(natural RANGE <> ) OF signed(15 DOWNTO 0);  
  CONSTANT atan_table : signed_array := (
    -- Q0.15 Fixed Point, Scale Factor (R) = 2^16 / 180
    to_signed(16384 , signed_array'length)   
  , to_signed(9672  , signed_array'length)    
  , to_signed(5110  , signed_array'length)    
  , to_signed(2594  , signed_array'length)    
  , to_signed(1302  , signed_array'length)    
  , to_signed(652   , signed_array'length)   
  , to_signed(326   , signed_array'length)   
  , to_signed(163   , signed_array'length)   
  , to_signed(81    , signed_array'length)    
  , to_signed(41    , signed_array'length)    
  , to_signed(20    , signed_array'length)    
  , to_signed(10    , signed_array'length)    
  , to_signed(5     , signed_array'length)   
  , to_signed(3     , signed_array'length)   
  , to_signed(1     , signed_array'length)   
  , to_signed(1     , signed_array'length)   

  );

  TYPE state_type IS (IDLE, WORKING, DONE);
  SIGNAL current_state : state_type := IDLE;
  SIGNAL next_state    : state_type := IDLE;

  SIGNAL x : std_logic_vector(8 DOWNTO 0);
  SIGNAL y : std_logic_vector(8 DOWNTO 0);

  SIGNAL z : std_logic_vector(15 DOWNTO 0);

  ALIAS sin IS result(31 DOWNTO 16);
  ALIAS cos IS result(15 DOWNTO 0);
BEGIN

  sync : PROCESS(clk, reset)
    BEGIN
      IF reset = HIGH THEN
        current_state <= IDLE;
      ELSIF rising_edge(clk) THEN
        current_state <= next_state;
      END IF;
  END PROCESS;

  comb : PROCESS(next_state)
    BEGIN
      CASE(next_state) IS
        WHEN IDLE     =>
          done <= LOW;

          IF START = HIGH THEN
            next_state <= WORKING;
          ELSE
            next_state <= IDLE;
          END IF;


        WHEN WORKING  =>
          START      <= LOW;
          next_state <= DONE;


        WHEN DONE     =>
          done <= HIGH;

          IF START = HIGH THEN
            next_state <= WORKING;
          ELSE
            next_state <= DONE;
          END IF;


        WHEN OTHERS   =>
          next_state <= IDLE;

      END CASE;
  END PROCESS;

  calculate : PROCESS(clk, reset, next_state)
    BEGIN
      IF rising_edge(clk) THEN

        IF reset = HIGH THEN
          x <= (OTHERS => '0');
          y <= (OTHERS => '0');
          z <= (OTHERS => '0');
        ELSIF next_state = WORKING THEN
        
          FOR i IN atan_table'range LOOP
            IF z_reg < ANGLE THEN
              x <= x - shift_right(y,i);
              y <= y + shift_right(x,i);
              z <= z + atan_table(i);
            ELSE
              x <= x + shift_right(y,i);
              y <= y - shift_right(x,i);
              z <= z - atan_table(i);
            END IF;
          END LOOP; 

        END IF;
      END IF;
  END PROCESS;

  sin <= y;
  cos <= x;

END ARCHITECTURE rtl;