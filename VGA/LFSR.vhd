library ieee;    
  use ieee.std_logic_1164.all;

entity LFSR is
	generic (bit_size : integer := 63);
  port (
    reset   : in  std_logic;
    clk     : in  std_logic; 
    count   : out std_logic_vector (bit_size downto 0) -- lfsr output
  );
end entity;

architecture rtl of LFSR is
  signal count_i        : std_logic_vector (bit_size downto 0); 
  signal feedback     : std_logic;

begin
  feedback <= not(count_i(bit_size) xor count_i(bit_size-1));        -- LFSR size 4

  process (reset, clk) 
  begin
    if (reset = '1') then
      count_i <= (others=>'0');
    elsif (rising_edge(clk)) then
      count_i <= count_i(bit_size-1 downto 0) & feedback;
    end if;
  end process;
  count <= count_i;

end architecture;