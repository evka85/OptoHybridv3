------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Version : 3.6
--  \   \         Application : 7 Series FPGAs Transceivers Wizard
--  /   /         Filename : v6_gtx_wrapper.vhd
-- /___/   /\
-- \   \  /  \
--  \___\/\___\
--
--
-- Module v6_gtx_wrapper
-- Generated by Xilinx 7 Series FPGAs Transceivers Wizard
--
--
-- (c) Copyright 2010-2012 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

--***********************************Entity Declaration************************

entity v6_gtx_wrapper is
  port
  (

    refclk_p      : in   std_logic_vector (1 downto 0);
    refclk_n      : in   std_logic_vector (1 downto 0);

    clock_40      : in   std_logic;
    clock_160     : in   std_logic;

    GTTX_RESET_IN : in   std_logic;
    TXN_OUT       : out  std_logic_vector(3 downto 0);
    TXP_OUT       : out  std_logic_vector(3 downto 0);

    GTX0_TXCHARISK_IN                         : in   std_logic_vector(1 downto 0);
    GTX1_TXCHARISK_IN                         : in   std_logic_vector(1 downto 0);
    GTX2_TXCHARISK_IN                         : in   std_logic_vector(1 downto 0);
    GTX3_TXCHARISK_IN                         : in   std_logic_vector(1 downto 0);

    GTX0_TXDATA_IN                         : in   std_logic_vector(15 downto 0);
    GTX1_TXDATA_IN                         : in   std_logic_vector(15 downto 0);
    GTX2_TXDATA_IN                         : in   std_logic_vector(15 downto 0);
    GTX3_TXDATA_IN                         : in   std_logic_vector(15 downto 0)
  );

end v6_gtx_wrapper;

architecture Behavioral of v6_gtx_wrapper is
  signal mgt_refclk : std_logic;
  signal mgt_refclk1 : std_logic;
begin

    ----------------------------- The GTX Wrapper -----------------------------
