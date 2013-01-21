LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE cordic_stage_pkg IS
	COMPONENT cordic_stage IS
		GENERIC(
			XY_WIDTH : natural := 9;
			Z_WIDTH  : natural := 17;
			STAGE    : natural;
			ATAN_VAL : signed
		);
		PORT(
			angle : IN std_logic_vector(31 DOWNTO 0);

            x_in  : IN signed(XY_WIDTH-1 DOWNTO 0);
            y_in  : IN signed(XY_WIDTH-1 DOWNTO 0);
            z_in  : IN signed(Z_WIDTH-1 DOWNTO 0);

            x_out : OUT signed(XY_WIDTH-1 DOWNTO 0);
            y_out : OUT signed(XY_WIDTH-1 DOWNTO 0);
            z_out : OUT signed(XY_WIDTH-1 DOWNTO 0)
		);
	END COMPONENT cordic_stage;
END PACKAGE cordic_stage_pkg;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY work;
USE work.signed_bitshift_pkg.ALL;

ENTITY cordic_stage IS
	GENERIC(
		XY_WIDTH : natural := 8;
		Z_WIDTH  : natural := 8;
		STAGE    : natural;
		ATAN_VAL : signed
	);
	PORT(
        angle : IN std_logic_vector(31 DOWNTO 0);

        x_in  : IN signed(XY_WIDTH-1 DOWNTO 0);
        y_in  : IN signed(XY_WIDTH-1 DOWNTO 0);
        z_in  : IN signed(Z_WIDTH-1 DOWNTO 0);

        x_out : OUT signed(XY_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        y_out : OUT signed(XY_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        z_out : OUT signed(Z_WIDTH-1 DOWNTO 0)  := (OTHERS => '0')
	);
END ENTITY cordic_stage;

ARCHITECTURE rtl OF cordic_stage IS
	
  	TYPE   i_array IS ARRAY(0 TO STAGE+1) OF signed(x_in'range);

	SIGNAL i_x : i_array := (OTHERS => (OTHERS => '0'));
	SIGNAL i_y : i_array := (OTHERS => (OTHERS => '0'));
BEGIN


PROCESS(x_in, y_in, z_in, angle, i_x, i_y) BEGIN
i_x(0) <= x_in;
i_y(0) <= y_in;
FOR i in 0 to STAGE LOOP
	i_x(i+1) <= '0' & i_x(i)( i_x(i)'high-1 downto 0);
	i_y(i+1) <= '0' & i_y(i)( i_y(i)'high-1 downto 0);
END LOOP;

IF z_in < signed(angle) THEN
	x_out <= signed(x_in) + signed(i_y(i_y'high));
	y_out <= signed(y_in) - signed(i_x(i_x'high));
	z_out <= z_in 		  + ATAN_VAL;
ELSE
	x_out <= signed(x_in) - signed(i_y(i_y'high));
	y_out <= signed(y_in) + signed(i_x(i_x'high));
	z_out <= z_in         - ATAN_VAL;
END IF;

END PROCESS;

END ARCHITECTURE rtl;
