
----------------------------------------------------------------------------------
-- Logicko projektovanje racunarskih sistema 1
-- 2011/2012,2020
-- Lab 6
--
-- Computer system top level testbench
--
-- authors:
-- Ivan Kastelan (ivan.kastelan@rt-rk.com)
-- Milos Subotic (milos.subotic@uns.ac.rs)
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library std;
use std.textio.all;

entity top_tb is
end top_tb;

architecture Behavior of top_tb is

	component top is
		generic(
			-- Default frequency used in synthesis.
			constant CLK_FREQ         : positive := 12000000;
			constant CNT_BITS_COMPENS : integer  := 0
		);
		port(
			iCLK       : in  std_logic;
			inRST      : in  std_logic;
			oLED       : out std_logic_vector(15 downto 0);
			onCOL      : out std_logic_vector(7 downto 0);
			oMUX_ROW   : out std_logic_vector(2 downto 0);
			oMUX_COLOR : out std_logic_vector(1 downto 0);
			iPB_UP     : in  std_logic;
			iPB_DOWN   : in  std_logic;
			iPB_LEFT   : in  std_logic;
			iPB_RIGHT  : in  std_logic;
			iPB_CENTAR   : in  std_logic
		);
	end component top;
	
	
	--Inputs
	signal iCLK       : std_logic := '0';
	signal inRST      : std_logic := '0';
	signal oLED       : std_logic_vector (15 downto 0);
	signal onCOL      : std_logic_vector(7 downto 0);
	signal oMUX_ROW   : std_logic_vector(2 downto 0);
	signal oMUX_COLOR : std_logic_vector(1 downto 0);
	signal iPB_UP     : std_logic := '0';
	signal iPB_DOWN   : std_logic := '0';
	signal iPB_LEFT   : std_logic := '0';
	signal iPB_RIGHT  : std_logic := '0';
	signal iPB_CENTAR  : std_logic := '0';

	constant iCLK_period : time := 83.333333 ns; -- 12MHz
	constant FRAME_LEN : natural := 1600;
	
	
	subtype tRGB is std_logic_vector(2 downto 0);
	type tRGB_MATRIX is array (0 to 7, 0 to 7) of tRGB;
	-- Indeksing goes like: sRGB_MATRIX(y, x)
	signal sRGB_MATRIX : tRGB_MATRIX;
	
	file fo : text open WRITE_MODE is "STD_OUTPUT";

begin


	-- Instantiate the Unit Under Test (UUT)
	uut: top
	generic map(
		--TODO Make it round. To have change on every 1 us.
		CLK_FREQ         => 120000, -- Everything is 100x faster.
		CNT_BITS_COMPENS => -7 -- Less bits to avoid warnings.
	)
	port map(
		iCLK       => iCLK,
		inRST      => inRST,
		oLED       => oLED,
		onCOL      => onCOL,
		oMUX_ROW   => oMUX_ROW,
		oMUX_COLOR => oMUX_COLOR,
		iPB_UP     => iPB_UP,
		iPB_DOWN   => iPB_DOWN,
		iPB_LEFT   => iPB_LEFT,
		iPB_RIGHT  => iPB_RIGHT,
		iPB_CENTAR => iPB_CENTAR
	);


	-- Clock process definitions
	iCLK_proc: process
	begin
		iCLK <= '0';
		wait for iCLK_period/2;
		iCLK <= '1';
		wait for iCLK_period/2;
	end process;


	-- Stimulus process
	stim_proc: process
	begin
		
		-- Tests go here ---------------------
		inRST <= '0';
		wait for 2*iCLK_period;
		inRST <= '1';
				
		iPB_RIGHT <= '1';
		wait for 10*iCLK_period;
		iPB_RIGHT <= '0';
		wait for (FRAME_LEN-10)*iCLK_period;
		wait for 3*FRAME_LEN*iCLK_period;
		
		iPB_CENTAR <= '1';
		wait for 10*iCLK_period;
		iPB_CENTAR <= '0';
		wait for (FRAME_LEN-10)*iCLK_period;
		wait for FRAME_LEN*iCLK_period;
		
		iPB_RIGHT <= '1';
		wait for 10*iCLK_period;
		iPB_RIGHT <= '0';
		wait for (FRAME_LEN-10)*iCLK_period;
		wait for 3*FRAME_LEN*iCLK_period;
		
		--------------------------------------
		wait;
	end process;



	process(iCLK, inRST)
	begin
		if inRST = '0' then
			sRGB_MATRIX <= (others => (others => "000"));
		elsif rising_edge(iCLK) then
			for col in 0 to 7 loop
				case oMUX_COLOR is
					when "00" => -- Red
						sRGB_MATRIX(conv_integer(oMUX_ROW), col)(0)
							<= not onCOL(col);
					when "01" => -- Green
						sRGB_MATRIX(conv_integer(oMUX_ROW), col)(1)
							<= not onCOL(col);
					when "10" => -- Blue
						sRGB_MATRIX(conv_integer(oMUX_ROW), col)(2)
							<= not onCOL(col);
					when others =>
				end case;
			end loop;
		end if;
	end process;


	process(oMUX_COLOR)
		variable l : line;
	begin
		if oMUX_COLOR'event and oMUX_COLOR = "11" then
			write(l, string'("# # # # # # # # # #"));
			writeline(fo, l);
			for y in 0 to 7 loop
				for x in 0 to 7 loop
					case sRGB_MATRIX(y, x) is
						when "001" =>
							write(l, string'("+"));
						when "010" =>
							write(l, string'("O"));
						when "100" =>
							write(l, string'("x"));
						when others =>
							write(l, string'("."));
					end case;
					write(l, string'(" "));
				end loop;
				write(l, string'("#"));
				writeline(fo, l);
			end loop;
			write(l, string'("# # # # # # # # # #"));
			writeline(fo, l);
		end if;
	end process;

end architecture;
