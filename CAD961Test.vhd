-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CAD961Test is
	Port(
		--//////////// CLOCK //////////
		CLOCK_50 	: in std_logic;
		CLOCK2_50	: in std_logic;
		CLOCK3_50	: in std_logic;
		CLOCK4_50	: inout std_logic;
		
		--//////////// KEY //////////
		RESET_N	: in std_logic;
		Key 		: in std_logic_vector(3 downto 0);
	
		--//////////// SEG7 //////////
		HEX0	: out std_logic_vector(6 downto 0);
		HEX1	: out std_logic_vector(6 downto 0);
		HEX2	: out std_logic_vector(6 downto 0);
		HEX3	: out std_logic_vector(6 downto 0);
		HEX4	: out std_logic_vector(6 downto 0);
		HEX5	: out std_logic_vector(6 downto 0);
	
		--//////////// LED //////////
		LEDR	: out std_logic_vector(9 downto 0);
	
		--//////////// SW //////////
		Switch : in std_logic_vector(9 downto 0);
		
		--//////////// SDRAM //////////
		DRAM_ADDR	: out std_logic_vector (12 downto 0);
		DRAM_BA		: out std_logic_vector (1 downto 0); 
		DRAM_CAS_N	: out std_logic;
		DRAM_CKE		: out std_logic;
		DRAM_CLK		: out std_logic;
		DRAM_CS_N	: out std_logic;
		DRAM_DQ		: inout std_logic_vector(15 downto 0);
		DRAM_LDQM	: out std_logic;
		DRAM_RAS_N	: out std_logic;
		DRAM_UDQM	: out std_logic;
		DRAM_WE_N	: out std_logic;
		
		--//////////// microSD Card //////////
		SD_CLK	: out std_logic;
		SD_CMD	: inout std_logic;
		SD_DATA	: inout std_logic_vector(3 downto 0);
		
		--//////////// VGA //////////
		VGA_B		: out std_logic_vector(3 downto 0);
		VGA_G		: out std_logic_vector(3 downto 0);
		VGA_HS	: out std_logic;
		VGA_R		: out std_logic_vector(3 downto 0);
		VGA_VS	: out std_logic;
		
		--//////////// GPIO_1, GPIO_1 connect to LT24 - 2.4" LCD and Touch //////////
		MyLCDLT24_ADC_BUSY		: in std_logic;
		MyLCDLT24_ADC_CS_N		: out std_logic;
		MyLCDLT24_ADC_DCLK		: out std_logic;
		MyLCDLT24_ADC_DIN			: out std_logic;
		MyLCDLT24_ADC_DOUT		: in std_logic;
		MyLCDLT24_ADC_PENIRQ_N	: in std_logic;
		MyLCDLT24_CS_N				: out std_logic;
		MyLCDLT24_D					: out std_logic_vector(15 downto 0);
		MyLCDLT24_LCD_ON			: out std_logic;
		MyLCDLT24_RD_N				: out std_logic;
		MyLCDLT24_RESET_N			: out std_logic;
		MyLCDLT24_RS				: out std_logic;
		MyLCDLT24_WR_N				: out std_logic
	);
end CAD961Test;

--}} End of automatically maintained section

architecture CAD961Test of CAD961Test is

Component LFSR

	 port (
		 reset   : in  std_logic;
		 clk     : in  std_logic; 
		 count   : out std_logic_vector (63 downto 0) -- lfsr output
	  );
end component;

Component VGA_controller
	port ( CLK_50MHz		: in std_logic;
         VS					: out std_logic;
			HS					: out std_logic;
			RED				: out std_logic_vector(3 downto 0);
			GREEN				: out std_logic_vector(3 downto 0);
			BLUE				: out std_logic_vector(3 downto 0);
			RESET				: in std_logic;
			ColorIN			: in std_logic_vector(11 downto 0);
			ScanlineX		: out std_logic_vector(10 downto 0);
			ScanlineY		: out std_logic_vector(10 downto 0)
  );
end component;

Component color_fill
	port ( CLK_50MHz		: in std_logic;
			RESET				: in std_logic;
			ColorOut			: out std_logic_vector(11 downto 0); -- RED & GREEN & BLUE
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0);
			LFSR_IN			: in std_logic_vector(63 downto 0);
			Key				: in std_logic_vector(3 downto 0);
			Switch		: in std_logic
  );
end component;



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

