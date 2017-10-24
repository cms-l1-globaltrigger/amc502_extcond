-- ext_cond phase_sel
--
-- Shifts input data with 240MHz phase.
-- The Phase Counter helps to find the correct sampling point.
--
-- Johannes Wittmann, March 2016
--
-- JW 06.04.2016: Phase Counter added

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus_reg_types.all;
use work.user_package.all;
use work.gt_mp7_core_pkg.all;

entity phase_sel is
    generic
    (
        DATA_WIDTH            : integer := 64;
        USE_REGISTERED_OUTPUT : boolean := false
    );
    port(
        lhc_clk: in std_logic; -- sync clk
        rst: in std_logic;
        clk_p: in std_logic; -- 240MHz clk
        phase_sel_in: in ipb_reg_v(63 downto 0);
        cntr_read_pulse: in std_logic;
        phase_cntr: out ipb_reg_v(127 downto 0);
        data_in: in  std_logic_vector(DATA_WIDTH-1 downto 0); -- inputs
        data_out: out  std_logic_vector(DATA_WIDTH-1 downto 0) -- outputs
    );
end phase_sel;

architecture rtl of phase_sel is

constant RST_ACT: std_logic := '1';
constant PHASE0: std_logic_vector(3 downto 0) := X"0";
constant PHASE1: std_logic_vector(3 downto 0) := X"1";
constant PHASE2: std_logic_vector(3 downto 0) := X"2";
constant PHASE3: std_logic_vector(3 downto 0) := X"3";
constant PHASE4: std_logic_vector(3 downto 0) := X"4";
constant PHASE5: std_logic_vector(3 downto 0) := X"5";

signal data, in5, in4, in3, in2, in1, in0 : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
signal sample0, sample1, sample2, sample3, sample4, sample5, sample_pre5 : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

begin

    -- Oversampling of 40 MHz LVDS data with 240MHz
    ov_samples: process(rst, clk_p)
    begin
        if rst = RST_ACT then
            in5 <= (others => '0'); -- phase 2 data
            in4 <= (others => '0'); -- phase 2 data
            in3 <= (others => '0'); -- phase 2 data
            in2 <= (others => '0'); -- phase 2 data
            in1 <= (others => '0'); -- phase 1 data
            in0 <= (others => '0'); -- phase 0 data
        elsif clk_p'event and clk_p = '1' then
            in5 <= data_in;      -- seen by sampling 3 (at last)
            in4 <= in5;             -- seen by sampling 2
            in3 <= in4;             -- seen by sampling 2
            in2 <= in3;             -- seen by sampling 2
            in1 <= in2;             -- seen by sampling 1
            in0 <= in1;             -- seen by sampling 0 (first)
        end if;
    end process ov_samples;

   -- LVDS PHASE selection
    mux: process(rst, lhc_clk)
    begin
        if rst = RST_ACT then
            data <= (others => '0');
        elsif lhc_clk'event and lhc_clk = '1' then
            for i in 0 to (DATA_WIDTH-1) loop      -- loop over all ext cond bits
            if    phase_sel_in(i)(3 downto 0) = PHASE0 then data(i) <= in0(i);
            elsif phase_sel_in(i)(3 downto 0) = PHASE1 then data(i) <= in1(i);
            elsif phase_sel_in(i)(3 downto 0) = PHASE2 then data(i) <= in2(i);
            elsif phase_sel_in(i)(3 downto 0) = PHASE3 then data(i) <= in3(i);
            elsif phase_sel_in(i)(3 downto 0) = PHASE4 then data(i) <= in4(i);
            elsif phase_sel_in(i)(3 downto 0) = PHASE5 then data(i) <= in5(i);
            end if;
            end loop;
        end if;
    end process mux;

    -- Phase counter block -------------------------------------------------------
    get_samples: process(rst, lhc_clk)
    variable in0_var, in1_var, in2_var, in3_var, in4_var, in5_var : std_logic;
    begin
        if rst = RST_ACT then
            sample0 <= (others => '0');
            sample1 <= (others => '0');
            sample2 <= (others => '0');
            sample3 <= (others => '0');
            sample4 <= (others => '0');
            sample5 <= (others => '0');
            sample_pre5 <= (others => '0');
        elsif lhc_clk'event and lhc_clk = '1' then
            for i in 0 to (DATA_WIDTH-1) loop   --loop over all 64 signals
            in0_var := in0(i);
            in1_var := in1(i);   -- get 6 samples of all bits of a group
            in2_var := in2(i);
            in3_var := in3(i);
            in4_var := in4(i);
            in5_var := in5(i);
            sample0(i) <= in0_var; -- take sample0
            sample1(i) <= in1_var; -- take sample1
            sample2(i) <= in2_var; -- take sample2
            sample3(i) <= in3_var; -- take sample3
            sample4(i) <= in4_var; -- take sample3
            sample5(i) <= in5_var; -- take sample3
            sample_pre5(i) <= sample5(i); -- keep previous sample for xor counter
            end loop;
        end if;
    end process get_samples;

    phase_cntrs: for i in 0 to (DATA_WIDTH-1) generate
    begin
        ph_cntrs: entity work.phase_counter
        port map (
            clk => lhc_clk,
            rst => rst,
            s0 => sample0(i),
            s1 => sample1(i),
            s2 => sample2(i),
            s3 => sample3(i),
            s4 => sample4(i),
            s5 => sample5(i),
            s_pre5 => sample_pre5(i),
            read_pulse => cntr_read_pulse,
            phase_cntr_lo => phase_cntr(2*i),
            phase_cntr_hi => phase_cntr(2*i+1)
        );
    end generate phase_cntrs;
    -- END Phase counter block -----------------------------------------------

    -- Output selection ------------------------------------------------------
    GEN_ADDITIONAL_OUTPUT_REGISTER : if USE_REGISTERED_OUTPUT = true generate
        sync_clk : process (lhc_clk, rst)
        begin
            if rst = RST_ACT then
                data_out <= (others => '0');
            elsif rising_edge(lhc_clk) then
                data_out <= data;
            end if;
        end process;
    end generate;

    DONT_GEN_ADDITIONAL_OUTPUT_REGISTER : if USE_REGISTERED_OUTPUT = false generate
        data_out <= data;
    end generate;
    -- END Output selection -------------------------------------------------

end architecture;