----------------------------------------------------------------------------------
-- Moving Square Demonstration 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity VGA_Square is
  port ( CLK_50MHz		: in std_logic;
			RESET				: in std_logic;
			ColorOut			: out std_logic_vector(11 downto 0); -- RED & GREEN & BLUE
			SQUAREWIDTH		: in std_logic_vector(7 downto 0);
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0)
  );
end VGA_Square;

architecture Behavioral of VGA_Square is
  
  signal ColorOutput: std_logic_vector(11 downto 0);
  
  signal SquareX: std_logic_vector(9 downto 0) := "0000001110";  
  signal SquareY: std_logic_vector(9 downto 0) := "0000010111";  
  signal SquareXMoveDir, SquareYMoveDir: std_logic := '0';
  --constant SquareWidth: std_logic_vector(4 downto 0) := "11001";
  constant SquareXmin: std_logic_vector(9 downto 0) := "0000000001";
  signal SquareXmax: std_logic_vector(9 downto 0); -- := "1010000000"-SquareWidth;
  constant SquareYmin: std_logic_vector(9 downto 0) := "0000000001";
  signal SquareYmax: std_logic_vector(9 downto 0); -- := "0111100000"-SquareWidth;
  signal ColorSelect: std_logic_vector(2 downto 0) := "001";
  signal Prescaler: std_logic_vector(30 downto 0) := (others => '0');

begin

	PrescalerCounter: process(CLK_50Mhz, RESET)
	begin
		if RESET = '1' then
			Prescaler <= (others => '0');
			SquareX <= "0111000101";
			SquareY <= "0001100010";
			SquareXMoveDir <= '0';
			SquareYMoveDir <= '0';
			ColorSelect <= "001";
		elsif rising_edge(CLK_50Mhz) then
			Prescaler <= Prescaler + 1;	 
			if Prescaler = "11000011010100000" then  -- Activated every 0,002 sec (2 msec)
				if SquareXMoveDir = '0' then
					if SquareX < SquareXmax then
						SquareX <= SquareX + 1;
					else
						SquareXMoveDir <= '1';
						ColorSelect <= ColorSelect(1 downto 0) & ColorSelect(2);
					end if;
				else
					if SquareX > SquareXmin then
						SquareX <= SquareX - 1;
					else
						SquareXMoveDir <= '0';
						ColorSelect <= ColorSelect(1 downto 0) & ColorSelect(2);
					end if;	 
				end if;
		  
				if SquareYMoveDir = '0' then
					if SquareY < SquareYmax then
						SquareY <= SquareY + 1;
					else
						SquareYMoveDir <= '1';
						ColorSelect <= ColorSelect(1 downto 0) & ColorSelect(2);
					end if;
				else
					if SquareY > SquareYmin then
						SquareY <= SquareY - 1;
					else
						SquareYMoveDir <= '0';
						ColorSelect <= ColorSelect(1 downto 0) & ColorSelect(2);
					end if;	 
				end if;		  
			
				Prescaler <= (others => '0');
			end if;
		end if;
	end process PrescalerCounter; 

	ColorOutput <=		"111100000000" when ColorSelect(0) = '1' AND ScanlineX >= SquareX AND ScanlineY >= SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareWidth 
					else	"000011110000" when ColorSelect(1) = '1' AND ScanlineX >= SquareX AND ScanlineY >= SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareWidth 
					else	"000000001111" when ColorSelect(2) = '1' AND ScanlineX >= SquareX AND ScanlineY >= SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareWidth 
					else	"111111111111";

	ColorOut <= ColorOutput;
	
	SquareXmax <= "1010000000"-SquareWidth; -- (640 - SquareWidth)
	SquareYmax <= "0111100000"-SquareWidth;	-- (480 - SquareWidth)
end Behavioral;

