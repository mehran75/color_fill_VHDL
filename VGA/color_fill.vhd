library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;


entity color_fill is 

	generic (squares_size : integer := 10);

	port (CLK_50MHz		: in std_logic;
			RESET				: in std_logic;
			ColorOut			: out std_logic_vector(11 downto 0); -- RED & GREEN & BLUE
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0);
			LFSR_IN			: in std_logic_vector(31 downto 0);
			Key				: in std_logic_vector(3 downto 0);
			Switch 			: in std_logic_vector(9 downto 0);
			LEDR				: out std_logic_vector(9 downto 0)
			);


end color_fill;


architecture Behavioral of color_fill is

	-- Stack component --
	constant data_size : integer := 8;
	component Stack
		port(
			push		    : in STD_LOGIC;
			 pop 		 	 : in STD_LOGIC;
			 en 		 	 : in STD_LOGIC;
			 data_in 	 : in STD_LOGIC_VECTOR(data_size-1 downto 0);
			 data_out	 : out STD_LOGIC_VECTOR(data_size-1 downto 0);
			 clk 		 	 : in STD_logic;							  
			 reset 		 : in STD_logic;
			 STACK_FULL  : out STD_LOGIC;						
			 STACK_EMPTY : out STD_LOGIC
		);
		
	end component;
	
	signal stack_in, stack_out 	 : std_LOGIC_VECTOR(data_size-1 downto 0);
	signal stack_push,stack_pop	 : std_LOGIC;
	signal stack_enable 			 	 : std_LOGIC;
	signal stack_reset			    : std_LOGIC;
	signal stack_full, stack_empty : std_LOGIC;

	
	-- Size parameters
	constant s_width		 : integer := 45;
	constant s_height		 : integer := 40;
	constant center		 : integer := 320;
	constant margin_sides : integer := 130;
	constant margin_up    : integer := 40;
	
	-- Colors pallete
	constant Fuchsia : std_logic_vector(11 downto 0) := X"F0F"; -- 00
	constant Teal : std_logic_vector(11 downto 0) := X"088";		-- 01
	constant Olive : std_logic_vector(11 downto 0) := X"880";	-- 10
	constant Maroon : std_logic_vector(11 downto 0) := X"800";  -- 11
	
	-- Square class
	type square is 
		record
			square_width : integer;
			square_height : integer;
			color : std_logic_vector(1 downto 0);
			-- if is_obstacle = '1' then should not be used --
			is_obstacle : std_logic;
		end record;
		
		
	-- FSM --
	type state is (idel ,ready, playing , AI, finished);
	
	-- Matrix of squares
	type row_square is array (squares_size -1 downto 0) of square;
	type matrix_square is array (squares_size -1 downto 0) of row_square;
	
	signal matrix : matrix_square;
	
	-- temp signal for colorOut  
	signal out_color_temp : std_logic_vector(11 downto 0);
	
	-- Random color picker
	signal row_counter, column_counter : integer range squares_size downto 0 := 0;
	signal stop_counter : std_LOGIC := '0';
	
	signal current_lfsr : std_logic_vector((2*squares_size) -1 downto 0) := (others=>'1');
	-- signal counter    : std_LOGIC_VECTOR(11 downto 0) := (others=>'0');
	
	
begin
	
	
	-- Key menu
	process(scanlineX, scanlineY, matrix)
	begin
		out_color_temp <= X"FFF";	-- Background color
		if scanlineY > 400+s_height then
			if scanlineX < center - 2*s_width then
				out_color_temp <= X"FFF";	-- Background color
			elsif scanlineX < center - s_width+1 then
				out_color_temp <= Fuchsia;	-- Fuchsia
			elsif scanlineX < center then
				out_color_temp <= Teal;	-- Teal
			elsif scanlineX < center + s_width-1 then
				out_color_temp <= Olive;	-- Olive
			elsif scanlineX < center + 2*s_width then
				out_color_temp <= Maroon;	-- Maroon
			end if;
		end if;
		
		-- Display squares
		show_matrix_row: for i in 0 to squares_size-1 loop
			show_matrix_col: for j in 0 to squares_size-1 loop
									if scanlineX < matrix(i)(j).square_width*i + margin_sides and scanlineX > matrix(i)(j).square_width*i - matrix(i)(j).square_width + margin_sides then
										if scanlineY < matrix(i)(j).square_height*j + margin_up and scanlineY > matrix(i)(j).square_height*j - matrix(i)(j).square_height + margin_up then
											case (matrix(i)(j).color) is 
												
												when "00" => out_color_temp <= Fuchsia;
												when "01" => out_color_temp <= Teal;
												when "10" => out_color_temp <= Olive;
												when "11" => out_color_temp <= Maroon;
			
											end case;
										end if;
									end if;
			end loop show_matrix_col;
		end loop show_matrix_row;
	
	end process;
	
	
	

	
	-- Mehran fucking random generator
	process(CLK_50MHz, key, RESET)
	begin
		
		
		if key(0) = '0' then
			stop_counter <= '0';
			row_counter <= 0;
			column_counter <= 0;
		elsif rising_edge(CLK_50MHz) then
			if stop_counter = '0' then
				column_counter <= column_counter + 1;
				if column_counter = squares_size - 1 then
					row_counter <= row_counter + 1;
					column_counter <= 0;
				end if;
				if row_counter = squares_size -1 then
					row_counter <= 0;
					stop_counter <= '1';
				end if;
			end if;
		end if;
	end process;
	
	
	process(key) 
	begin
		
		LEDR(3 downto 0) <= not key;
	
		--if (current_state = idel) then
		--	if key(0) = '0' then
			--	stop_counter <= '1';
		--	end if;
		--elsif current_state = ready then
			-- state game
		--	next_state <= playing;
		--elsif current_state = playing then
			-- handle game button
		--elsif current_state = finished then
			-- show result
		--end if;
	
	end process;
	
	
	
	
	-- randomly initialize colors
	process(column_counter, row_counter)
	begin
	
		current_lfsr <= current_lfsr;
		
		matrix(row_counter)(column_counter).square_width <= s_width;
		matrix(row_counter)(column_counter).square_height <= s_height;
		matrix(row_counter)(column_counter).is_obstacle <= '0';
		
		if column_counter = 0 then
			current_lfsr <= LFSR_IN((2*squares_size)-1 downto 0);
			matrix(row_counter)(column_counter).color <= LFSR_IN(1 downto 0);--current_lfsr(column_counter+1 downto column_counter);
		else
			matrix(row_counter)(column_counter).color <=current_lfsr(column_counter downto column_counter-1);
		end if;
		
	end process;
	
	
	ColorOut <= out_color_temp;	-- Display
	
end Behavioral;