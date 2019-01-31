
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.numeric_std.all;

entity Stack is			   
	
	generic(data_size: integer := 8;
		address_size   : integer := 8
		);
	
	port(
		push		 : in STD_LOGIC;
		pop 		 : in STD_LOGIC;
		en 		 : in STD_LOGIC;
		data_in 	 : in STD_LOGIC_VECTOR(data_size-1 downto 0);
		data_out	 : out STD_LOGIC_VECTOR(data_size-1 downto 0);
		clk 		 : in STD_logic;							  
		reset 		 : in STD_logic;
		STACK_FULL  : out STD_LOGIC;						
		STACK_EMPTY  : out STD_LOGIC
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
			cs1 : in STD_LOGIC;
			cs2 : in STD_LOGIC;
			we1 : in STD_LOGIC;
			we2 : in STD_LOGIC;
			addr1 : in STD_LOGIC_VECTOR(Addr_Width -1 downto 0);
			addr2 : in STD_LOGIC_VECTOR(Addr_Width -1 downto 0);
			data1 : inout STD_LOGIC_VECTOR(Data_width -1 downto 0);
			data2 : inout STD_LOGIC_VECTOR(Data_width -1 downto 0)
			);
	end component;
	
	signal 	address, address2: std_logic_vector(address_size-1 downto 0) := (others=>'0');
	signal empty, full : std_logic;
	signal input, output : std_logic_vector(data_size-1 downto 0);
	
begin
	
	ram : Memory
	port map(
		clk   => clk,
		cs1   => push,
		cs2   => pop,
		we1   => '1',
		we2   => '0',
		addr1 => address,
		addr2 => address2,
		data1 => input,
		data2 => output
		);		
	
	
	STACK_EMPTY <= empty;
	STACK_FULL  <= full; 
	
	empty <= '1' when to_integer(unsigned(address)) = 0 else '0';
	full  <= '1' when to_integer(unsigned(not address)) = 0 else '0';
	
	address2 <= address -1;
	data_out <= output ;	
	input  <= data_in when en = '1' else (others=>'Z');	
	
	
	
	process(clk,reset)
	begin			
		
		
		if reset = '1' then 
			address <= (others=> '0');
		elsif rising_edge(clk) then	
			if en = '1' then
				address <= address;
				if push = '1' and full = '0' then
					address <= std_logic_vector(unsigned(address)+1);  
				end if;
				
				if pop = '1' and empty = '0' then 				 
					address <= std_logic_vector(unsigned(address)-1);
					--data_out <= output ;	
			
					
				end if;	 
			end if;
		end if;	
		
		
	end process; 
	
	
	
	
	
	
end Stack;