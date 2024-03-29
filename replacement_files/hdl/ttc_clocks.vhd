-- ttc_clocks
--
-- Clock generation for LHC clocks
--
-- Dave Newbold, June 2013

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library unisim;
use unisim.VComponents.all;

use work.mp7_top_decl.all;
use work.top_decl.all;


entity ttc_clocks is
	port(
		clk40_in_p: in std_logic;		
		clk40_in_n: in std_logic;
		clk_p40: in std_logic;
		clko_40: out std_logic;
		clko_p: out std_logic;
		clko_aux: out std_logic_vector(2 downto 0);
		rsto_40: out std_logic;
		rsto_p: out std_logic;
		rsto_aux: out std_logic_vector(2 downto 0);
		clko_40s: out std_logic;
		stopped: out std_logic;
		locked: out std_logic;
		rst_mmcm: in std_logic;
		rsti: in std_logic;
		clksel: in std_logic;
		psen: in std_logic;
		psval: in std_logic_vector(11 downto 0);
		psok: out std_logic
	);

end ttc_clocks;

architecture rtl of ttc_clocks is

	signal clk40_bp, clk40_bp_u, clk_fb, clk_fb_fr, clk_p40_b: std_logic;
	signal clk40_u, clk_p_u, clk40s_u, clk40_i, clk_p_i: std_logic;
	signal clks_aux_u, clks_aux_i, rsto_aux_r: std_logic_vector(2 downto 0);
	signal locked_i, rsto_p_r: std_logic;
	signal pscur_i: std_logic_vector(11 downto 0);
	signal psrst, psgo, psincdec, psdone, psbusy, psdiff: std_logic;
	
begin

-- Input buffers

	ibuf_clk40: IBUFGDS
		port map(
			i => clk40_in_p,
			ib => clk40_in_n,
			o => clk40_bp_u
		);
		
	bufr_clk40: BUFG
		port map(
			i => clk40_bp_u,
			o => clk40_bp
		);
		
-- MMCM

	mmcm: MMCME2_ADV
		generic map(
			clkin1_period => 25.0,
			clkin2_period => 25.0,
			clkfbout_mult_f => 24.0,
			clkout1_divide => 24,
			clkout2_divide => 24,
			clkout2_phase => 45.0, -- Adjust on test
			clkout2_use_fine_ps => true,
			clkout3_divide => 24 / CLOCK_RATIO,
			clkout4_divide => 24 / CLOCK_AUX_RATIO(0),
			clkout5_divide => 24 / CLOCK_AUX_RATIO(1),
			clkout6_divide => 24 / CLOCK_AUX_RATIO(2)
		)
		port map(
			clkin1 => clk40_bp,
			clkin2 => clk_p40,
			clkinsel => clksel,
			clkfbin => clk_fb,
			clkfbout => clk_fb,
			clkout1 => clk40_u,
			clkout2 => clk40s_u,
			clkout3 => clk_p_u,
			clkout4 => clks_aux_u(0),
			clkout5 => clks_aux_u(1),
			clkout6 => clks_aux_u(2),
			rst => rst_mmcm,
			pwrdwn => '0',
			clkinstopped => stopped,
			locked => locked_i,
			daddr => "0000000",
			di => X"0000",
			dwe => '0',
			den => '0',
			dclk => '0',
			psclk => clk40_i,
			psen => psgo,
			psincdec => psincdec,
			psdone => psdone
		);
		
	locked <= locked_i;

-- Phase shift state machine
	
	psrst <= rst_mmcm or not locked_i or not psen;

	process(clk40_i)
	begin
		if rising_edge(clk40_i) then

			if psrst = '1' then
				pscur_i <= X"000";
			elsif psdone = '1' then
				if psincdec = '1' then
					pscur_i <= std_logic_vector(unsigned(pscur_i) + 1);
				else
					pscur_i <= std_logic_vector(unsigned(pscur_i) - 1);
				end if;
			end if;

			psgo <= psdiff and not (psbusy or psgo or psrst);
			psbusy <= ((psbusy and not psdone) or psgo) and not psrst;

		end if;
	end process;
	
	psincdec <= '1' when psval > pscur_i else '0';
	psdiff <= '1' when psval /= pscur_i else '0';
	psok <= not psdiff;
	
-- Buffers
	
	bufg_40: BUFG
		port map(
			i => clk40_u,
			o => clk40_i
		);
		
	clko_40 <= clk40_i;

	process(clk40_i)
	begin
		if rising_edge(clk40_i) then
			rsto_40 <= rsti or not locked_i;
		end if;
	end process;

	bufg_p: BUFG
		port map(
			i => clk_p_u,
			o => clk_p_i
		);
		
	clko_p <= clk_p_i;
		
	process(clk_p_i)
	begin
		if rising_edge(clk_p_i) then
			rsto_p_r <= rsti or not locked_i; -- Disaster looms if tools duplicate this signal
			rsto_p <= rsto_p_r; -- Pipelining for high-fanout signal
		end if;
	end process;

	cgen: for i in 2 downto 0 generate
		
		bufg_aux: BUFG
			port map(
				i => clks_aux_u(i),
				o => clks_aux_i(i)
			);
			
		clko_aux(i) <= clks_aux_i(i);
			
		process(clks_aux_i(i))
		begin
			if rising_edge(clks_aux_i(i)) then
				rsto_aux_r(i) <= rsti or not locked_i; -- Disaster looms if tools duplicate this signal
				rsto_aux(i) <= rsto_aux_r(i); -- Pipelining for high-fanout signal
			end if;
		end process;

	end generate;

	bufr_40s: BUFG
		port map(
			i => clk40s_u,
			o => clko_40s
		);

end rtl;
