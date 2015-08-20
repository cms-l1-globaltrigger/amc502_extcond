--------------------------------------------------------------------------------
-- Synthesizer : ISE 14.6
-- Platform    : Linux Ubuntu 10.04
-- Targets     : Synthese
--------------------------------------------------------------------------------
-- This work is held in copyright as an unpublished work by HEPHY (Institute
-- of High Energy Physics) All rights reserved.  This work may not be used
-- except by authorized licensees of HEPHY. This work is the
-- confidential information of HEPHY.
--------------------------------------------------------------------------------
-- $HeadURL: svn://heros.hephy.oeaw.ac.at/GlobalTriggerUpgrade/firmware/TDF_fw_integration/trunk/tdf_algos/firmware/hdl/tdf_mp7_top_pkg_tpl.vhd $
-- $Date: 2015-07-30 16:00:15 +0200 (Thu, 30 Jul 2015) $
-- $Author: wittmann $
-- $Revision: 4118 $
--------------------------------------------------------------------------------
--
-- Notes on using `gtu-pkgpatch-ipbus' for this package:
--  * _IPBUS_TIMESTAMP_    32 bit UNIX timestamp placeholder (X"00000000")
--  * _IPBUS_USERNAME_     unix username 32 char string placeholder (X"...")
--  * _IPBUS_HOSTNAME_     machine hostname 32 char string placeholder (X"...")
--
--------------------------------------------------------------------------------

-- HB 2014-09-08: v1.4.0.0: package for mp7 fw version v1.4.0
-- HB 2014-09-08: v1.0.4.15: bug fixed in UCF (to use 4 quads), user constraint for quad(3) was set
-- HB 2014-09-02: v1.0.4.14: changed to 4 quads (for external-conditions) and added signals to mezz-board (bcres_d_FDL_int - for checking on scope) in gt_mp7_top.vhd

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.top_decl.all;
use work.mp7_brd_decl.all;

package tdf_mp7_top_pkg is

-- constant MAC_ADDR : std_logic_vector(47 downto 0) := X"000a3501eaf1";
-- constant IP_ADDR : std_logic_vector(31 downto 0) := X"c0a801c9"; -- HEPHY_CRATE:192.168.1.201

-- HB 2014-05-30: moved definition from gt_mp7_core_pkg.vhd, but constants still exits in gt_mp7_core_pkg.vhd (see there!)
constant TOP_TYPE_PROTOCOL: std_logic_vector(3 downto 0) := X"3"; -- IP_BUS_2.0
constant TOP_MODULE_TYPE: std_logic_vector(3 downto 0) := X"2"; -- MP7
-- constant TOP_SERIAL_NUMBER: std_logic_vector(23 downto 0) := X"000000"; -- not used anymore !!!
-- constant TOP_SERIAL_VENDOR: std_logic_vector(63 downto 0) := X"0000433331394F50"; -- serial number of MP7 (2 x 32 bits), interpreted as ASCII (actual HW module => "PO913C")
-- BA 2014-08-06: TIMESTAMP generated by gtu-pkgpatch-ipbus (32 bits), has to be interpreted as 32 bit UNIX timestamp.
constant TOP_TIMESTAMP : std_logic_vector(31 downto 0) := {{IPBUS_TIMESTAMP}};
-- HB 2014-05-23: USERNAME generated by gtu-pkgpatch-ipbus (256 bits = 8 x 32 bits), has to be interpreted as 32 ASCII-characters string (from right to left).
constant TOP_USERNAME : std_logic_vector(32*8-1 downto 0)  := {{IPBUS_USERNAME}};
-- HB 2014-05-23: HOSTNAME generated by gtu-pkgpatch-ipbus (256 bits = 8 x 32 bits), has to be interpreted as 32 ASCII-characters string (from right to left).
constant TOP_HOSTNAME : std_logic_vector(32*8-1 downto 0) := {{IPBUS_HOSTNAME}};
-- HB 2014-05-23: BUILD_VERSION generated by gtu-pkgpatch-ipbus (32 bits), has to be interpreted as hex value.
constant TOP_BUILD_VERSION : std_logic_vector(31 downto 0) := {{IPBUS_BUILD_VERSION}};

constant IMPERIAL_FW_VERSION : std_logic_vector(23 downto 0) := X"010401"; -- mp7 fw version v1.4.0
constant GT_VARIATION : std_logic_vector(7 downto 0) := X"00"; -- GT variation of mp7 fw version v1.4.0
constant IMPERIAL_FW_ID : std_logic_vector(31 downto 0) := IMPERIAL_FW_VERSION & GT_VARIATION;

--constant LHC_BUNCH_COUNT : natural range 3564 to 3564 := 3564; -- LHC orbit length
-- HB 2014-09-01: added external-conditions data in lmp, so 4 NQUADs needed (= 16 lanes)
-- constant NQUAD : natural range 0 to 18 := 3; -- number of QUADs (GTH quads)
   constant NQUAD : natural range 0 to 18 := N_REGION; -- number of QUADs (GTH quads), this constant is defined in top_decl.vhd
--constant CLOCK_RATIO : natural range 0 to 6 := 6; -- 32 bit data within a LHC clock periode (?)

-- -- HB 2014-05-12: future aspect looking at "trunk/cactusupgrades/components/mp7_links/firmware/hdl/protocol"
-- constant QUAD_EXT_COND : natural range 0 to 18 := 4; -- index of QUAD for external condition (in generic declaration of mp7_mgt.vhd and quad_wrapper_gth.vhd)

-- =================================================================================================================
-- HB 2014-09-12: inserted from ../mp7fw_v1_4_0/cactusupgrades/projects/examples/mp7_690es/firmware/hdl/top_decl.vhd
-- -- 	constant LHC_BUNCH_COUNT: integer := 3564; -- for definition - see above
-- 	constant LB_ADDR_WIDTH: integer := 10;
-- 	constant DR_ADDR_WIDTH: integer := 9;
-- 	constant RO_ADDR_WIDTH: integer := 15;
-- -- 	constant N_REGION: integer := 18;
-- 	constant N_REGION: integer := NQUAD;
-- 	constant ALIGN_REGION: integer := 4; -- HB 2014-09-16: not clear, what that is, see mp7_datapath_2.vhd !!!
-- 	constant CROSS_REGION: integer := 8; -- HB 2014-09-16: not clear, what that is, see mp7_region.vhd !!!
-- -- 	constant CLOCK_RATIO: integer := 6; -- for definition - see above
-- 	constant N_REFCLK: integer := 9;
--
-- 	type region_kind_t is (empty, buf_only, gth_10g);
--
-- 	type region_conf_t is
-- 		record
-- 			kind: region_kind_t;
-- 			xloc: integer;
-- 			yloc: integer;
-- 			refclk: integer range 0 to N_REFCLK - 1;
-- 		end record;
--
-- 	type region_conf_array_t is array(0 to N_REGION - 1) of region_conf_t;
--
--  -- HB 2014-09-16: changed to NQUAD=4
-- 	constant REGION_CONF: region_conf_array_t := (
-- 		(gth_10g, 1, 8, 3), -- 0 / 118
-- 		(gth_10g, 1, 7, 3), -- 1 / 117*
-- 		(gth_10g, 1, 6, 4), -- 2 / 116
-- 		(gth_10g, 1, 5, 4) -- 3 / 115*
-- -- 		(gth_10g, 1, 4, 5), -- 4 / 114
-- -- 		(gth_10g, 1, 3, 5), -- 5 / 113*
-- -- 		(gth_10g, 1, 2, 7), -- 6 / 112
-- -- 		(gth_10g, 1, 1, 7), -- 7 / 111*
-- -- 		(gth_10g, 1, 0, 7), -- 8 / 110
-- -- 		(gth_10g, 0, 0, 6), -- 9 / 210
-- -- 		(gth_10g, 0, 1, 6), -- 10 / 211*
-- -- 		(gth_10g, 0, 2, 2), -- 11 / 212
-- -- 		(gth_10g, 0, 3, 2), -- 12 / 213*
-- -- 		(gth_10g, 0, 4, 1), -- 13 / 214
-- -- 		(gth_10g, 0, 5, 1), -- 14 / 215*
-- -- 		(gth_10g, 0, 6, 0), -- 15 / 216
-- -- 		(gth_10g, 0, 7, 0), -- 16 / 217*
-- -- 		(gth_10g, 0, 8, 0) -- 17 / 218
-- --		(gth_10g, 0, 9, 8) -- 18 / 219
-- 	);

-- =================================================================================================================


end;



