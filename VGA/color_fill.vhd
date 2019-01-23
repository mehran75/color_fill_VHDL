library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;


entity color_fill is 

	generic (squares_size : integer := 10);

	port (CLK_50MHz		: in std_logic;
			RESET				: in std_logic;
			ColorOut			: out std_logic_vector(11 downto 0); -- RED & GREEN & BLUE
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0);
			LFSR_IN			: in std_logic_vector(63 downto 0);
			Key				: in std_logic_vector(3 downto 0);
			Switch 			: in std_logic_vector(9 downto 0);
			LEDR				: out std_logic_vector(9 downto 0)
			);


end color_fill;


architecture Behavioral of color_fill is

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
	type game_state is (idel ,ready, playing , AI, finished);
	type dfs_state is (idle_state, origin_state, pop_state, top_state, right_state, bottom_state, left_state);
	
	-- Matrix of squares
	type row_square is array (squares_size -1 downto 0) of square;
	type matrix_square is array (squares_size -1 downto 0) of row_square;
	

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
	signal stack_push, stack_pop	 : std_LOGIC;
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
	
	-- Matrix and other stuff
	signal selected_color : std_logic_vector(1 downto 0);
	signal origin_color : std_logic_vector(1 downto 0);
	signal popped_vector : std_LOGIC_VECTOR(data_size-1 downto 0);
	signal i, j : integer := 0;
	
	signal algo_current_state : dfs_state := idle_state;
	signal algo_next_state : dfs_state := idle_state;
	
	signal matrix : matrix_square;
	
	-- temp signal for colorOut  
	signal out_color_temp : std_logic_vector(11 downto 0);
	
	-- Random color picker
	signal row_counter, column_counter : integer range squares_size downto 0 := 0;
	signal stop_counter : std_LOGIC := '0';
	
	signal current_lfsr : std_logic_vector((2*squares_size) -1 downto 0) := (others=>'1');
	-- signal counter    : std_LOGIC_VECTOR(11 downto 0) := (others=>'0');
	
	
	-- push in stack
	procedure push_in_stack(i : in integer; j: in integer) is
	begin
	
		stack_push	<= '1';
		stack_pop <= '0';
		stack_enable <= '1';
		stack_in <= std_logic_vector(to_unsigned(i, 4)) & std_logic_vector(to_unsigned(j, 4));
	
	end push_in_stack;
	
	impure function pop_from_stack return std_logic_vector is
	begin
		stack_push <= '0';
		stack_pop <= '1';
		stack_enable <= '1';
		
		return stack_out;
	
	end pop_from_stack;
	
	
	
	
	-- Architecture begin
	begin
	
		
		-- display key options
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
		
		
		

		
		
		
		-- Mehran fucking random selector
		process(CLK_50MHz, RESET)
		begin
			if reset = '1' then
				stop_counter <= '0';
				row_counter <= 0;
				column_counter <= 0;
			elsif rising_edge(CLK_50MHz) then
				if stop_counter = '0' then
					column_counter <= column_counter + 1;
					if column_counter = squares_size then
						row_counter <= row_counter + 1;
						column_counter <= 0;
					end if;
					if row_counter = squares_size then
						row_counter <= 0;
						stop_counter <= '1';
					end if;
				end if;
			end if;
		end process;
		
		
		-- Initilize pixels
		process(column_counter, row_counter, clk_50MHz, stop_counter, algo_current_state)
		begin
			if stop_counter = '0' then -- initilize game with random colors
				current_lfsr <= current_lfsr;
				
				matrix(row_counter)(column_counter).square_width <= s_width;
				matrix(row_counter)(column_counter).square_height <= s_height;
				matrix(row_counter)(column_counter).is_obstacle <= '0';
				
				if rising_edge(clk_50MHz) then
					if column_counter = 0 then
						current_lfsr <= LFSR_IN((2*squares_size)-1 downto 0);
						matrix(row_counter)(column_counter).color <= LFSR_IN(1 downto 0);--current_lfsr(column_counter+1 downto column_counter);
					else
						matrix(row_counter)(column_counter).color <= current_lfsr(column_counter downto column_counter-1);
					end if;
				end if;
			else								-- do the game
				case algo_current_state is
					when origin_state => matrix(0)(0).color <= selected_color;
												-- Right
												if matrix(0)(1).color = origin_color then
													push_in_stack(0, 1);
												end if;
												-- Bottom
												--if matrix(1)(0).color = origin_color then
													--push_in_stack(1, 0);
												--end if;
					when pop_state => popped_vector <= pop_from_stack;
											i <= conv_integer(popped_vector(7 downto 4));
											j <= conv_integer(popped_vector(3 downto 0));
											
											
					when top_state => matrix(i)(j).color <= selected_color;
											if not (i = 0) then 
												if matrix(i-1)(j).color = origin_color then
													push_in_stack(i-1,j);
												end if;
											end if;
											
					when right_state => if not (j = squares_size -1) then 
												if matrix(i)(j+1).color = origin_color then
													push_in_stack(i,j+1);
												end if;
											end if;
											
					when bottom_state => if not (i = squares_size -1) then 
												if matrix(i+1)(j).color = origin_color then
													push_in_stack(i+1,j);
												end if;
											end if;
											
					when left_state => if not (j = 0) then 
												if matrix(i)(j-1).color = origin_color then
													push_in_stack(i,j-1);
												end if;
											end if;
					when others => null;								
				end case;
			end if;
			
			
		end process;
		

		
		-- FSM after push key
		process(key, algo_current_state) 
		begin
			-- LED Display
			LEDR(3 downto 0) <= not key;
			
			-- Default Value
			algo_next_state <= algo_next_state;
			selected_color <= selected_color; 
			case algo_current_state is
			
					-- Check that a key is pushed
					when idle_state => 
											origin_color <= matrix(0)(0).color;
											if key(3) = '0' then
												selected_color <= "00";
												algo_next_state <= origin_state;
											end if;
											if key(2) = '0' then
												selected_color <= "01";
												algo_next_state <= origin_state;
											end if;
											if key(1) = '0' then
												selected_color <= "10";
												algo_next_state <= origin_state;
											end if;
											if key(0) = '0' then
												selected_color <= "11";
												algo_next_state <= origin_state;
											end if;
					-- Check origin (0,0)
					when origin_state => if stack_empty = '0' then algo_next_state <= pop_state;
													else algo_next_state <= idle_state;
												end if;
					-- Pop from stack (if it's not empty)
					when pop_state => if stack_empty = '1' then algo_next_state <= idle_state;
												else algo_next_state <= top_state;
											end if;
					-- Check neighbors pixel
					when top_state => algo_next_state <= right_state;
					when right_state => algo_next_state <= bottom_state;
					when bottom_state => algo_next_state <= left_state;
					when left_state => algo_next_state <= pop_state;
					
					when others => algo_next_state <= algo_next_state;
			end case;
				
		end process;
		
		
		
		-- update algo_next_state
		process (clk_50MHz, reset)
		begin
			if reset = '1' then 
				algo_current_state <= idle_state;
			elsif falling_edge(clk_50MHz) then
				algo_current_state <= algo_next_state;
			end if;
		end process;
		
		
		-- update matrix 

		
		ColorOut <= out_color_temp;	-- Display
		
		
		
end Behavioral;