-------------------------------------------------------------------------------
--
-- Title       : Stack
-- Design      : Trainy
-- Author      : 
-- Company     : 
--
-------------------------------------------------------------------------------
--
-- File        : Stack.vhd
-- Generated   : Thu Jan 17 08:50:12 2019
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
--{entity {Stack} architecture {Stack}}

library IEEE;
use IEEE.STD_LOGIC_1164.all;	  
use ieee.numeric_std.all;

entity Stack is			   
	
	generic(data_size: integer := 8;
			address_size   : integer := 8
	);
	
	 port(
		 push			 : in STD_LOGIC;
		 en 		 	 : in STD_LOGIC;
		 data_in 	 : in STD_LOGIC_VECTOR(data_size-1 downto 0);
		 data_out	 : out STD_LOGIC_VECTOR(data_size-1 downto 0);
		 clk 		 	 : in STD_logic;							  
		 reset 		 : in STD_logic;
		 STACK_FULL  : out STD_LOGIC;						
		 STACK_EMPTY : out STD_LOGIC
	     );
end Stack;

 

architecture Stack of Stack is 



Component Memory
	  generic(
		Data_Width : INTEGER := data_size;
		Addr_Width : INTEGER := address_size
		);
	  port(
		 clk : in STD_LOGIC;
		 cs : in STD_LOGIC;
		 we : in STD_LOGIC;
		 addr : in STD_LOGIC_VECTOR(Addr_Width -1 downto 0);
		 data_in : in STD_LOGIC_VECTOR(Data_width -1 downto 0);
		 data_out : out STD_LOGIC_VECTOR(Data_width -1 downto 0)
	     );
end component;

signal 	address: std_logic_vector(address_size-1 downto 0) := (others=>'0');
signal empty, full : std_logic;
signal input, output : std_logic_vector(data_size-1 downto 0);

begin

	ram : Memory
	port map(
		clk   => clk,
		cs   => en,
		we   => push,
		addr => address,
		data_in => input,
		data_out => output
	);		
	
	
	STACK_EMPTY <= empty;
	STACK_FULL  <= full; 
	
	empty <= '1' when to_integer(unsigned(address)) = 0 else '0';
	full  <= '1' when to_integer(unsigned(not address)) = 0 else '0';
		
	data_out <= output;	
	input  <= data_in;	
		


		process(clk,reset)
	begin			
		
		
		if reset = '1' then 
			address <= (others=> '0');
		elsif rising_edge(clk) then	
			if en = '1' then
				if push = '1' and full = '0' then 
					address <= std_logic_vector(unsigned(address)+1);
				elsif push = '0' and empty = '0' then 				 
					address <= std_logic_vector(unsigned(address)-1);
				else 
					address <= address;
				end if;	 
			end if;
		end if;	
		
		
	end process; 

		

			   
	

end Stack;
