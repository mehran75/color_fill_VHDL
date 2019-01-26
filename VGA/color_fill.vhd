library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;


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
			color : std_logic_vector(1 downto 0);
			-- if is_obstacle = '1' then should not be used --
			is_obstacle : std_logic;
		end record;
		
		
	-- FSM --
	type dfs_state is (idle_state, push_origin, pop_state, check_right, check_bottom, check_left, check_top, check_stack);
	
	-- Matrix of squares
	type row_square is array (squares_size -1 downto 0) of square;
	type matrix_square is array (squares_size -1 downto 0) of row_square;
	
	type row_sc is array (squares_size-1 downto 0) of std_LOGIC_VECTOR(1 downto 0);
	type color_ca is array (squares_size-1 downto 0) of row_sc;

	
	-- Stack component --
	constant data_size : integer := 8;
	
	component Stack
		port(
		push		    : in STD_LOGIC;
		POP		    : in STD_LOGIC;
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
	signal stack_push,stack_pop					 : std_LOGIC := '0';
	signal stack_enable 			 	 : std_LOGIC := '0';
	signal stack_reset			    : std_LOGIC := '0';
	signal stack_full, stack_empty : std_LOGIC := '0';

	
	-- Size parameters
	constant s_width		 : integer := 45;
	constant s_height		 : integer := 40;
	constant center		 : integer := 320;
	constant margin_sides : integer := 130;
	constant margin_up    : integer := 40;
	
	-- Colors pallete
	constant orange : std_logic_vector(11 downto 0) := X"E72"; -- 00
	constant Teal : std_logic_vector(11 downto 0) := X"088";		-- 01
	constant Olive : std_logic_vector(11 downto 0) := X"880";	-- 10
	constant Maroon : std_logic_vector(11 downto 0) := X"800";  -- 11
	
	-- Matrix and other stuff
	signal selected_color : std_logic_vector(1 downto 0) := "00";
	signal origin_color : std_logic_vector(1 downto 0) := "00" ;
	signal i, j : integer := 0;
	signal change_zero_zero_flag : std_LOGIC := '0';
	
	signal algo_current_state : dfs_state := idle_state;
	signal algo_next_state	  : dfs_state := idle_state;
	signal algo_last_state	  : dfs_state := idle_state;

	
	signal matrix : matrix_square;
	signal color_matrix : color_ca;
	
	-- temp signal for colorOut  
	signal out_color_temp : std_logic_vector(11 downto 0);
	
	-- Random color picker
	signal row_counter, column_counter : integer range squares_size downto 0 := 0;
	signal stop_counter : std_LOGIC := '0';
	
	signal current_lfsr : std_logic_vector((2*squares_size) -1 downto 0) := (others=>'1');
	-- signal counter    : std_LOGIC_VECTOR(11 downto 0) := (others=>'0');
	
	

	-- Architecture begin
	begin
	
	assign_color_row : for i in 0 to (squares_size-1) generate
		assign_color_col : for j in 0 to (squares_size-1) generate
			process(CLK_50MHz, RESET)
				begin
					if RESET = '1' then 
						matrix(i)(j).color <= "00";
					elsif rising_edge(CLK_50MHz) then 
						matrix(i)(j).color <= color_matrix(i)(j);
					end if;
			end process;
		end generate assign_color_col;
	end generate assign_color_row;
	
	STACK_CO : Stack
		port map(
			 push		    => stack_push,
			 pop	=> stack_pop,
			 en 		 	 => stack_enable,
			 data_in 	 => stack_in,
			 data_out	 => stack_out,
			 clk 		 	 => clk_50MHz,							  
			 reset 		 => RESET,
			 STACK_FULL  => stack_full,						
			 STACK_EMPTY => stack_empty
		);
	
		
		-- display key options
		process(scanlineX, scanlineY, matrix)
		begin
			out_color_temp <= X"FFF";	-- Background color
			if scanlineY > 400+s_height then
				if scanlineX < center - 2*s_width then
					out_color_temp <= X"FFF";	-- Background color
				elsif scanlineX < center - s_width+1 then
					out_color_temp <= orange;	-- orange
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
										if scanlineX < s_width*i + margin_sides and scanlineX > s_width*i - s_width + margin_sides then
											if scanlineY < s_height*j + margin_up and scanlineY > s_height*j - s_height + margin_up then
												case (matrix(i)(j).color) is 
													when "00" => out_color_temp <= orange;
													when "01" => out_color_temp <= Teal;
													when "10" => out_color_temp <= Olive;
													when "11" => out_color_temp <= Maroon;
													when others => null;
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
		
		
		process(row_counter, column_counter, stop_counter, i, j, change_zero_zero_flag, selected_color, current_lfsr, LFSR_IN)
		begin	
			if stop_counter = '0' then
				if column_counter = 0 then
					current_lfsr <= LFSR_IN((2*squares_size)-1 downto 0);
					color_matrix(column_counter)(row_counter)  <= LFSR_IN(1 downto 0); 
					--change_matrix_color(RESET, CLK_50MHz ,row_counter, column_counter, );
					--matrix(row_counter)(column_counter).color := LFSR_IN(1 downto 0);
					--current_lfsr(column_counter+1 downto column_counter);
				else
					color_matrix(column_counter)(row_counter)  <= current_lfsr(column_counter downto column_counter-1);
					--change_matrix_color(RESET, CLK_50MHz ,row_counter, column_counter, current_lfsr(column_counter downto column_counter-1));
					--matrix(row_counter)(column_counter).color := current_lfsr(column_counter downto column_counter-1);
				end if;
			elsif i = 0 and j = 0 then 
				if change_zero_zero_flag = '1' then
					color_matrix(j)(j) <= selected_color;
				end if;
   		else
				color_matrix(i)(j) <= selected_color;
			end if;
		
		end process;
		
		
		process(algo_current_state)
		begin
			
			case algo_current_state is
					when idle_state => LEDR(9 downto 2) <= X"FF";
					when push_origin => LEDR(9 downto 2) <= X"01";
					when pop_state => LEDR(9 downto 2) <= X"02";
					when check_right => LEDR(9 downto 2) <= X"03";
					when check_bottom => LEDR(9 downto 2) <= X"04"; 					
					when check_left => LEDR(9 downto 2) <= X"05";
					when check_top => LEDR(9 downto 2) <= X"06";
					when check_stack => LEDR(9 downto 2) <= X"07";
					when others => null;
			end case;
			
		end process;

		-- fsm
		process(algo_current_state, key, stack_out)
		begin
		case algo_current_state is
			when idle_state => 	if key(3) = '0' then
									selected_color <= "00";
									algo_next_state <= push_origin;
								elsif key(2) = '0' then
									selected_color <= "01";
									algo_next_state <= push_origin;
								elsif key(1) = '0' then
									selected_color <= "10";
									algo_next_state <= push_origin;
								elsif key(0) = '0' then
									selected_color <= "11";
									algo_next_state <= push_origin;
								else 
									algo_next_state <= idle_state;
								end if;
			when push_origin => 	origin_color <= matrix(0)(0).color;
										stack_enable <= '1';
										stack_push <= '1';
										stack_in <= X"00";	-- Origin Position
										algo_next_state <= pop_state;
			
			when pop_state => if selected_color = origin_color then
									algo_next_state <= idle_state;	-- If user choose same color button, then nothings to change
									stack_enable <= '1';
									stack_push <= '0' ; 	-- Pop origin from stack 
									stack_pop <= '0';
									change_zero_zero_flag <= '0';
									else
										stack_enable <= '1';
										stack_push <= '0' ; 	-- Pop from stack
										stack_pop <= '1' ;
										algo_next_state <= check_right;
										-- Index of last item in stack
										i <= to_integer(unsigned(stack_out(7 downto 4)));
										j <= to_integer(unsigned(stack_out(3 downto 0)));
										change_zero_zero_flag <= '1';
									end if;
			when check_right => 	stack_enable <= '0';
										change_zero_zero_flag <= '0';
										if j < (squares_size-1) then
											if matrix(i)(j+1).color = origin_color then
												stack_enable <= '1';
												stack_push <= '1';
												stack_pop <= '0' ;
												stack_in <= std_logic_vector(to_unsigned(i, 4)) & std_logic_vector(to_unsigned(j+1, 4));
											end if;
										end if;
										algo_next_state <= check_bottom;
			when check_bottom => stack_enable <= '0';
										if i < (squares_size-1) then
											if matrix(i+1)(j).color = origin_color then
												stack_enable <= '1';
												stack_push <= '1';
												stack_pop <= '0' ;
												stack_in <= std_logic_vector(to_unsigned(i+1, 4)) & std_logic_vector(to_unsigned(j, 4));
											end if;
										end if;
										algo_next_state <= check_left;
			when check_left => 	stack_enable <= '0';
										if j > 0 then
											if matrix(i)(j-1).color = origin_color then
												stack_enable <= '1';
												stack_push <= '1';
												stack_pop <= '0' ;
												stack_in <= std_logic_vector(to_unsigned(i, 4)) & std_logic_vector(to_unsigned(j-1, 4));
											end if;
										end if;
										algo_next_state <= check_top;
			when check_top => 	stack_enable <= '0';
										if i > 0 then
											if matrix(i-1)(j).color = origin_color then
												stack_enable <= '1';
												stack_push <= '1';
												stack_pop <= '0' ;
												stack_in <= std_logic_vector(to_unsigned(i-1, 4)) & std_logic_vector(to_unsigned(j, 4));
											end if;
										end if;
										algo_next_state <= check_stack;
			when check_stack => 		stack_enable <= '0';
										if stack_empty = '0' then
											algo_next_state <= pop_state;
										else
											algo_next_state <= idle_state;
										end if;
			when others => null;
		end case;								
		end process;
		
		
		
		
		
		-- update algo_next_state
		process (clk_50MHz, RESET)
		begin
			if reset = '1' then 
				algo_current_state <= idle_state;
			elsif rising_edge(clk_50MHz) then
				algo_current_state <= algo_next_state;
			end if;
		end process;
		
		
		-- update matrix 

		
		ColorOut <= out_color_temp;	-- Display
		
		
		
end Behavioral;