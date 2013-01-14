LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE signed_bitshift_pkg IS
	
	FUNCTION signed_sra(n : signed; i : natural)
	RETURN signed;

END PACKAGE signed_bitshift_pkg;

PACKAGE BODY signed_bitshift_pkg IS

	FUNCTION signed_sra(n : signed; i : natural)
	RETURN signed IS
		VARIABLE result : signed(n'range);
	BEGIN
		result := n;
		FOR k in 0 to i LOOP
			result := '0' & result(result'high DOWNTO 1);
		END LOOP;

		RETURN result;
	END signed_sra;

END signed_bitshift_pkg;
