library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cordic_tb is
end entity cordic_tb;

architecture tb of cordic_tb is
	component cordic is
	  port (
	    clk    : in std_logic;
	    reset  : in std_logic; -- active high due tto nios ii limitation
	    --
	    -- clock enable required by nios ii custom components.  when asserted
	    -- high the cordic component can move forwared with its processing
	    clk_en : in std_logic;
	    --
	    -- angle in degrees. the angle is formatted as a fixed point notation
	    -- with 9-bit allocated for the integer and 8-bits for the decimal.
	    angle  : in std_logic_vector(31 downto 0);
	    --
	    -- this signal is asserted high to start the cordic process
	    start  : in std_logic;
	    --
	    -- this signal is asserted high when cordic process is done
	    done   : out std_logic;
	    --
	    -- the result of the cordic process.  the output values contains the
	    -- sin result on bits [31:16] and cos result on bits [15:0].  both the
	    -- sine and cosine results are in fixed point notation with one sign bit
	    -- followed by 8-bits behind decimal point.
	    result : out std_logic_vector(31 downto 0)
	  );
	end component cordic;

	constant LOW  : std_logic := '0';
	constant HIGH : std_logic := '1';

    signal clk    : std_logic := LOW;
    signal clk_en : std_logic := LOW;
    signal reset  : std_logic := HIGH;
    signal start  : std_logic := LOW;
    signal done   : std_logic;
    signal result : std_logic_vector(31 downto 0);
    signal angle  : std_logic_vector(31 downto 0);

begin

    clk <= not clk after 20 ns;

	process begin
		angle <= std_logic_vector(to_signed((0),angle'length));

		wait for 15 ns;
    	reset  <= LOW;
    	wait for 40 ns;
    	clk_en <= HIGH;

    	wait for 20 ns;
    	start <= HIGH;

    	wait until rising_edge(clk);
    	start <= LOW;


    	FOR i in 0 to 90 LOOP
    		wait until rising_edge(clk);
    		angle <= std_logic_vector(to_signed((i * 1024),angle'length));
    	END LOOP;


    wait until done = HIGH;
    wait;
	end process;

	uut : component cordic port map(
        clk    => clk,
        reset  => reset,
        clk_en => clk_en,
        angle  => angle,
        start  => start,
        done   => done,
        result => result
	);

end architecture tb;