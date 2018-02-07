----------------------------------------------------------------------------------
-- CMS Muon Endcap
-- GEM Collaboration
-- Optohybrid v3 Firmware -- GBT
-- A. Peck
----------------------------------------------------------------------------------
-- Description:
--   This module implements all functionality required for communicating with GBTx
----------------------------------------------------------------------------------
-- 2017/07/24 -- Initial. Wrapper around GBT components to simplify top-level
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.types_pkg.all;
use work.ipbus_pkg.all;
use work.registers.all;

entity gbt is
generic(
    DEBUG : boolean := FALSE
);
port(

    reset_i : in std_logic;

    clock_i : in std_logic; -- 40 MHz logic clock

    delay_refclk : in std_logic;
    delay_refclk_reset : in std_logic;

    gbt_rx_clk_div_i : in std_logic; -- 40 MHz phase shiftable frame clock from GBT
    gbt_rx_clk_i     : in std_logic; -- 320 MHz phase shiftable frame clock from GBT

    gbt_tx_clk_div_i : in std_logic_vector (1 downto 0); -- 40 MHz phase shiftable frame clock from GBT
    gbt_tx_clk_i     : in std_logic_vector (1 downto 0); -- 320 MHz phase shiftable frame clock from GBT

    elink_i_p : in  std_logic_vector (1 downto 0);
    elink_i_n : in  std_logic_vector (1 downto 0);

    elink_o_p : out std_logic_vector (1 downto 0);
    elink_o_n : out std_logic_vector (1 downto 0);

    gbt_link_error_o : out std_logic;

    l1a_o         : out std_logic;
    bc0_o         : out std_logic;
    resync_o      : out std_logic;
    reset_vfats_o : out std_logic;

    cnt_snap : in std_logic;

    -- GBTx

    gbt_rxready_i : in std_logic;
    gbt_rxvalid_i : in std_logic;
    gbt_txready_i : in std_logic;

    -- wishbone master
    ipb_mosi_o : out ipb_wbus;
    ipb_miso_i : in  ipb_rbus;

    -- wishbone slave
    ipb_mosi_i : in  ipb_wbus;
    ipb_miso_o : out ipb_rbus;
    ipb_reset_i : in std_logic
);

end gbt;