signal Counter : integer;
signal ScanlineX,ScanlineY	: std_logic_vector(10 downto 0);
signal ColorTable	: std_logic_vector(11 downto 0);

signal LFSR_OUT : std_logic_vector(63 downto 0);
begin

	 --------- VGA Controller -----------
	 VGA_Control: vga_controller
			port map(
				CLK_50MHz	=> CLOCK3_50,
				VS				=> VGA_VS,
				HS				=> VGA_HS,
				RED			=> VGA_R,
				GREEN			=> VGA_G,
				BLUE			=> VGA_B,
				RESET			=> not RESET_N,
				ColorIN		=> ColorTable,
				ScanlineX	=> ScanlineX,
				ScanlineY	=> ScanlineY
			);
		
		--------- COLOR FIll -----------
		VGA_SQ: color_fill
			port map(
				CLK_50MHz		=> CLOCK3_50,
				RESET				=> not RESET_N,
				ColorOut			=> ColorTable,
				ScanlineX		=> ScanlineX,
				ScanlineY		=> ScanlineY,
				LFSR_IN 			=> LFSR_OUT,
				key 				=> key,
				Switch 			=> switch(0)
			);
	 
	 ------------ LFSR ----------------
	 RANDOM_GENERATOR: LFSR
		port map (
			reset => not RESET_N,
			clk => CLOCK3_50,
			count => LFSR_OUT
		);
	 
	 --------- 7Segment Show ------------
	 Process(CLOCK_50, RESET_N)
	 begin
		if (RESET_N='0') then
			Counter <= 0;
		elsif (rising_edge(CLOCK_50)) then
			if (Counter = 600000000) then
				Counter <= 0;
			else
				Counter <= Counter +1;
			end if;
		end if;
	 end process;
	 
	 Process (Counter)
	 begin
		if (Counter < 100000000) then
			HEX0 <= convSEG("0000");
			HEX1 <= (0 => '1', others => '0');
		elsif (Counter < 200000000) then
			HEX0 <= convSEG("0001");
			HEX1 <= (1 => '1', others => '0');
		elsif (Counter < 300000000) then
			HEX0 <= convSEG("0010");
			HEX1 <= (2 => '1', others => '0');
		elsif (Counter < 400000000) then
			HEX0 <= convSEG("0011");
			HEX1 <= (3 => '1', others => '0');
		elsif (Counter < 500000000) then
			HEX0 <= convSEG("0100");
			HEX1 <= (4 => '1', others => '0');
		elsif (Counter < 600000000) then
			HEX0 <= convSEG("0101");
			HEX1 <= (5 => '1', others => '0');
		elsif (Counter < 700000000) then
			HEX0 <= convSEG("0110");
			HEX1 <= (6 => '1', others => '0');
		elsif (Counter < 800000000) then
			HEX0 <= convSEG("0111");
			HEX1 <= (0 => '1', others => '0');
		elsif (Counter < 900000000) then
			HEX0 <= convSEG("1000");
			HEX1 <= (1 => '1', others => '0');
		elsif (Counter < 1000000000) then
			HEX0 <= convSEG("1001");
			HEX1 <= (2 => '1', others => '0');
		elsif (Counter < 1100000000) then
			HEX0 <= convSEG("1010");
			HEX1 <= (3 => '1', others => '0');
		elsif (Counter < 1200000000) then
			HEX0 <= convSEG("1011");
			HEX1 <= (4 => '1', others => '0');
		elsif (Counter < 1300000000) then
			HEX0 <= convSEG("1100");
			HEX1 <= (5 => '1', others => '0');
		elsif (Counter < 1400000000) then
			HEX0 <= convSEG("1101");
			HEX1 <= (6 => '1', others => '0');
		elsif (Counter < 1500000000) then
			HEX0 <= convSEG("1110");
			HEX1 <= (0 => '1', others => '0');
		elsif (Counter < 1600000000) then
			HEX0 <= convSEG("1111");
			HEX1 <= (1 => '1', others => '0');
		else 
			HEX0 <= (others => '1');
			HEX1 <= (others => '1');
		end if;
	 end process;
	 
	
	 -- Mehran --
    HEX2 <= convSEG("0101");
	 HEX3 <= convSEG("0010");
	 -- Parsa --
	 HEX4 <= convSEG("0110");
	 HEX5 <= convSEG("0000");
	 
end CAD961Test;
