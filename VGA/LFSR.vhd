library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity LFSR64 is
	Port(
		Resetn: in std_logic;
		Clk: in std_logic;
		LFSR64Out: out std_logic_vector(63 downto 0)
	);
end LFSR64;

--}} End of automatically maintained section

architecture LFSR64 of LFSR64 is

signal pseudo_rand : std_logic_vector(63 downto 0);

begin

	-- enter your statements here --
	process(clk)
		-- maximal length 64-bit xnor LFSR
		function lfsr64func(x : std_logic_vector(63 downto 0)) return std_logic_vector is
		begin
			return x(62 downto 0) & not(x(0) xor x(1) xor x(3) xor x(4));
		end function;
	begin
		if rising_edge(clk) then
			if resetn='0' then
				pseudo_rand <= (others => '0');
			else
				pseudo_rand <= lfsr64func(pseudo_rand);
			end if;
		end if;
	end process;
	
	LFSR64Out <= pseudo_rand;

end LFSR64;
