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


  TYPE signed_array IS ARRAY(natural RANGE <> ) OF signed(16 DOWNTO 0);
  CONSTANT atan_table : signed_array := (
    -- Q0.15 Fixed Point, Scale Factor (R) = 2^16 / 180
	  to_signed(5760, 17)
	, to_signed(2880, 17)
	, to_signed(1440, 17)
	, to_signed(720, 17)
	, to_signed(360, 17)
	, to_signed(180, 17)
	, to_signed(90, 17)
	, to_signed(45, 17)
  );

  CONSTANT K : signed(8 DOWNTO 0) := to_signed(155,K'length);

  SIGNAL x : signed(8 DOWNTO 0);
  SIGNAL y : signed(8 DOWNTO 0);
  SIGNAL z : signed(16 DOWNTO 0);

  ALIAS sin IS result(31 DOWNTO 16);
  ALIAS cos IS result(15 DOWNTO 0);

  SIGNAL round : std_logic_vector(3 DOWNTO 0) := (OTHERS => '0');

BEGIN

	PROCESS(angle) BEGIN
		round <= '0';
	END PROCESS;

	PROCESS(clk) BEGIN
	IF rising_edge(clk) THEN
		IF (round < x"8") THEN

			x <= K;
			y <= (OTHERS => '0');
			z <= (OTHERS => '0');
			
			IF z < angle THEN
				x <= x - shift_right(y,i);
              	y <= y + shift_right(x,i);
              	z <= z + atan_table(i);
            ELSE
            	x <= x + shift_right(y,i);
              	y <= y - shift_right(x,i);
              	z <= z - atan_table(i);
			END IF;

			round <= round + 1;
		END IF;
	END IF;
        sin <= x"00" & std_logic_vector(y);
        cos <= x"00" & std_logic_vector(x);
	END PROCESS;


END ARCHITECTURE rtl;