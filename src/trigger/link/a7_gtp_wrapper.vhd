------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Version : 3.6
--  \   \         Application : 7 Series FPGAs Transceivers Wizard
--  /   /         Filename : a7_gtp_wrapper.vhd
-- /___/   /\
-- \   \  /  \
--  \___\/\___\
--
--
-- Module a7_gtp_wrapper
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

entity a7_gtp_wrapper is
  port
  (
    Q0_CLK0_GTREFCLK_PAD_N_IN               : in   std_logic;
    Q0_CLK0_GTREFCLK_PAD_P_IN               : in   std_logic;
    Q0_CLK1_GTREFCLK_PAD_N_IN               : in   std_logic;
    Q0_CLK1_GTREFCLK_PAD_P_IN               : in   std_logic;
    sysclk_in                               : in   std_logic;
    soft_reset_tx_in                        : in std_logic;
    PLL_LOCK_OUT                            : out  std_logic;
    TXN_OUT                                 : out  std_logic_vector(3 downto 0);
    TXP_OUT                                 : out  std_logic_vector(3 downto 0);

    tx_fsm_reset_done                       : out std_logic_vector (3 downto 0);

    gt0_txcharisk_i                         : in   std_logic_vector(1 downto 0);
    gt1_txcharisk_i                         : in   std_logic_vector(1 downto 0);
    gt2_txcharisk_i                         : in   std_logic_vector(1 downto 0);
    gt3_txcharisk_i                         : in   std_logic_vector(1 downto 0);

    gt0_txdata_i                         : in   std_logic_vector(15 downto 0);
    gt1_txdata_i                         : in   std_logic_vector(15 downto 0);
    gt2_txdata_i                         : in   std_logic_vector(15 downto 0);
    gt3_txdata_i                         : in   std_logic_vector(15 downto 0);

    gt0_txusrclk_o                      : out   std_logic;
    gt1_txusrclk_o                      : out   std_logic;
    gt2_txusrclk_o                      : out   std_logic;
    gt3_txusrclk_o                      : out   std_logic
  );

end a7_gtp_wrapper;

architecture RTL of a7_gtp_wrapper is

  --GT0  (X0Y0)

  --------------- Transmit Ports - TX Configurable Driver Ports --------------
  signal  gt0_txdiffctrl_i                : std_logic_vector(3 downto 0);

  --GT1  (X0Y1)

  --------------- Transmit Ports - TX Configurable Driver Ports --------------
  signal  gt1_txdiffctrl_i                : std_logic_vector(3 downto 0);

  --GT2  (X0Y2)

  --------------- Transmit Ports - TX Configurable Driver Ports --------------
  signal  gt2_txdiffctrl_i                : std_logic_vector(3 downto 0);

  --GT3  (X0Y3)

  --------------- Transmit Ports - TX Configurable Driver Ports --------------
  signal  gt3_txdiffctrl_i                : std_logic_vector(3 downto 0);

  attribute keep: string;


