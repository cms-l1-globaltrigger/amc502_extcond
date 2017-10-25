--
-- Address decode logic for ipbus fabric.
-- Do NOT edit this file it will be AUTOGENERATED by gtu-ipbus-decoder.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.math_pkg.all;


package ipbus_decode_mp7_payload is

    -- Number of slaves defined in the address table.
    constant N_SLAVES: positive := 11;

    -- Define selection vector format.
    constant IPBUS_SEL_WIDTH: positive := log2c(N_SLAVES);
    subtype ipbus_sel_t is std_logic_vector(IPBUS_SEL_WIDTH - 1 downto 0);
    function ipbus_sel_mp7_payload(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t;

    -- Item's unique identification index, used in slave implementation.
    constant N_SLV_MINFO: integer := 0;
    constant N_SLV_DEL: integer := 1;
    constant N_SLV_TCM: integer := 2;
    constant N_SLV_PULSE_REGS: integer := 3;
    constant N_SLV_PHASE: integer := 4;
    constant N_SLV_PHASECNTR: integer := 5;
    constant N_SLV_RATECNTR: integer := 6; -- HB 2017-08-28: inserted rate counter status regs for ext cond inputs

    type n_slv_spymem_array is array (0 to 1) of natural;
    constant N_SLV_SPYMEM : n_slv_spymem_array := (7, 8);

    type n_slv_simmem_array is array (0 to 1) of natural;
    constant N_SLV_SIMMEM : n_slv_simmem_array := (9, 10);

    -- Item's address width in bits, used in slave implementation.
    constant N_SLV_MINFO_SIZE: integer := 5;
    constant N_SLV_DEL_SIZE: integer := 6;
    constant N_SLV_PHASE_SIZE: integer := 6;
    constant N_SLV_PHASECNTR_SIZE: integer := 8;
    constant N_SLV_TCM_SIZE: integer := 5;
    constant N_SLV_PULSE_REGS_SIZE: integer := 5;
    constant N_SLV_SPYMEM_SIZE: integer := 12;
    constant N_SLV_SIMMEM_SIZE: integer := 12;
    constant N_SLV_RATECNTR_SIZE: integer := 8; -- HB 2017-08-28: inserted rate counter status regs for ext cond inputs

end ipbus_decode_mp7_payload;

package body ipbus_decode_mp7_payload is

    function ipbus_sel_mp7_payload(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t is
        variable sel: ipbus_sel_t;

    begin
        if    std_match(addr, "100000000000000000000000000-----") then sel := ipbus_sel_t(to_unsigned(N_SLV_MINFO, IPBUS_SEL_WIDTH));       -- 0x80000000
        elsif std_match(addr, "10000000000000000000000001------") then sel := ipbus_sel_t(to_unsigned(N_SLV_DEL, IPBUS_SEL_WIDTH));         -- 0x80000040
        elsif std_match(addr, "100000000000000000000000100-----") then sel := ipbus_sel_t(to_unsigned(N_SLV_TCM, IPBUS_SEL_WIDTH));         -- 0x80000080
        elsif std_match(addr, "100000000000000000000000101-----") then sel := ipbus_sel_t(to_unsigned(N_SLV_PULSE_REGS, IPBUS_SEL_WIDTH));  -- 0x800000A0
        elsif std_match(addr, "10000000000000000000000011------") then sel := ipbus_sel_t(to_unsigned(N_SLV_PHASE, IPBUS_SEL_WIDTH));       -- 0x800000C0
        elsif std_match(addr, "100000000000000000000001--------") then sel := ipbus_sel_t(to_unsigned(N_SLV_PHASECNTR, IPBUS_SEL_WIDTH));   -- 0x80000100
        elsif std_match(addr, "100000000000000000000010--------") then sel := ipbus_sel_t(to_unsigned(N_SLV_RATECNTR, IPBUS_SEL_WIDTH));    -- 0x80000200 -- HB 2017-08-28: inserted rate counter status regs for ext cond inputs
        elsif std_match(addr, "10000001000000000000------------") then sel := ipbus_sel_t(to_unsigned(N_SLV_SPYMEM(0), IPBUS_SEL_WIDTH));   -- 0x81000000 .. 0x81000FFF
        elsif std_match(addr, "10000001000000000001------------") then sel := ipbus_sel_t(to_unsigned(N_SLV_SPYMEM(1), IPBUS_SEL_WIDTH));   -- 0x81001000 .. 0x81001FFF
        elsif std_match(addr, "10000001000000000010------------") then sel := ipbus_sel_t(to_unsigned(N_SLV_SIMMEM(0), IPBUS_SEL_WIDTH));   -- 0x81002000 .. 0x81002FFF
        elsif std_match(addr, "10000001000000000011------------") then sel := ipbus_sel_t(to_unsigned(N_SLV_SIMMEM(1), IPBUS_SEL_WIDTH));   -- 0x81003000 .. 0x81003FFF
        else
            sel := ipbus_sel_t(to_unsigned(N_SLAVES, IPBUS_SEL_WIDTH));
        end if;

        return sel;

    end function ipbus_sel_mp7_payload;

end ipbus_decode_mp7_payload;
