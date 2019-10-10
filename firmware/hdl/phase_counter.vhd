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

entity phase_counter is
    port(
        clk: in std_logic; -- sync clk
        rst: in std_logic;
        s0: in std_logic;
        s1: in std_logic;
        s2: in std_logic;
        s3: in std_logic;
        s4: in std_logic;
        s5: in std_logic;
        s_pre5: in std_logic;
        read_pulse: in std_logic;
        phase_cntr_lo: out std_logic_vector(31 downto 0);
        phase_cntr_hi: out std_logic_vector(31 downto 0)
    );
end phase_counter;

architecture rtl of phase_counter is

constant RST_ACT: std_logic := '1';
constant MAX_VALUE: std_logic_vector(7 downto 0) := X"FF";

signal inc: std_logic_vector(5 downto 0);
signal cntr, reg: phase_cntr_regs_array(5 downto 0) := (others => (others => '0'));

begin

    inc(0) <= s_pre5 xor s0; -- increment when samples are different
    inc(1) <= s0 xor s1;
    inc(2) <= s1 xor s2;
    inc(3) <= s2 xor s3;
    inc(4) <= s3 xor s4;
    inc(5) <= s4 xor s5;

    make_counters: for i in 0 to 5 generate
        phase_cntr: process(clk, rst)
        begin
            if rst = RST_ACT then
                cntr(i)  <= (others => '0');  -- counter
                reg(i)   <= (others => '0');  -- register
            elsif clk'event and clk = '1' then
                if read_pulse = '1' then
                    cntr(i) <= (others => '0');  -- reset counter
                    reg(i)  <= cntr(i);          -- load into register
                elsif cntr(i) = MAX_VALUE then
                    cntr(i)  <=  MAX_VALUE;      -- stop counting at FF
                elsif inc(i) = '1' then
                    cntr(i)  <= std_logic_vector(unsigned(cntr(i)) + 1);      -- increment counter
                end if;
            end if;
        end process phase_cntr;
    end generate make_counters;

    phase_cntr_lo <= reg(3) & reg(2) & reg(1) & reg(0); -- packing all 6 counters in the output signal
    phase_cntr_hi <= X"0000" & reg(5) & reg(4); -- packing all 6 counters in the output signal

end architecture;