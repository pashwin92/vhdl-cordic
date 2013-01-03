LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY synth_cordic IS
PORT(
  clk     : IN std_logic;
  reset_n : IN std_logic;

  z_ip    : IN std_logic_vector(16 DOWNTO 0);
  x_ip    : IN std_logic_vector(16 DOWNTO 0);
  y_ip    : IN std_logic_vector(16 DOWNTO 0);

  cos_op  : OUT std_logic_vector(16 DOWNTO 0);
  sin_op  : OUT std_logic_vector(16 DOWNTO 0);
);
END ENTITY synth_cordic;

ARCHITECTURE rtl OF synth_cordic IS
  
  TYPE signed_array IS ARRAY(natural RANGE <> ) OF signed(17 DOWNTO 0);

  --ARCTAN Array format 1.16 in radians
  CONSTANT tan_array : signed_array := (
      to_signed(51471 , 18)
    , to_signed(30385 , 18)
    , to_signed(16054 , 18)
    , to_signed(8149  , 18)

    , to_signed(4090  , 18)
    , to_signed(2047  , 18)
    , to_signed(1023  , 18)
    , to_signed(511   , 18)

    , to_signed(255   , 18)
    , to_signed(127   , 18)
    , to_signed(63    , 18)
    , to_signed(31    , 18) 

    , to_signed(15    , 18)
    , to_signed(7     , 18)
    , to_signed(3     , 18)
    , to_signed(1     , 18)

    , to_signed(0     , 18)
  );


  SIGNAL x_array : signed_array(0 TO 14) := (OTHERS => (OTHERS => '0'));
  SIGNAL y_array : signed_array(0 TO 14) := (OTHERS => (OTHERS => '0'));
  SIGNAL z_array : signed_array(0 TO 14) := (OTHERS => (OTHERS => '0'));
BEGIN

  -- convert inputs into signed format

  PROCESS(reset_n, clk)
    BEGIN
      IF reset_n = '0' THEN
        x_array <= (OTHERS => (OTHERS => '0'));
        y_array <= (OTHERS => (OTHERS => '0'));
        z_array <= (OTHERS => (OTHERS => '0'));

      ELSIF rising_edge(clk) THEN
        IF signed(z_ip) < to_signed(0,18) THEN
          x_array(x_array'low) <= signed(x_ip) + signed('0' & y_ip);
          y_array(y_array'low) <= signed(y_ip) - signed('0' & x_ip);
          z_array(z_array'low) <= signed(z_ip) + tan_array(0);
        ELSE
          x_array(x_array'low) <= signed(x_ip) - signed('0' & y_ip);
          y_array(y_array'low) <= signed(y_ip) + signed('0' & x_ip);
          z_array(z_array'low) <= signed(z_ip) - tan_array(0);
        END IF;


        -- http://repositories.lib.utexas.edu/bitstream/handle/2152/1472/arbaughj20424.pdf
        -- Section 3.7 Iteration Equations
        FOR i IN 1 TO 14 LOOP
          IF z_array(i-1) < to_signed(0,17) THEN
            x_array(i) <= x_array(i-1) + (y_array(i-1) sll i);
            y_array(i) <= y_array(i-1) - (x_array(i-1) sll i);
            z_array(i) <= z_array(i-1) + tan_array(i);
          ELSE
            x_array(i) <= x_array(i-1) - (y_array(i-1) sll i);
            y_array(i) <= y_array(i-1) + (x_array(i-1) sll i);
            z_array(i) <= z_array(i-1) - tan_array(i);
          END IF;
        END LOOP;
      END IF;
  END PROCESS;

  cos_op <= std_logic_vector(x_array(x_array'high)(16 DOWNTO 0));
  sin_op <= std_logic_vector(y_array(y_array'high)(16 DOWNTO 0));

END ARCHITECTURE rtl;