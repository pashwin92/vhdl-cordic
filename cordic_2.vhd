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
    result : OUT std_logic_vector(31 DOWNTO 0)
  );
END ENTITY cordic;

ARCHITECTURE rtl OF cordic IS

  CONSTANT HIGH : std_logic := '1';
  CONSTANT LOW  : std_logic := '0';

  TYPE signed_array IS ARRAY(natural RANGE <> ) OF signed(15 DOWNTO 0);  
  CONSTANT atan_table : signed_array := (
    -- Q0.15 Fixed Point, Scale Factor (R) = 2^16 / 180
    to_signed(16384 ,16)   
  , to_signed(9672  ,16)    
  , to_signed(5110  ,16)    
  , to_signed(2594  ,16)    
  , to_signed(1302  ,16)    
  , to_signed(652   ,16)   
  , to_signed(326   ,16)   
  , to_signed(163   ,16)   
  -- , to_signed(81    ,16)    
  -- , to_signed(41    ,16)    
  -- , to_signed(20    ,16)    
  -- , to_signed(10    ,16)    
  -- , to_signed(5     ,16)   
  -- , to_signed(3     ,16)   
  -- , to_signed(1     ,16)   
  -- , to_signed(1     ,16)   

  );

  TYPE state_type IS (IDLE, PRESET, WORK, NOTIFY);
  SIGNAL current_state : state_type := IDLE;
  SIGNAL next_state    : state_type := IDLE;

  SIGNAL x : signed(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL y : signed(7 DOWNTO 0) := (OTHERS => '0');

  SIGNAL z : signed(15 DOWNTO 0);

  ALIAS sin IS result(31 DOWNTO 16);
  ALIAS cos IS result(15 DOWNTO 0);

  FUNCTION shift_right(n : signed; i : integer)
  RETURN signed IS
    VARIABLE result : signed(n'range);
  BEGIN
    result := n;
    FOR k in 0 to i LOOP
      result := '0' & result(result'high DOWNTO 1);
    END LOOP;
    
    RETURN result;
  END shift_right;


BEGIN

  sync : PROCESS(clk, reset)
    BEGIN
      IF reset = HIGH THEN
        current_state <= IDLE;
      ELSIF rising_edge(clk) THEN
        IF clk_en = HIGH THEN
          current_state <= next_state;
        END IF;
      END IF;
  END PROCESS;

  comb : PROCESS(current_state, START)
    BEGIN
      CASE(current_state) IS
        WHEN IDLE     =>
          done <= LOW;

          IF START = HIGH THEN
            next_state <= PRESET;
          ELSE
            next_state <= IDLE;
          END IF;

        WHEN PRESET =>
          next_state <= WORK;


        WHEN WORK  =>
          next_state <= NOTIFY;


        WHEN NOTIFY =>
          done <= HIGH;

          IF START = HIGH THEN
            next_state <= PRESET;
          ELSE
            next_state <= NOTIFY;
          END IF;


        WHEN OTHERS   =>
          next_state <= IDLE;

      END CASE;
  END PROCESS;

  calculate : PROCESS(next_state)
    BEGIN
      IF (next_state = WORK) THEN
        
          FOR i IN 0 to 7 LOOP
            IF z < signed(ANGLE) THEN
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
  END PROCESS;

  signals : PROCESS(clk) BEGIN
  IF rising_edge(clk) THEN
    CASE(next_state) IS
      WHEN IDLE =>

      WHEN PRESET =>
         -- set to magic number 0.60725293
        x <= to_signed(221, 8);
        y <= to_signed(0, 8);
        z <= to_signed(0, 16);

      WHEN WORK =>

      WHEN NOTIFY =>
        sin <= x"00" & std_logic_vector(y);
        cos <= x"00" & std_logic_vector(x);

      WHEN OTHERS =>
    END CASE;
  END IF;
  END PROCESS;

END ARCHITECTURE rtl;