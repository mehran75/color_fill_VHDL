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
			LEDR				: out std_logic_vector(9 downto 0);
			
			HEX0				: out std_logic_vector(6 downto 0);
			HEX1				: out std_logic_vector(6 downto 0);
			HEX2				: out std_logic_vector(6 downto 0);
			HEX3				: out std_logic_vector(6 downto 0);
			HEX4				: out std_logic_vector(6 downto 0);
			HEX5				: out std_logic_vector(6 downto 0)
			);


end color_fill;


architecture Behavioral of color_fill is

	function convSEG (N : std_logic_vector(3 downto 0)) return std_logic_vector is
			variable ans:std_logic_vector(6 downto 0);
	begin
		Case N is
			when "0000" => ans:="1000000";	 
			when "0001" => ans:="1111001";
			when "0010" => ans:="0100100";
			when "0011" => ans:="0110000";
			when "0100" => ans:="0011001";
			when "0101" => ans:="0010010";
			when "0110" => ans:="0000010";
			when "0111" => ans:="1111000";
			when "1000" => ans:="0000000";
			when "1001" => ans:="0010000";	   
			when "1010" => ans:="0001000";
			when "1011" => ans:="0000011";
			when "1100" => ans:="1000110";
			when "1101" => ans:="0100001";
			when "1110" => ans:="0000110";
			when "1111" => ans:="0001110";				
			when others=> ans:="1111111";
		end case;	
		return ans;
	end function convSEG;
	
	-- Square class
	-- type square is 
	--	record
	--		color : std_logic_vector(1 downto 0);
			-- if is_obstacle = '1' then should not be used --
	--		is_obstacle : std_logic;
	--	end record;
		
		
	-- FSM --
	type dfs_state is (idle_state, push_origin, pop_state, check_right, check_bottom, check_left, check_top, check_stack);
	
	-- Matrix of squares
	type row_square is array (0 to squares_size -1) of std_LOGIC_VECTOR(1 downto 0);
	type matrix_square is array (0 to squares_size -1) of row_square;
	
	type row_sc is array (0 to squares_size-1) of std_LOGIC_VECTOR(1 downto 0);
	type color_ca is array (0 to squares_size-1) of row_sc;

	
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
	--constant orange : std_logic_vector(11 downto 0) := X"000"; -- 00
	--constant Teal : std_logic_vector(11 downto 0) := X"00F";		-- 01
	--constant Olive : std_logic_vector(11 downto 0) := X"F00";	-- 10
	--constant Maroon : std_logic_vector(11 downto 0) := X"0F0";  -- 11
	
	-- Matrix and other stuff
	signal selected_color : std_logic_vector(1 downto 0) := "00";
	signal origin_color : std_logic_vector(1 downto 0) := "00" ;
	signal i, j : integer := 0;
	signal change_zero_zero_flag : std_LOGIC := '0';
	
	signal algo_current_state : dfs_state := idle_state;
	signal algo_next_state	  : dfs_state := idle_state;
	signal algo_last_state	  : dfs_state := idle_state;

	
	signal matrix : matrix_square := ((others=> (others=>(others=>'Z'))));
	signal color_matrix : matrix_square:= ((others=> (others=>(others=>'Z'))));
	
	constant win_1 : matrix_square := ((others=> (others=>"00")));
	constant win_2 : matrix_square := ((others=> (others=>"01")));
	constant win_3 : matrix_square := ((others=> (others=>"10")));
	constant win_4 : matrix_square := ((others=> (others=>"11")));
	
	-- temp signal for colorOut  
	signal out_color_temp : std_logic_vector(11 downto 0);
	
	-- Random color picker
	signal row_counter, column_counter : integer range 0 to squares_size := 0;
	signal stop_counter : std_LOGIC := '0';
	
	signal current_lfsr : std_logic_vector((2*squares_size) -1 downto 0) := (others=>'1');
	-- signal counter    : std_LOGIC_VECTOR(11 downto 0) := (others=>'0');
	
	
	
	signal flag_end_game : std_logic := '0';
	signal Counter, counter_2, counter_1, key_delay : integer := 0;	
	signal timer_stop : std_logic := '1';
	signal timer_99 : std_logic := '0';
	
	
	signal score1, score2 : integer  := 0;
	signal last_key : std_LOGIC_VECTOR(3 downto 0) := "1111";
	signal flag_change_score : std_LOGIC := '1';
	
	-- Architecture begin
	begin
	
	assign_color_row : for index_i in 0 to (squares_size-1) generate
		assign_color_col : for index_j in 0 to (squares_size-1) generate
			process(CLK_50MHz, RESET)
				begin
					if RESET = '1' then 
						matrix(index_i)(index_j) <= "00";
					elsif rising_edge(CLK_50MHz) then 
						matrix(index_i)(index_j) <= color_matrix(index_i)(index_j);
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
			 reset 		 => stack_reset,
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
			show_matrix_row: for i_index in 0 to squares_size-1 loop
				show_matrix_col: for j_index in 0 to squares_size-1 loop
										if scanlineX < s_width*i_index + margin_sides and scanlineX > s_width*i_index - s_width + margin_sides then
											if scanlineY < s_height*j_index + margin_up and scanlineY > s_height*j_index - s_height + margin_up then
												case (matrix(j_index)(i_index)) is 
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
		
		
		process(matrix, timer_99, RESET)
		begin
		
				flag_end_game <= '0';
					
				if stop_counter = '1' and (matrix = win_1 or matrix = win_2 or matrix = win_3 or matrix = win_4 or timer_99 = '1') then
					flag_end_game <= '1';
				end if;
		
		end process;
		
		
		process(CLK_50MHz, RESET)
		begin
			if reset = '1' then
				stop_counter <= '0';
				row_counter <= 0;
				column_counter <= 0;
			elsif rising_edge(CLK_50MHz) then
				if stop_counter = '0' then
					column_counter <= column_counter + 1;
					if column_counter = squares_size -1 then
						row_counter <= row_counter + 1;
						column_counter <= 0;
					end if;
					if row_counter = squares_size -1 and column_counter = squares_size - 1 then
						row_counter <= 0;
						column_counter <= 0;
						stop_counter <= '1';
					end if;
				end if;
			end if;
		end process;
		
		
		process(row_counter, column_counter, stop_counter, i, j, change_zero_zero_flag, selected_color)
		begin	
		
				color_matrix <= matrix;
			if stop_counter = '0' then	  
				
				if column_counter = 0 then
					current_lfsr <= LFSR_IN((2*squares_size)-1 downto 0);
					color_matrix(row_counter)(column_counter) <= LFSR_IN(1 downto 0);--current_lfsr(column_counter+1 downto column_counter);
				else
					color_matrix(column_counter)(row_counter)  <= current_lfsr(column_counter downto column_counter-1);
				end if;
		
			elsif i = 0 and j = 0 then 
				if  change_zero_zero_flag = '1' then
					color_matrix(i)(j) <= selected_color;
				end if;
   		else
				color_matrix(i)(j) <= selected_color;
			end if;
		
		end process;
		
	
		
		-- fsm
		process(algo_current_state, key, stack_out, flag_end_game, i,j,stack_empty, RESET , selected_color)
		begin 
			
			
			stack_in <= (others=>'Z');
			change_zero_zero_flag <= '0';
			stack_reset <= '0';

			if flag_end_game = '1' then
				LEDR(9 downto 0) <= (others=>'1');
				algo_next_state <= idle_state;
				timer_stop <= '1';
			else				  
				LEDR(9 downto 0) <= (others=>'0');			
				
				case algo_current_state is
					when idle_state => 	i <= 0;
												j <= 0;
												stack_enable <= '0';
												stack_push <= '0';
												stack_pop <= '0';
												stack_reset <= '1';
												algo_next_state <= idle_state;
												origin_color <= color_matrix(0)(0);
												
												if key(3) = '0' then
													selected_color <= "00";
													algo_next_state <= push_origin;
													timer_stop <= '0';
												elsif key(2) = '0' then
													selected_color <= "01";
													algo_next_state <= push_origin;
													timer_stop <= '0';
												elsif key(1) = '0'  then
													selected_color <= "10";
													algo_next_state <= push_origin;
													timer_stop <= '0';
												elsif key(0) = '0' then
													selected_color <= "11";
													algo_next_state <= push_origin;
													timer_stop <= '0';
												else 
													algo_next_state <= idle_state;
												end if;
												

					when push_origin => 	flag_change_score <= '1';
												stack_reset <= '0';
												stack_enable <= '1';
												stack_push <= '1';
												stack_pop <= '0';
												stack_in <= X"00";	-- Origin Position
												algo_next_state <= pop_state;
					
					when pop_state => 
										if selected_color = origin_color then
												algo_next_state <= idle_state;	-- If user choose same color button, then nothings to change
												stack_enable <= '1';
												stack_push <= '0' ; 	-- Pop origin from stack 
												stack_pop <= '1';
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
					when check_right => 
											stack_enable <= '0';
											stack_push <= '0';
											stack_pop <= '0';
											change_zero_zero_flag <= '0';
												
											if j < (squares_size-1) and color_matrix(i)(j+1) = origin_color then
												stack_enable <= '1';
												stack_push <= '1';
												stack_pop <= '0' ;
												stack_in(7 downto 0) <= std_logic_vector(to_unsigned(i, 4)) & std_logic_vector(to_unsigned(j+1, 4));
											end if;
												algo_next_state <= check_bottom;
												
					when check_bottom => 	
											stack_enable <= '0';
											stack_push <= '0';
											stack_pop <= '0';
												
											if i < (squares_size-1) and color_matrix(i+1)(j)= origin_color then
												stack_enable <= '1';
												stack_push <= '1';
												stack_pop <= '0' ;
												stack_in(7 downto 0) <= std_logic_vector(to_unsigned(i+1, 4)) & std_logic_vector(to_unsigned(j, 4));
											end if;
										
												algo_next_state <= check_left;
					when check_left => 
											stack_enable <= '0';
											stack_push <= '0';
											stack_pop <= '0';
												
												if j > 0 and color_matrix(i)(j-1) = origin_color then
													stack_enable <= '1';
													stack_push <= '1';
													stack_pop <= '0' ;
													stack_in(7 downto 0) <= std_logic_vector(to_unsigned(i, 4)) & std_logic_vector(to_unsigned(j-1, 4));
												end if;
												
												algo_next_state <= check_top;
					when check_top => 		
											stack_enable <= '0';
											stack_push <= '0';
											stack_pop <= '0';
											if i > 0 and color_matrix(i-1)(j) = origin_color then
												stack_enable <= '1';
												stack_push <= '1';
												stack_pop <= '0' ;
												stack_in(7 downto 0) <= std_logic_vector(to_unsigned(i-1, 4)) & std_logic_vector(to_unsigned(j, 4));
											end if;
												algo_next_state <= check_stack;
					when check_stack => 	
											stack_enable <= '0';
											stack_push <= '0';
											stack_pop <= '0';
											
											if stack_empty = '0' then
												algo_next_state <= pop_state;
											else
												algo_next_state <= idle_state;
												if flag_change_score = '1' then
													flag_change_score <= '0';
													score1 <= score1 +1;
													if score1 = 9 then
														score2 <= score2 +1;
														score1 <= 0;
													end if;
													
													if score2 = 10 then 
														score2 <= 0;
														score1 <= 0;
													end if;
												end if;
												
											end if;
					when others => null;
				end case;
			end if;			


			if RESET ='1' then
				score1 <= 0;
				score2 <= 0;
			end if;
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
		
		
		
	
		--------- 7Segment Show ------------
	 Process(CLK_50MHz, RESET)
	 begin
		if (RESET ='1') then
			Counter <= 0;
			counter_1 <= 0;
			counter_2 <= 0;
			timer_99 <= '0';
		elsif (rising_edge(CLK_50MHz)) then
			if timer_stop = '0' then
				
				if counter > 381 then
					counter <= 0;
					counter_1 <= counter_1 + 1;
					
					if counter_1 = 9 then
						counter_1 <= 0;
						counter_2 <= counter_2 + 1;
					end if;
					
					if counter_2 = 9 then
						counter_2 <= 0;
						timer_99 <= '1';
					end if;
					
				else
					counter <= counter + 1;				
				end if;
			end if;
			
			
		end if;
	 end process;
	 
	 Process (counter_1, counter_2)
	 begin
		HEX4 <= ConvSEG(std_logic_vector(to_unsigned(counter_1,4)));
		HEX5 <= ConvSEG(std_logic_vector(to_unsigned(counter_2,4)));		
	 end process;
	 
	
	process(score1, score2, timer_stop)
		begin
			if timer_stop = '1' then
	
				-- Mehran --
				HEX0 <= convSEG("0101");
				HEX1 <= convSEG("0010");
				-- Parsa --
				HEX2 <= convSEG("0110");
				HEX3 <= convSEG("0000");
			else
				HEX0 <= convSEG(std_logic_vector(to_unsigned(score1,4)));
				HEX1 <= convSEG(std_logic_vector(to_unsigned(score2,4)));
				HEX2 <= "1111111";
				HEX3 <= "1111111";
			end if;
		end process;
		
--	LEDR(1 downto 0) <= matrix(0)(2);
--	LEDR(3 downto 2) <= matrix(1)(2);
--	LEDR(5 downto 4) <= matrix(2)(2);
--	LEDR(7 downto 6) <= matrix(3)(2);
--	LEDR(9 downto 8) <= matrix(4)(0);
		
end Behavioral;