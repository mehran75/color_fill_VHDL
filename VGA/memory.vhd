-------------------------------------------------------------------------------
--
-- Title       : memory
-- Design      : CAD_HW04_MEHRAN_RAFIEE
-- Author      : 
-- Company     : 
--
-------------------------------------------------------------------------------
--
-- File        : memory.vhd
-- Generated   : Sun Dec  9 19:43:12 2018
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.22
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {memory} architecture {memory}}

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.numeric_std.all;
--use IEEE.STD_LOGIC_ARITH.all;

entity memory is
	generic (Data_Width :integer := 8;
			 Addr_Width :integer := 8);
	 port(
		 clk : in STD_LOGIC;
		 cs : in STD_LOGIC;
		 --cs2 : in STD_LOGIC;
		 we : in STD_LOGIC;
		 --we2 : in STD_LOGIC;
		 addr : in STD_LOGIC_VECTOR(Addr_Width -1 downto 0);
		 --addr2 : in STD_LOGIC_VECTOR(Addr_Width -1 downto 0);
		 data_in : in STD_LOGIC_VECTOR(Data_width -1 downto 0);
		 data_out : out STD_LOGIC_VECTOR(Data_width -1 downto 0)					 			 		
	     );
end memory;

--}} End of automatically maintained section

architecture memory of memory is 
type memory_arch is array(2**Addr_Width -1 downto 0) 
							of std_logic_vector(Data_width -1 downto 0);
 
signal ram : memory_arch;

--signal data_out : std_logic_vector(Data_width -1 downto 0);
begin
	
	
	-- Write --		
	process (clk)
	begin
		
		if (clk'event and clk = '1') then
			-- port number 1--
			if (cs = '1' and we = '1') then
				ram(to_integer(unsigned(addr))) <= data_in ;			
			end if;
		end if;	
	end process; 
	
	
	-- Read from port 1--
	process(addr,cs,we)
	begin
		
		if (cs = '1' and we = '0') then
			data_out <= ram(to_integer(unsigned(addr)));	  
		else
			data_out <= (others => '0');
		end if;
		
	end process;
	


end memory;