architecture Behavioral of gbt is

    signal gbt_tx_data  : std_logic_vector(15 downto 0) := (others => '0');
    signal gbt_rx_data   : std_logic_vector(15 downto 0) := (others => '0');

    signal gbt_tx_bitslip0 : std_logic_vector(2 downto 0) ;
    signal gbt_tx_bitslip1: std_logic_vector(2 downto 0) ;

    signal test_pattern : std_logic_vector (63 downto 0);

    signal gbt_link_error : std_logic;
    signal gbt_link_unstable : std_logic;
    signal gbt_link_ready : std_logic;

    signal reset     : std_logic;


    signal tx_delay : std_logic_vector (4 downto 0);
    signal tx_sync_mode : std_logic;

    attribute mark_debug : string;
    attribute mark_debug of tx_sync_mode : signal is "TRUE";

    -- wishbone master
    signal ipb_mosi : ipb_wbus;
    signal ipb_miso : ipb_rbus;

    ------ Register signals begin (this section is generated by <optohybrid_top>/tools/generate_registers.py -- do not edit)
    signal regs_read_arr        : t_std32_array(REG_GBT_NUM_REGS - 1 downto 0);
    signal regs_write_arr       : t_std32_array(REG_GBT_NUM_REGS - 1 downto 0);
    signal regs_addresses       : t_std32_array(REG_GBT_NUM_REGS - 1 downto 0);
    signal regs_defaults        : t_std32_array(REG_GBT_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_read_pulse_arr  : std_logic_vector(REG_GBT_NUM_REGS - 1 downto 0);
    signal regs_write_pulse_arr : std_logic_vector(REG_GBT_NUM_REGS - 1 downto 0);
    signal regs_read_ready_arr  : std_logic_vector(REG_GBT_NUM_REGS - 1 downto 0) := (others => '1');
    signal regs_write_done_arr  : std_logic_vector(REG_GBT_NUM_REGS - 1 downto 0) := (others => '1');
    signal regs_writable_arr    : std_logic_vector(REG_GBT_NUM_REGS - 1 downto 0) := (others => '0');
    -- Connect counter signal declarations
    signal cnt_ipb_response : std_logic_vector (23 downto 0) := (others => '0');
    signal cnt_ipb_request : std_logic_vector (23 downto 0) := (others => '0');
    signal cnt_link_err : std_logic_vector (23 downto 0) := (others => '0');
    ------ Register signals end ----------------------------------------------

begin

    -- wishbone master
    ipb_mosi_o <= ipb_mosi;
    ipb_miso   <= ipb_miso_i;

    -- fanout reset tree

    process (clock_i) begin
        if (rising_edge(clock_i)) then
            reset <= reset_i;
        end if;
    end process;

    --=========--
    --== GBT ==--
    --=========--

    -- at 320 MHz performs ser-des on incoming
    gbt_serdes_inst : entity work.gbt_serdes
    port map(
        -- reset
       reset_i          => reset,

       -- input clocks

       gbt_rx_clk_div_i => gbt_rx_clk_div_i , -- 40 MHz phase shiftable frame clock from GBT
       gbt_rx_clk_i     => gbt_rx_clk_i     , -- 320 MHz phase shiftable frame clock from GBT

       gbt_tx_clk_div_i => gbt_tx_clk_div_i , -- 40 MHz phase shiftable frame clock from GBT
       gbt_tx_clk_i     => gbt_tx_clk_i     , -- 320 MHz phase shiftable frame clock from GBT

       clock            => clock_i,     -- 40 MHz logic clock

       -- serial data
       elink_o_p      => elink_o_p,  -- output e-links
       elink_o_n      => elink_o_n,  -- output e-links

       elink_i_p       => elink_i_p,   -- input e-links
       elink_i_n       => elink_i_n,   -- input e-links

       gbt_link_error_i => gbt_link_error,

       delay_refclk => delay_refclk,
       delay_refclk_reset => delay_refclk_reset,
       tx_delay_i => tx_delay,

       -- gbt tx bitslip

       gbt_tx_bitslip0 => gbt_tx_bitslip0,
       gbt_tx_bitslip1 => gbt_tx_bitslip1,

       tx_sync_mode => tx_sync_mode,
       test_pattern => test_pattern,

       -- parallel data
       data_o           => gbt_rx_data,           -- Parallel data out
       data_i           => gbt_tx_data           -- Parallel data in
    );

    -- decodes GBT frames to build packets

    gbt_link_inst : entity work.gbt_link
    port map(

        -- reset
        reset_i         => reset,

        -- clock inputs
        clock           => clock_i, -- 40 MHz ttc fabric clock

        -- parallel data
        data_i          => gbt_rx_data,
        data_o          => gbt_tx_data,

        -- wishbone master
        ipb_mosi_o    => ipb_mosi,
        ipb_miso_i    => ipb_miso,

        -- decoded TTC
        reset_vfats_o   => reset_vfats_o,
        resync_o        => resync_o,
        l1a_o           => l1a_o,
        bc0_o           => bc0_o,

        -- outputs
        unstable_o      => gbt_link_unstable,
        ready_o         => gbt_link_ready,
        error_o         => gbt_link_error

    );

    --===============================================================================================
    -- (this section is generated by <optohybrid_top>/tools/generate_registers.py -- do not edit)
    --==== Registers begin ==========================================================================

    -- IPbus slave instanciation
    ipbus_slave_inst : entity work.ipbus_slave
        generic map(
           g_NUM_REGS             => REG_GBT_NUM_REGS,
           g_ADDR_HIGH_BIT        => REG_GBT_ADDRESS_MSB,
           g_ADDR_LOW_BIT         => REG_GBT_ADDRESS_LSB,
           g_USE_INDIVIDUAL_ADDRS => true
       )
       port map(
           ipb_reset_i            => ipb_reset_i,
           ipb_clk_i              => clock_i,
           ipb_mosi_i             => ipb_mosi_i,
           ipb_miso_o             => ipb_miso_o,
           usr_clk_i              => clock_i,
           regs_read_arr_i        => regs_read_arr,
           regs_write_arr_o       => regs_write_arr,
           read_pulse_arr_o       => regs_read_pulse_arr,
           write_pulse_arr_o      => regs_write_pulse_arr,
           regs_read_ready_arr_i  => regs_read_ready_arr,
           regs_write_done_arr_i  => regs_write_done_arr,
           individual_addrs_arr_i => regs_addresses,
           regs_defaults_arr_i    => regs_defaults,
           writable_regs_i        => regs_writable_arr
      );

    -- Addresses
    regs_addresses(0)(REG_GBT_ADDRESS_MSB downto REG_GBT_ADDRESS_LSB) <= "000";
    regs_addresses(1)(REG_GBT_ADDRESS_MSB downto REG_GBT_ADDRESS_LSB) <= "001";
    regs_addresses(2)(REG_GBT_ADDRESS_MSB downto REG_GBT_ADDRESS_LSB) <= "010";
    regs_addresses(3)(REG_GBT_ADDRESS_MSB downto REG_GBT_ADDRESS_LSB) <= "011";
    regs_addresses(4)(REG_GBT_ADDRESS_MSB downto REG_GBT_ADDRESS_LSB) <= "100";
    regs_addresses(5)(REG_GBT_ADDRESS_MSB downto REG_GBT_ADDRESS_LSB) <= "101";

    -- Connect read signals
    regs_read_arr(0)(REG_GBT_TX_BITSLIP0_MSB downto REG_GBT_TX_BITSLIP0_LSB) <= gbt_tx_bitslip0;
    regs_read_arr(0)(REG_GBT_TX_BITSLIP1_MSB downto REG_GBT_TX_BITSLIP1_LSB) <= gbt_tx_bitslip1;
    regs_read_arr(0)(REG_GBT_TX_CNT_RESPONSE_SENT_MSB downto REG_GBT_TX_CNT_RESPONSE_SENT_LSB) <= cnt_ipb_response;
    regs_read_arr(1)(REG_GBT_TX_TX_READY_BIT) <= gbt_txready_i;
    regs_read_arr(1)(REG_GBT_TX_SYNC_MODE_BIT) <= tx_sync_mode;
    regs_read_arr(1)(REG_GBT_TX_TX_DELAY_MSB downto REG_GBT_TX_TX_DELAY_LSB) <= tx_delay;
    regs_read_arr(2)(REG_GBT_TX_TEST_PAT0_MSB downto REG_GBT_TX_TEST_PAT0_LSB) <= test_pattern (31 downto 0);
    regs_read_arr(3)(REG_GBT_TX_TEST_PAT1_MSB downto REG_GBT_TX_TEST_PAT1_LSB) <= test_pattern (63 downto 32);
    regs_read_arr(4)(REG_GBT_RX_RX_READY_BIT) <= gbt_rxready_i;
    regs_read_arr(4)(REG_GBT_RX_RX_VALID_BIT) <= gbt_rxvalid_i;
    regs_read_arr(4)(REG_GBT_RX_CNT_REQUEST_RECEIVED_MSB downto REG_GBT_RX_CNT_REQUEST_RECEIVED_LSB) <= cnt_ipb_request;
    regs_read_arr(5)(REG_GBT_RX_CNT_LINK_ERR_MSB downto REG_GBT_RX_CNT_LINK_ERR_LSB) <= cnt_link_err;

    -- Connect write signals
    gbt_tx_bitslip0 <= regs_write_arr(0)(REG_GBT_TX_BITSLIP0_MSB downto REG_GBT_TX_BITSLIP0_LSB);
    gbt_tx_bitslip1 <= regs_write_arr(0)(REG_GBT_TX_BITSLIP1_MSB downto REG_GBT_TX_BITSLIP1_LSB);
    tx_sync_mode <= regs_write_arr(1)(REG_GBT_TX_SYNC_MODE_BIT);
    tx_delay <= regs_write_arr(1)(REG_GBT_TX_TX_DELAY_MSB downto REG_GBT_TX_TX_DELAY_LSB);
    test_pattern (31 downto 0) <= regs_write_arr(2)(REG_GBT_TX_TEST_PAT0_MSB downto REG_GBT_TX_TEST_PAT0_LSB);
    test_pattern (63 downto 32) <= regs_write_arr(3)(REG_GBT_TX_TEST_PAT1_MSB downto REG_GBT_TX_TEST_PAT1_LSB);

    -- Connect write pulse signals

    -- Connect write done signals

    -- Connect read pulse signals

    -- Connect counter instances

    COUNTER_GBT_TX_CNT_RESPONSE_SENT : entity work.counter
    generic map (g_WIDTH => 24)
    port map (
        ref_clk_i => clock_i,
        snap_i    => cnt_snap,
        reset_i   => ipb_reset_i,
        en_i      => ipb_miso.ipb_ack,
        data_o    => cnt_ipb_response
    );


    COUNTER_GBT_RX_CNT_REQUEST_RECEIVED : entity work.counter
    generic map (g_WIDTH => 24)
    port map (
        ref_clk_i => clock_i,
        snap_i    => cnt_snap,
        reset_i   => ipb_reset_i,
        en_i      => ipb_mosi.ipb_strobe,
        data_o    => cnt_ipb_request
    );


    COUNTER_GBT_RX_CNT_LINK_ERR : entity work.counter
    generic map (g_WIDTH => 24)
    port map (
        ref_clk_i => clock_i,
        snap_i    => cnt_snap,
        reset_i   => ipb_reset_i,
        en_i      => (gbt_link_error and gbt_link_ready),
        data_o    => cnt_link_err
    );


    -- Connect rate instances

    -- Connect read ready signals

    -- Defaults
    regs_defaults(0)(REG_GBT_TX_BITSLIP0_MSB downto REG_GBT_TX_BITSLIP0_LSB) <= REG_GBT_TX_BITSLIP0_DEFAULT;
    regs_defaults(0)(REG_GBT_TX_BITSLIP1_MSB downto REG_GBT_TX_BITSLIP1_LSB) <= REG_GBT_TX_BITSLIP1_DEFAULT;
    regs_defaults(1)(REG_GBT_TX_SYNC_MODE_BIT) <= REG_GBT_TX_SYNC_MODE_DEFAULT;
    regs_defaults(1)(REG_GBT_TX_TX_DELAY_MSB downto REG_GBT_TX_TX_DELAY_LSB) <= REG_GBT_TX_TX_DELAY_DEFAULT;
    regs_defaults(2)(REG_GBT_TX_TEST_PAT0_MSB downto REG_GBT_TX_TEST_PAT0_LSB) <= REG_GBT_TX_TEST_PAT0_DEFAULT;
    regs_defaults(3)(REG_GBT_TX_TEST_PAT1_MSB downto REG_GBT_TX_TEST_PAT1_LSB) <= REG_GBT_TX_TEST_PAT1_DEFAULT;

    -- Define writable regs
    regs_writable_arr(0) <= '1';
    regs_writable_arr(1) <= '1';
    regs_writable_arr(2) <= '1';
    regs_writable_arr(3) <= '1';

    --==== Registers end ============================================================================
end Behavioral;