gtx_wizard_4output_v6_i : entity work.gtx_wizard_4output_v6
generic map
(
  WRAPPER_SIM_GTXRESET_SPEEDUP    =>      1
)
port map
(
        --_____________________________________________________________________
        --_____________________________________________________________________
        --GTX0

              ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        GTX0_RXN_IN                     =>      '0',
        GTX0_RXP_IN                     =>      '1',
              ---------------- Transmit Ports - 8b10b Encoder Control Ports --------------
        GTX0_TXCHARISK_IN               =>      GTX0_TXCHARISK_IN,
              ------------------ Transmit Ports - TX Data Path interface -----------------
        GTX0_TXDATA_IN                  =>      GTX0_TXDATA_IN,
        GTX0_TXOUTCLK_OUT               =>      open,
        GTX0_TXUSRCLK2_IN               =>      clock_160,
              ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        GTX0_TXDIFFCTRL_IN              =>      "1101",
        GTX0_TXN_OUT                    =>      TXN_OUT(0),
        GTX0_TXP_OUT                    =>      TXP_OUT(0),
        GTX0_TXPOSTEMPHASIS_IN          =>      "00000",
              --------------- Transmit Ports - TX Driver and OOB signalling --------------
        GTX0_TXPREEMPHASIS_IN           =>      "0000",
              ----------------------- Transmit Ports - TX PLL Ports ----------------------
        GTX0_GTXTXRESET_IN              =>      GTTX_RESET_IN,
        GTX0_MGTREFCLKTX_IN             =>      mgt_refclk,
        GTX0_PLLTXRESET_IN              =>      '0',
        GTX0_TXPLLLKDET_OUT             =>      open,
        GTX0_TXRESETDONE_OUT            =>      open,

        --_____________________________________________________________________
        --_____________________________________________________________________
        --GTX1

              ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        GTX1_RXN_IN                     =>      '0',
        GTX1_RXP_IN                     =>      '1',
              ---------------- Transmit Ports - 8b10b Encoder Control Ports --------------
        GTX1_TXCHARISK_IN               =>      GTX1_TXCHARISK_IN,
              ------------------ Transmit Ports - TX Data Path interface -----------------
        GTX1_TXDATA_IN                  =>      GTX1_TXDATA_IN,
        GTX1_TXOUTCLK_OUT               =>      open,
        GTX1_TXUSRCLK2_IN               =>      clock_160,
              ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        GTX1_TXDIFFCTRL_IN              =>      "1101",
        GTX1_TXN_OUT                    =>      TXN_OUT(1),
        GTX1_TXP_OUT                    =>      TXP_OUT(1),
        GTX1_TXPOSTEMPHASIS_IN          =>      "00000",
              --------------- Transmit Ports - TX Driver and OOB signalling --------------
        GTX1_TXPREEMPHASIS_IN           =>      "0000",
              ----------------------- Transmit Ports - TX PLL Ports ----------------------
        GTX1_GTXTXRESET_IN              =>      GTTX_RESET_IN,
        GTX1_MGTREFCLKTX_IN             =>      mgt_refclk,
        GTX1_PLLTXRESET_IN              =>      '0',
        GTX1_TXPLLLKDET_OUT             =>      open,
        GTX1_TXRESETDONE_OUT            =>      open,

        --_____________________________________________________________________
        --_____________________________________________________________________
        --GTX2

              ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        GTX2_RXN_IN                     =>      '0',
        GTX2_RXP_IN                     =>      '1',
              ---------------- Transmit Ports - 8b10b Encoder Control Ports --------------
        GTX2_TXCHARISK_IN               =>      GTX2_TXCHARISK_IN,
              ------------------ Transmit Ports - TX Data Path interface -----------------
        GTX2_TXDATA_IN                  =>      GTX2_TXDATA_IN,
        GTX2_TXOUTCLK_OUT               =>      open,
        GTX2_TXUSRCLK2_IN               =>      clock_160,
              ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        GTX2_TXDIFFCTRL_IN              =>      "1101",
        GTX2_TXN_OUT                    =>      TXN_OUT(2),
        GTX2_TXP_OUT                    =>      TXP_OUT(2),
        GTX2_TXPOSTEMPHASIS_IN          =>      "00000",
              --------------- Transmit Ports - TX Driver and OOB signalling --------------
        GTX2_TXPREEMPHASIS_IN           =>      "0000",
              ----------------------- Transmit Ports - TX PLL Ports ----------------------
        GTX2_GTXTXRESET_IN              =>      GTTX_RESET_IN,
        GTX2_MGTREFCLKTX_IN             =>      mgt_refclk,
        GTX2_PLLTXRESET_IN              =>      '0',
        GTX2_TXPLLLKDET_OUT             =>      open,
        GTX2_TXRESETDONE_OUT            =>      open,

        --_____________________________________________________________________
        --_____________________________________________________________________
        --GTX3

              ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        GTX3_RXN_IN                     =>      '0',
        GTX3_RXP_IN                     =>      '1',
              ---------------- Transmit Ports - 8b10b Encoder Control Ports --------------
        GTX3_TXCHARISK_IN               =>      GTX3_TXCHARISK_IN,
              ------------------ Transmit Ports - TX Data Path interface -----------------
        GTX3_TXDATA_IN                  =>      GTX3_TXDATA_IN,
        GTX3_TXOUTCLK_OUT               =>      open,
        GTX3_TXUSRCLK2_IN               =>      clock_160,
              ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        GTX3_TXDIFFCTRL_IN              =>      "1101",
        GTX3_TXN_OUT                    =>      TXN_OUT(3),
        GTX3_TXP_OUT                    =>      TXP_OUT(3),
        GTX3_TXPOSTEMPHASIS_IN          =>      "00000",
              --------------- Transmit Ports - TX Driver and OOB signalling --------------
        GTX3_TXPREEMPHASIS_IN           =>      "0000",
              ----------------------- Transmit Ports - TX PLL Ports ----------------------
        GTX3_GTXTXRESET_IN              =>      GTTX_RESET_IN,
        GTX3_MGTREFCLKTX_IN             =>      mgt_refclk,
        GTX3_PLLTXRESET_IN              =>      '0',
        GTX3_TXPLLLKDET_OUT             =>      open,
        GTX3_TXRESETDONE_OUT            =>      open
  );


-----------------------Dedicated GTX Reference Clock Inputs ---------------
-- Each dedicated refclk you are using in your design will need its own IBUFDS_GTXE1 instance

q3_clk0_refclk_ibufds_i : IBUFDS_GTXE1
port map
(
  O                               =>  mgt_refclk,
  ODIV2                           =>  open,
  CEB                             =>  '0',
  I                               =>  refclk_p(0),  -- Connect to package pin P6
  IB                              =>  refclk_n(0)  -- Connect to package pin P5
);

q3_clk1_refclk_ibufds_i : IBUFDS_GTXE1
port map
(
  O                               =>  mgt_refclk1,
  ODIV2                           =>  open,
  CEB                             =>  '0',
  I                               =>  refclk_p(1),
  IB                              =>  refclk_n(1)
);

end Behavioral;