begin

  ------------ optional Ports assignments --------------
  gt0_txdiffctrl_i                             <= "1100";
  gt1_txdiffctrl_i                             <= "1100";
  gt2_txdiffctrl_i                             <= "1100";
  gt3_txdiffctrl_i                             <= "1100";
  ------------------------------------------------------

  ----------------------------- The GT Wrapper -----------------------------

  -- Use the instantiation template in the example directory to add the GT wrapper to your design.
  -- In this example, the wrapper is wired up for basic operation with a frame generator and frame
  -- checker. The GTs will reset, then attempt to align and transmit data. If channel bonding is
  -- enabled, bonding should occur after alignment
  -- While connecting the GT TX/RX Reset ports below, please add a delay of
  -- minimum 500ns as mentioned in AR 43482.

  a7_mgts_with_buffer0_support_i : entity work.a7_mgts_with_buffer0
  port map
  (
    soft_reset_tx_in            => soft_reset_tx_in,
    DONT_RESET_ON_DATA_ERROR_IN => '0',
    Q0_CLK0_GTREFCLK_PAD_N_IN   => Q0_CLK0_GTREFCLK_PAD_N_IN,
    Q0_CLK0_GTREFCLK_PAD_P_IN   => Q0_CLK0_GTREFCLK_PAD_P_IN,
    Q0_CLK1_GTREFCLK_PAD_N_IN   => Q0_CLK1_GTREFCLK_PAD_N_IN,
    Q0_CLK1_GTREFCLK_PAD_P_IN   => Q0_CLK1_GTREFCLK_PAD_P_IN,
    GT0_TX_FSM_RESET_DONE_OUT   => tx_fsm_reset_done(0),
    GT0_RX_FSM_RESET_DONE_OUT   => open,
    GT0_DATA_VALID_IN           => '0',
    GT1_TX_FSM_RESET_DONE_OUT   => tx_fsm_reset_done(1),
    GT1_RX_FSM_RESET_DONE_OUT   => open,
    GT1_DATA_VALID_IN           => '0',
    GT2_TX_FSM_RESET_DONE_OUT   => tx_fsm_reset_done(2),
    GT2_RX_FSM_RESET_DONE_OUT   => open,
    GT2_DATA_VALID_IN           => '0',
    GT3_TX_FSM_RESET_DONE_OUT   => tx_fsm_reset_done(3),
    GT3_RX_FSM_RESET_DONE_OUT   => open,
    GT3_DATA_VALID_IN           => '0',

    GT0_TXUSRCLK_OUT => gt0_txusrclk_o,
    GT1_TXUSRCLK_OUT => gt1_txusrclk_o,
    GT2_TXUSRCLK_OUT => gt2_txusrclk_o,
    GT3_TXUSRCLK_OUT => gt3_txusrclk_o,

    --_____________________________________________________________________
    --_____________________________________________________________________
    --GT0  (X0Y0)

    ---------------------------- Channel - DRP Ports  --------------------------
    gt0_drpaddr_in                  =>      (others => '0'),
    gt0_drpdi_in                    =>      (others => '0'),
    gt0_drpdo_out                   =>      open,
    gt0_drpen_in                    =>      '0',
    gt0_drprdy_out                  =>      open,
    gt0_drpwe_in                    =>      '0',
    --------------------- RX Initialization and Reset Ports --------------------
    gt0_eyescanreset_in             =>      '0',
    -------------------------- RX Margin Analysis Ports ------------------------
    gt0_eyescandataerror_out        =>      open,
    gt0_eyescantrigger_in           =>      '0',
    ------------ Receive Ports - RX Decision Feedback Equalizer(DFE) -----------
    gt0_dmonitorout_out             =>      open,
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt0_gtrxreset_in                =>      '0',
    gt0_rxlpmreset_in               =>      '0',
    --------------------- TX Initialization and Reset Ports --------------------
    gt0_gttxreset_in                =>      '0', -- not internally connected
    gt0_txuserrdy_in                =>      '0', -- not internally connected
    ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
    gt0_txdata_in                   =>      gt0_txdata_i,
    ------------------ Transmit Ports - TX 8B/10B Encoder Ports ----------------
    gt0_txcharisk_in                =>      gt0_txcharisk_i,
    --------------- Transmit Ports - TX Configurable Driver Ports --------------
    gt0_gtptxn_out                  =>      TXN_OUT(0),
    gt0_gtptxp_out                  =>      TXP_OUT(0),
    --gt0_txdiffctrl_in               =>      gt0_txdiffctrl_i,
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt0_txoutclkfabric_out          =>      open,
    gt0_txoutclkpcs_out             =>      open,
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt0_txresetdone_out             =>      open,


    --_____________________________________________________________________
    --_____________________________________________________________________
    --GT1  (X0Y1)

    ---------------------------- Channel - DRP Ports  --------------------------
    gt1_drpaddr_in                  =>      (others => '0'),
    gt1_drpdi_in                    =>      (others => '0'),
    gt1_drpdo_out                   =>      open,
    gt1_drpen_in                    =>      '0',
    gt1_drprdy_out                  =>      open,
    gt1_drpwe_in                    =>      '0',
    --------------------- RX Initialization and Reset Ports --------------------
    gt1_eyescanreset_in             =>      '0',
    -------------------------- RX Margin Analysis Ports ------------------------
    gt1_eyescandataerror_out        =>      open,
    gt1_eyescantrigger_in           =>      '0',
    ------------ Receive Ports - RX Decision Feedback Equalizer(DFE) -----------
    gt1_dmonitorout_out             =>      open,
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt1_gtrxreset_in                =>      '0',
    gt1_rxlpmreset_in               =>      '0',
    --------------------- TX Initialization and Reset Ports --------------------
    gt1_gttxreset_in                =>      '0', -- not internally connected
    gt1_txuserrdy_in                =>      '0', -- not internally connected
    ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
    gt1_txdata_in                   =>      gt1_txdata_i,
    ------------------ Transmit Ports - TX 8B/10B Encoder Ports ----------------
    gt1_txcharisk_in                =>      gt1_txcharisk_i,
    --------------- Transmit Ports - TX Configurable Driver Ports --------------
    gt1_gtptxn_out                  =>      TXN_OUT(1),
    gt1_gtptxp_out                  =>      TXP_OUT(1),
    --gt1_txdiffctrl_in               =>      gt1_txdiffctrl_i,
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt1_txoutclkfabric_out          =>      open,
    gt1_txoutclkpcs_out             =>      open,
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt1_txresetdone_out             =>      open,


    --_____________________________________________________________________
    --_____________________________________________________________________
    --GT2  (X0Y2)

    ---------------------------- Channel - DRP Ports  --------------------------
    gt2_drpaddr_in                  =>      (others => '0'),
    gt2_drpdi_in                    =>      (others => '0'),
    gt2_drpdo_out                   =>      open,
    gt2_drpen_in                    =>      '0',
    gt2_drprdy_out                  =>      open,
    gt2_drpwe_in                    =>      '0',
    --------------------- RX Initialization and Reset Ports --------------------
    gt2_eyescanreset_in             =>      '0',
    -------------------------- RX Margin Analysis Ports ------------------------
    gt2_eyescandataerror_out        =>      open,
    gt2_eyescantrigger_in           =>      '0',
    ------------ Receive Ports - RX Decision Feedback Equalizer(DFE) -----------
    gt2_dmonitorout_out             =>      open,
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt2_gtrxreset_in                =>      '0',
    gt2_rxlpmreset_in               =>      '0',
    --------------------- TX Initialization and Reset Ports --------------------
    gt2_gttxreset_in                =>      '0', -- not internally connected
    gt2_txuserrdy_in                =>      '0', -- not internally connected
    ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
    gt2_txdata_in                   =>      gt2_txdata_i,
    ------------------ Transmit Ports - TX 8B/10B Encoder Ports ----------------
    gt2_txcharisk_in                =>      gt2_txcharisk_i,
    --------------- Transmit Ports - TX Configurable Driver Ports --------------
    gt2_gtptxn_out                  =>      TXN_OUT(2),
    gt2_gtptxp_out                  =>      TXP_OUT(2),
    --gt2_txdiffctrl_in               =>      gt2_txdiffctrl_i,
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt2_txoutclkfabric_out          =>      open,
    gt2_txoutclkpcs_out             =>      open,
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt2_txresetdone_out             =>      open,


    --_____________________________________________________________________
    --_____________________________________________________________________
    --GT3  (X0Y3)

    ---------------------------- Channel - DRP Ports  --------------------------
    gt3_drpaddr_in                  =>      (others => '0'),
    gt3_drpdi_in                    =>      (others => '0'),
    gt3_drpdo_out                   =>      open,
    gt3_drpen_in                    =>      '0',
    gt3_drprdy_out                  =>      open,
    gt3_drpwe_in                    =>      '0',
    --------------------- RX Initialization and Reset Ports --------------------
    gt3_eyescanreset_in             =>      '0',
    -------------------------- RX Margin Analysis Ports ------------------------
    gt3_eyescandataerror_out        =>      open,
    gt3_eyescantrigger_in           =>      '0',
    ------------ Receive Ports - RX Decision Feedback Equalizer(DFE) -----------
    gt3_dmonitorout_out             =>      open,
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt3_gtrxreset_in                =>      '0',
    gt3_rxlpmreset_in               =>      '0',
    --------------------- TX Initialization and Reset Ports --------------------
    gt3_gttxreset_in                =>      '0', -- not internally connected
    gt3_txuserrdy_in                =>      '0', -- not internally connected
    ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
    gt3_txdata_in                   =>      gt3_txdata_i,
    ------------------ Transmit Ports - TX 8B/10B Encoder Ports ----------------
    gt3_txcharisk_in                =>      gt3_txcharisk_i,
    --------------- Transmit Ports - TX Configurable Driver Ports --------------
    gt3_gtptxn_out                  =>      TXN_OUT(3),
    gt3_gtptxp_out                  =>      TXP_OUT(3),
    --gt3_txdiffctrl_in               =>      gt3_txdiffctrl_i,
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt3_txoutclkfabric_out          =>      open,
    gt3_txoutclkpcs_out             =>      open,
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt3_txresetdone_out             =>      open,

    GT0_DRPADDR_COMMON_IN => "00000000",
    GT0_DRPDI_COMMON_IN   => "0000000000000000",
    GT0_DRPDO_COMMON_OUT  => open,
    GT0_DRPEN_COMMON_IN   => '0',
    GT0_DRPRDY_COMMON_OUT => open,
    GT0_DRPWE_COMMON_IN   => '0',

    --____________________________COMMON PORTS________________________________
    GT0_PLL0OUTCLK_OUT     => open,
    GT0_PLL0OUTREFCLK_OUT  => open,
    GT0_PLL0LOCK_OUT       => PLL_LOCK_OUT,
    GT0_PLL0REFCLKLOST_OUT => open,
    GT0_PLL1OUTCLK_OUT     => open,
    GT0_PLL1OUTREFCLK_OUT  => open,
    sysclk_in              => sysclk_in
  );


end RTL;



