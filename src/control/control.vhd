----------------------------------------------------------------------------------
-- CMS Muon Endcap
-- GEM Collaboration
-- Optohybrid v3 Firmware -- Control
-- A. Peck
----------------------------------------------------------------------------------
-- 2017/07/25 -- Initial. Wrapper around OH control modules
-- 2017/07/25 -- Clear many synthesis warnings from module
-- 2017/11/14 -- Overhaul with XML derived controls
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

use IEEE.Numeric_STD.all;

library work;
use work.types_pkg.all;
use work.ipbus_pkg.all;
use work.param_pkg.all;
use work.registers.all;

entity control is
port(


    --== TTC ==--

    clock_i     : in std_logic;
    gbt_clock_i : in std_logic;
    reset_i     : in std_logic;

    ttc_l1a    : in std_logic;
    ttc_bc0    : in std_logic;
    ttc_resync : in std_logic;

    ipb_mosi_i : in  ipb_wbus;
    ipb_miso_o : out ipb_rbus;

    -------------------
    -- status inputs --
    -------------------

    -- MMCM
    mmcms_locked_i     : in std_logic;
    dskw_mmcm_locked_i : in std_logic;
    eprt_mmcm_locked_i : in std_logic;

    -- SCA Control

    sca_ctl                 : in  std_logic_vector (2 downto 0);

    tx_sync_mode_sca_o      : out std_logic;
    gbt_loopback_mode_sca_o : out std_logic;

    -- GBT

    gbt_rxready_i    : in std_logic;
    gbt_link_ready_i : in std_logic;
    gbt_rxvalid_i    : in std_logic;
    gbt_txready_i    : in std_logic;

    gbt_rx_data_i  : in std_logic_vector (15 downto 0);

    -- Trigger

    active_vfats_i  : in std_logic_vector (23 downto 0);
    sbit_overflow_i : in std_logic;
    cluster_count_i : in std_logic_vector (7 downto 0);

    -- GBT
    gbt_link_error_i       : in std_logic;
    gbt_request_received_i : in std_logic;

    -- Analog input
    adc_vp : in  std_logic;
    adc_vn : in  std_logic;

    --------------------
    -- config outputs --
    --------------------

    -- VFAT
    vfat_reset_o : out std_logic_vector (11 downto 0);
    ext_sbits_o  : out std_logic_vector(7 downto 0);

    -- LEDs
    led_o              : out std_logic_vector(15 downto 0);

    -- pulse to synchronously snap all counters for readout
    -- freeze high to make counters transparent (asynchronous readout)
    cnt_snap_o : out std_logic;

    soft_reset_o : out std_logic;

    -------------
    -- outputs --
    -------------

    trig_stop_o   : out std_logic;
    bxn_counter_o : out std_logic_vector (11 downto 0)

);

end control;

architecture Behavioral of control is


    --== SEM ==--

    signal sem_correction : std_logic;
    signal sem_critical   : std_logic;
    --== Sbits ==--

    signal sbit_sel0    : std_logic_vector(4 downto 0);
    signal sbit_sel1    : std_logic_vector(4 downto 0);
    signal sbit_sel2    : std_logic_vector(4 downto 0);
    signal sbit_sel3    : std_logic_vector(4 downto 0);
    signal sbit_sel4    : std_logic_vector(4 downto 0);
    signal sbit_sel5    : std_logic_vector(4 downto 0);
    signal sbit_sel6    : std_logic_vector(4 downto 0);
    signal sbit_sel7    : std_logic_vector(4 downto 0);

    signal sbit_mode0   : std_logic_vector(1  downto 0);
    signal sbit_mode1   : std_logic_vector(1  downto 0);
    signal sbit_mode2   : std_logic_vector(1  downto 0);
    signal sbit_mode3   : std_logic_vector(1  downto 0);
    signal sbit_mode4   : std_logic_vector(1  downto 0);
    signal sbit_mode5   : std_logic_vector(1  downto 0);
    signal sbit_mode6   : std_logic_vector(1  downto 0);
    signal sbit_mode7   : std_logic_vector(1  downto 0);

    signal cluster_rate : std_logic_vector(31  downto 0);

    --== SCA Control ==--

    signal tx_sync_mode_sca      : std_logic;
    signal gbt_loopback_mode_sca : std_logic;
    signal led_sync_mode_sca     : std_logic;

    --== Loopback ==--

    signal loopback  : std_logic_vector(31  downto 0);

    --== TTC FMM ==--

    signal fmm_dont_wait : std_logic;
    signal fmm_trig_stop : std_logic;

    --== TTC Sync ==--

    signal bx0_local : std_logic;
    attribute mark_debug : string;
    attribute mark_debug of bx0_local : signal is "TRUE";

    signal cnt_snap         : std_logic;
    signal cnt_snap_pulse   : std_logic;
    signal cnt_snap_disable : std_logic;

    signal ttc_bxn_offset  : std_logic_vector (11 downto 0);
    signal ttc_bxn_counter : std_logic_vector (11 downto 0);

    signal ttc_bx0_sync_err : std_logic;
    signal ttc_bxn_sync_err : std_logic;

    signal vfat_startup_reset : std_logic_vector (11 downto 0);
    signal vfat_startup_reset_timer : unsigned (31 downto 0);
    signal vfat_startup_reset_timer_max : natural := 32;
    signal vfat_reset : std_logic_vector (11 downto 0);

    signal reset : std_logic;
    signal cnt_reset : std_logic;

    ------ Register signals begin (this section is generated by <optohybrid_top>/tools/generate_registers.py -- do not edit)
    signal regs_read_arr        : t_std32_array(REG_CONTROL_NUM_REGS - 1 downto 0);
    signal regs_write_arr       : t_std32_array(REG_CONTROL_NUM_REGS - 1 downto 0);
    signal regs_addresses       : t_std32_array(REG_CONTROL_NUM_REGS - 1 downto 0);
    signal regs_defaults        : t_std32_array(REG_CONTROL_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_read_pulse_arr  : std_logic_vector(REG_CONTROL_NUM_REGS - 1 downto 0);
    signal regs_write_pulse_arr : std_logic_vector(REG_CONTROL_NUM_REGS - 1 downto 0);
    signal regs_read_ready_arr  : std_logic_vector(REG_CONTROL_NUM_REGS - 1 downto 0) := (others => '1');
    signal regs_write_done_arr  : std_logic_vector(REG_CONTROL_NUM_REGS - 1 downto 0) := (others => '1');
    signal regs_writable_arr    : std_logic_vector(REG_CONTROL_NUM_REGS - 1 downto 0) := (others => '0');
    -- Connect counter signal declarations
    signal cnt_sem_critical : std_logic_vector (15 downto 0) := (others => '0');
    signal cnt_sem_correction : std_logic_vector (15 downto 0) := (others => '0');
    signal cnt_bx0_lcl : std_logic_vector (23 downto 0) := (others => '0');
    signal cnt_bx0_rxd : std_logic_vector (23 downto 0) := (others => '0');
    signal cnt_l1a : std_logic_vector (23 downto 0) := (others => '0');
    signal cnt_bxn_sync_err : std_logic_vector (15 downto 0) := (others => '0');
    signal cnt_bx0_sync_err : std_logic_vector (15 downto 0) := (others => '0');
    ------ Register signals end ----------------------------------------------

    begin

    process (clock_i) begin
        if (rising_edge(clock_i)) then

            -- startup timer; count to max then deassert the startup reset
            if (reset_i = '1') then
                vfat_startup_reset_timer <= (others => '0');
            elsif (vfat_startup_reset_timer < vfat_startup_reset_timer_max) then
                vfat_startup_reset_timer <= vfat_startup_reset_timer + 1;
            end if;

            if (vfat_startup_reset_timer < vfat_startup_reset_timer_max) then
                vfat_startup_reset <= (others => '1');
            else
                vfat_startup_reset <= (others => '0');
            end if;

        end if;
    end process;

    process (clock_i) begin
        if (rising_edge(clock_i)) then
            reset <= reset_i;
            cnt_reset <= reset_i or ttc_resync;
        end if;
    end process;

    trig_stop_o   <= fmm_trig_stop;
    vfat_reset_o  <= vfat_reset or vfat_startup_reset;
    bxn_counter_o <= ttc_bxn_counter;
    cnt_snap_o    <= cnt_snap;

    -- clock the OR for fanout
    process (clock_i) begin
        if (rising_edge(clock_i)) then
            cnt_snap <= cnt_snap_pulse or cnt_snap_disable;
        end if;
    end process;

    --==========--
    --== LEDS ==--
    --==========--

    led_control : entity work.led_control
    port map (
        -- reset
        reset         => reset,

        -- ttc commands

        ttc_l1a => ttc_l1a,
        ttc_bc0 => ttc_bc0,
        ttc_resync => ttc_resync,
        vfat_reset => or_reduce(vfat_reset),

        -- clocks
        clock         => clock_i,
        gbt_eclk      => gbt_clock_i,

        -- gbt sync mode

        gbt_rx_data_i        => gbt_rx_data_i,
        led_sync_mode_i      => led_sync_mode_sca,

        -- signals
        mmcm_locked          => mmcms_locked_i,
        gbt_rxready          => gbt_rxready_i,
        gbt_link_ready       => gbt_link_ready_i,
        gbt_rxvalid          => gbt_rxvalid_i,

        gbt_request_received => gbt_request_received_i,

        cluster_count_i      => cluster_count_i,

        cluster_rate  => cluster_rate,

        -- led outputs
        led_out       => led_o
    );


    --======================--
    --== External signals ==--
    --======================--

    -- This module handles the external signals: the input trigger and the output SBits.

    external_inst : entity work.external
    port map(
        clock               => clock_i,

        reset_i             => reset,

        active_vfats_i      => active_vfats_i,

        sbit_mode0 => sbit_mode0,
        sbit_mode1 => sbit_mode1,
        sbit_mode2 => sbit_mode2,
        sbit_mode3 => sbit_mode3,
        sbit_mode4 => sbit_mode4,
        sbit_mode5 => sbit_mode5,
        sbit_mode6 => sbit_mode6,
        sbit_mode7 => sbit_mode7,

        sbit_sel0 => sbit_sel0,
        sbit_sel1 => sbit_sel1,
        sbit_sel2 => sbit_sel2,
        sbit_sel3 => sbit_sel3,
        sbit_sel4 => sbit_sel4,
        sbit_sel5 => sbit_sel5,
        sbit_sel6 => sbit_sel6,
        sbit_sel7 => sbit_sel7,

        ext_sbits_o         => ext_sbits_o
    );

    --=================--
    --== SCA Control ==--
    --=================--

    sca_control_inst : entity work.sca_control
    port map (

    clock             => clock_i,

    reset_i           => reset,

    sca_ctl           => sca_ctl,

    tx_sync_mode      => tx_sync_mode_sca,
    gbt_loopback_mode => gbt_loopback_mode_sca,
    led_sync_mode     => led_sync_mode_sca

    );

    tx_sync_mode_sca_o      <= tx_sync_mode_sca;
    gbt_loopback_mode_sca_o <= gbt_loopback_mode_sca;

    --=================--
    --== TTC Sync    ==--
    --=================--

    ttc_inst : entity work.ttc

    port map (

        -- clock & reset
        clock => clock_i,
        reset => reset,

        -- ttc commands
        ttc_bx0     => ttc_bc0,
        bx0_local   => bx0_local,
        ttc_resync  => ttc_resync,

        -- control
        bxn_offset => ttc_bxn_offset,

        -- output
       bxn_counter     => ttc_bxn_counter,
       bx0_sync_err    => ttc_bx0_sync_err,
       bxn_sync_err    => ttc_bxn_sync_err

    );

    --=================--
    --== Trigger FMM ==--
    --=================--

    fmm_inst : entity work.fmm
    port map (

        -- clock & reset
        clock   => clock_i,
        reset_i => reset,

        -- ttc commands
        ttc_bx0    => ttc_bc0,
        ttc_resync => ttc_resync,

        -- control

        dont_wait  => fmm_dont_wait,

        -- output
        fmm_trig_stop => fmm_trig_stop

    );

    --=========--
    --== SEM ==--
    --=========--

    sem_mon_inst : entity work.sem_mon
    port map(
        clk_i               => clock_i,
        heartbeat_o         => open,
        initialization_o    => open,
        observation_o       => open,
        correction_o        => sem_correction,
        classification_o    => open,
        injection_o         => open,
        essential_o         => open,
        uncorrectable_o     => sem_critical
    );

    --===============================================================================================
    -- (this section is generated by <optohybrid_top>/tools/generate_registers.py -- do not edit)
    --==== Registers begin ==========================================================================

    -- IPbus slave instanciation
    ipbus_slave_inst : entity work.ipbus_slave
        generic map(
           g_NUM_REGS             => REG_CONTROL_NUM_REGS,
           g_ADDR_HIGH_BIT        => REG_CONTROL_ADDRESS_MSB,
           g_ADDR_LOW_BIT         => REG_CONTROL_ADDRESS_LSB,
           g_USE_INDIVIDUAL_ADDRS => true
       )
       port map(
           ipb_reset_i            => reset,
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
    regs_addresses(0)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "00" & x"0";
    regs_addresses(1)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "00" & x"2";
    regs_addresses(2)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "00" & x"5";
    regs_addresses(3)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "00" & x"6";
    regs_addresses(4)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "00" & x"a";
    regs_addresses(5)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "00" & x"c";
    regs_addresses(6)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "00" & x"e";
    regs_addresses(7)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "00" & x"f";
    regs_addresses(8)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "01" & x"0";
    regs_addresses(9)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "01" & x"1";
    regs_addresses(10)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "01" & x"2";
    regs_addresses(11)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "01" & x"8";
    regs_addresses(12)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "01" & x"c";
    regs_addresses(13)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "01" & x"d";
    regs_addresses(14)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "10" & x"0";
    regs_addresses(15)(REG_CONTROL_ADDRESS_MSB downto REG_CONTROL_ADDRESS_LSB) <= "10" & x"1";

    -- Connect read signals
    regs_read_arr(0)(REG_CONTROL_LOOPBACK_DATA_MSB downto REG_CONTROL_LOOPBACK_DATA_LSB) <= loopback;
    regs_read_arr(1)(REG_CONTROL_RELEASE_DATE_MSB downto REG_CONTROL_RELEASE_DATE_LSB) <= (RELEASE_YEAR & RELEASE_MONTH & RELEASE_DAY);
    regs_read_arr(2)(REG_CONTROL_RELEASE_VERSION_MAJOR_MSB downto REG_CONTROL_RELEASE_VERSION_MAJOR_LSB) <= (MAJOR_VERSION);
    regs_read_arr(2)(REG_CONTROL_RELEASE_VERSION_MINOR_MSB downto REG_CONTROL_RELEASE_VERSION_MINOR_LSB) <= (MINOR_VERSION);
    regs_read_arr(2)(REG_CONTROL_RELEASE_VERSION_BUILD_MSB downto REG_CONTROL_RELEASE_VERSION_BUILD_LSB) <= (RELEASE_VERSION);
    regs_read_arr(2)(REG_CONTROL_RELEASE_VERSION_GENERATION_MSB downto REG_CONTROL_RELEASE_VERSION_GENERATION_LSB) <= (RELEASE_HARDWARE);
    regs_read_arr(3)(REG_CONTROL_SEM_CNT_SEM_CRITICAL_MSB downto REG_CONTROL_SEM_CNT_SEM_CRITICAL_LSB) <= cnt_sem_critical;
    regs_read_arr(3)(REG_CONTROL_SEM_CNT_SEM_CORRECTION_MSB downto REG_CONTROL_SEM_CNT_SEM_CORRECTION_LSB) <= cnt_sem_correction;
    regs_read_arr(4)(REG_CONTROL_VFAT_RESET_MSB downto REG_CONTROL_VFAT_RESET_LSB) <= vfat_reset(11 downto 0);
    regs_read_arr(5)(REG_CONTROL_FMM_DONT_WAIT_BIT) <= fmm_dont_wait;
    regs_read_arr(5)(REG_CONTROL_FMM_STOP_TRIGGER_BIT) <= fmm_trig_stop;
    regs_read_arr(6)(REG_CONTROL_TTC_BX0_CNT_LOCAL_MSB downto REG_CONTROL_TTC_BX0_CNT_LOCAL_LSB) <= cnt_bx0_lcl;
    regs_read_arr(7)(REG_CONTROL_TTC_BX0_CNT_TTC_MSB downto REG_CONTROL_TTC_BX0_CNT_TTC_LSB) <= cnt_bx0_rxd;
    regs_read_arr(8)(REG_CONTROL_TTC_BXN_CNT_LOCAL_MSB downto REG_CONTROL_TTC_BXN_CNT_LOCAL_LSB) <= ttc_bxn_counter;
    regs_read_arr(8)(REG_CONTROL_TTC_BXN_SYNC_ERR_BIT) <= ttc_bxn_sync_err;
    regs_read_arr(8)(REG_CONTROL_TTC_BX0_SYNC_ERR_BIT) <= ttc_bx0_sync_err;
    regs_read_arr(8)(REG_CONTROL_TTC_BXN_OFFSET_MSB downto REG_CONTROL_TTC_BXN_OFFSET_LSB) <= ttc_bxn_offset;
    regs_read_arr(9)(REG_CONTROL_TTC_L1A_CNT_MSB downto REG_CONTROL_TTC_L1A_CNT_LSB) <= cnt_l1a;
    regs_read_arr(10)(REG_CONTROL_TTC_BXN_SYNC_ERR_CNT_MSB downto REG_CONTROL_TTC_BXN_SYNC_ERR_CNT_LSB) <= cnt_bxn_sync_err;
    regs_read_arr(10)(REG_CONTROL_TTC_BX0_SYNC_ERR_CNT_MSB downto REG_CONTROL_TTC_BX0_SYNC_ERR_CNT_LSB) <= cnt_bx0_sync_err;
    regs_read_arr(11)(REG_CONTROL_SBITS_CLUSTER_RATE_MSB downto REG_CONTROL_SBITS_CLUSTER_RATE_LSB) <= cluster_rate;
    regs_read_arr(12)(REG_CONTROL_HDMI_SBIT_SEL0_MSB downto REG_CONTROL_HDMI_SBIT_SEL0_LSB) <= sbit_sel0;
    regs_read_arr(12)(REG_CONTROL_HDMI_SBIT_SEL1_MSB downto REG_CONTROL_HDMI_SBIT_SEL1_LSB) <= sbit_sel1;
    regs_read_arr(12)(REG_CONTROL_HDMI_SBIT_SEL2_MSB downto REG_CONTROL_HDMI_SBIT_SEL2_LSB) <= sbit_sel2;
    regs_read_arr(12)(REG_CONTROL_HDMI_SBIT_SEL3_MSB downto REG_CONTROL_HDMI_SBIT_SEL3_LSB) <= sbit_sel3;
    regs_read_arr(12)(REG_CONTROL_HDMI_SBIT_SEL4_MSB downto REG_CONTROL_HDMI_SBIT_SEL4_LSB) <= sbit_sel4;
    regs_read_arr(12)(REG_CONTROL_HDMI_SBIT_SEL5_MSB downto REG_CONTROL_HDMI_SBIT_SEL5_LSB) <= sbit_sel5;
    regs_read_arr(13)(REG_CONTROL_HDMI_SBIT_SEL6_MSB downto REG_CONTROL_HDMI_SBIT_SEL6_LSB) <= sbit_sel6;
    regs_read_arr(13)(REG_CONTROL_HDMI_SBIT_SEL7_MSB downto REG_CONTROL_HDMI_SBIT_SEL7_LSB) <= sbit_sel7;
    regs_read_arr(13)(REG_CONTROL_HDMI_SBIT_MODE0_MSB downto REG_CONTROL_HDMI_SBIT_MODE0_LSB) <= sbit_mode0;
    regs_read_arr(13)(REG_CONTROL_HDMI_SBIT_MODE1_MSB downto REG_CONTROL_HDMI_SBIT_MODE1_LSB) <= sbit_mode1;
    regs_read_arr(13)(REG_CONTROL_HDMI_SBIT_MODE2_MSB downto REG_CONTROL_HDMI_SBIT_MODE2_LSB) <= sbit_mode2;
    regs_read_arr(13)(REG_CONTROL_HDMI_SBIT_MODE3_MSB downto REG_CONTROL_HDMI_SBIT_MODE3_LSB) <= sbit_mode3;
    regs_read_arr(13)(REG_CONTROL_HDMI_SBIT_MODE4_MSB downto REG_CONTROL_HDMI_SBIT_MODE4_LSB) <= sbit_mode4;
    regs_read_arr(13)(REG_CONTROL_HDMI_SBIT_MODE5_MSB downto REG_CONTROL_HDMI_SBIT_MODE5_LSB) <= sbit_mode5;
    regs_read_arr(13)(REG_CONTROL_HDMI_SBIT_MODE6_MSB downto REG_CONTROL_HDMI_SBIT_MODE6_LSB) <= sbit_mode6;
    regs_read_arr(13)(REG_CONTROL_HDMI_SBIT_MODE7_MSB downto REG_CONTROL_HDMI_SBIT_MODE7_LSB) <= sbit_mode7;
    regs_read_arr(15)(REG_CONTROL_CNT_SNAP_DISABLE_BIT) <= cnt_snap_disable;

    -- Connect write signals
    loopback <= regs_write_arr(0)(REG_CONTROL_LOOPBACK_DATA_MSB downto REG_CONTROL_LOOPBACK_DATA_LSB);
    vfat_reset(11 downto 0) <= regs_write_arr(4)(REG_CONTROL_VFAT_RESET_MSB downto REG_CONTROL_VFAT_RESET_LSB);
    fmm_dont_wait <= regs_write_arr(5)(REG_CONTROL_FMM_DONT_WAIT_BIT);
    ttc_bxn_offset <= regs_write_arr(8)(REG_CONTROL_TTC_BXN_OFFSET_MSB downto REG_CONTROL_TTC_BXN_OFFSET_LSB);
    sbit_sel0 <= regs_write_arr(12)(REG_CONTROL_HDMI_SBIT_SEL0_MSB downto REG_CONTROL_HDMI_SBIT_SEL0_LSB);
    sbit_sel1 <= regs_write_arr(12)(REG_CONTROL_HDMI_SBIT_SEL1_MSB downto REG_CONTROL_HDMI_SBIT_SEL1_LSB);
    sbit_sel2 <= regs_write_arr(12)(REG_CONTROL_HDMI_SBIT_SEL2_MSB downto REG_CONTROL_HDMI_SBIT_SEL2_LSB);
    sbit_sel3 <= regs_write_arr(12)(REG_CONTROL_HDMI_SBIT_SEL3_MSB downto REG_CONTROL_HDMI_SBIT_SEL3_LSB);
    sbit_sel4 <= regs_write_arr(12)(REG_CONTROL_HDMI_SBIT_SEL4_MSB downto REG_CONTROL_HDMI_SBIT_SEL4_LSB);
    sbit_sel5 <= regs_write_arr(12)(REG_CONTROL_HDMI_SBIT_SEL5_MSB downto REG_CONTROL_HDMI_SBIT_SEL5_LSB);
    sbit_sel6 <= regs_write_arr(13)(REG_CONTROL_HDMI_SBIT_SEL6_MSB downto REG_CONTROL_HDMI_SBIT_SEL6_LSB);
    sbit_sel7 <= regs_write_arr(13)(REG_CONTROL_HDMI_SBIT_SEL7_MSB downto REG_CONTROL_HDMI_SBIT_SEL7_LSB);
    sbit_mode0 <= regs_write_arr(13)(REG_CONTROL_HDMI_SBIT_MODE0_MSB downto REG_CONTROL_HDMI_SBIT_MODE0_LSB);
    sbit_mode1 <= regs_write_arr(13)(REG_CONTROL_HDMI_SBIT_MODE1_MSB downto REG_CONTROL_HDMI_SBIT_MODE1_LSB);
    sbit_mode2 <= regs_write_arr(13)(REG_CONTROL_HDMI_SBIT_MODE2_MSB downto REG_CONTROL_HDMI_SBIT_MODE2_LSB);
    sbit_mode3 <= regs_write_arr(13)(REG_CONTROL_HDMI_SBIT_MODE3_MSB downto REG_CONTROL_HDMI_SBIT_MODE3_LSB);
    sbit_mode4 <= regs_write_arr(13)(REG_CONTROL_HDMI_SBIT_MODE4_MSB downto REG_CONTROL_HDMI_SBIT_MODE4_LSB);
    sbit_mode5 <= regs_write_arr(13)(REG_CONTROL_HDMI_SBIT_MODE5_MSB downto REG_CONTROL_HDMI_SBIT_MODE5_LSB);
    sbit_mode6 <= regs_write_arr(13)(REG_CONTROL_HDMI_SBIT_MODE6_MSB downto REG_CONTROL_HDMI_SBIT_MODE6_LSB);
    sbit_mode7 <= regs_write_arr(13)(REG_CONTROL_HDMI_SBIT_MODE7_MSB downto REG_CONTROL_HDMI_SBIT_MODE7_LSB);
    cnt_snap_disable <= regs_write_arr(15)(REG_CONTROL_CNT_SNAP_DISABLE_BIT);

    -- Connect write pulse signals
    soft_reset_o <= regs_write_pulse_arr(10);
    cnt_snap_pulse <= regs_write_pulse_arr(14);

    -- Connect write done signals

    -- Connect read pulse signals

    -- Connect counter instances

    COUNTER_CONTROL_SEM_CNT_SEM_CRITICAL : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 16
    )
    port map (
        ref_clk_i => clock_i,
        reset_i   => reset,
        en_i      => sem_critical,
        snap_i    => cnt_snap,
        count_o   => cnt_sem_critical
    );


    COUNTER_CONTROL_SEM_CNT_SEM_CORRECTION : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 16
    )
    port map (
        ref_clk_i => clock_i,
        reset_i   => reset,
        en_i      => sem_correction,
        snap_i    => cnt_snap,
        count_o   => cnt_sem_correction
    );


    COUNTER_CONTROL_TTC_BX0_CNT_LOCAL : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 24
    )
    port map (
        ref_clk_i => clock_i,
        reset_i   => cnt_reset,
        en_i      => bx0_local,
        snap_i    => cnt_snap,
        count_o   => cnt_bx0_lcl
    );


    COUNTER_CONTROL_TTC_BX0_CNT_TTC : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 24
    )
    port map (
        ref_clk_i => clock_i,
        reset_i   => cnt_reset,
        en_i      => ttc_bc0,
        snap_i    => cnt_snap,
        count_o   => cnt_bx0_rxd
    );


    COUNTER_CONTROL_TTC_L1A_CNT : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 24
    )
    port map (
        ref_clk_i => clock_i,
        reset_i   => cnt_reset,
        en_i      => ttc_l1a,
        snap_i    => cnt_snap,
        count_o   => cnt_l1a
    );


    COUNTER_CONTROL_TTC_BXN_SYNC_ERR_CNT : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 16
    )
    port map (
        ref_clk_i => clock_i,
        reset_i   => cnt_reset,
        en_i      => ttc_bxn_sync_err,
        snap_i    => cnt_snap,
        count_o   => cnt_bxn_sync_err
    );


    COUNTER_CONTROL_TTC_BX0_SYNC_ERR_CNT : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 16
    )
    port map (
        ref_clk_i => clock_i,
        reset_i   => cnt_reset,
        en_i      => ttc_bx0_sync_err,
        snap_i    => cnt_snap,
        count_o   => cnt_bx0_sync_err
    );


    -- Connect rate instances

    -- Connect read ready signals

    -- Defaults
    regs_defaults(0)(REG_CONTROL_LOOPBACK_DATA_MSB downto REG_CONTROL_LOOPBACK_DATA_LSB) <= REG_CONTROL_LOOPBACK_DATA_DEFAULT;
    regs_defaults(4)(REG_CONTROL_VFAT_RESET_MSB downto REG_CONTROL_VFAT_RESET_LSB) <= REG_CONTROL_VFAT_RESET_DEFAULT;
    regs_defaults(5)(REG_CONTROL_FMM_DONT_WAIT_BIT) <= REG_CONTROL_FMM_DONT_WAIT_DEFAULT;
    regs_defaults(8)(REG_CONTROL_TTC_BXN_OFFSET_MSB downto REG_CONTROL_TTC_BXN_OFFSET_LSB) <= REG_CONTROL_TTC_BXN_OFFSET_DEFAULT;
    regs_defaults(12)(REG_CONTROL_HDMI_SBIT_SEL0_MSB downto REG_CONTROL_HDMI_SBIT_SEL0_LSB) <= REG_CONTROL_HDMI_SBIT_SEL0_DEFAULT;
    regs_defaults(12)(REG_CONTROL_HDMI_SBIT_SEL1_MSB downto REG_CONTROL_HDMI_SBIT_SEL1_LSB) <= REG_CONTROL_HDMI_SBIT_SEL1_DEFAULT;
    regs_defaults(12)(REG_CONTROL_HDMI_SBIT_SEL2_MSB downto REG_CONTROL_HDMI_SBIT_SEL2_LSB) <= REG_CONTROL_HDMI_SBIT_SEL2_DEFAULT;
    regs_defaults(12)(REG_CONTROL_HDMI_SBIT_SEL3_MSB downto REG_CONTROL_HDMI_SBIT_SEL3_LSB) <= REG_CONTROL_HDMI_SBIT_SEL3_DEFAULT;
    regs_defaults(12)(REG_CONTROL_HDMI_SBIT_SEL4_MSB downto REG_CONTROL_HDMI_SBIT_SEL4_LSB) <= REG_CONTROL_HDMI_SBIT_SEL4_DEFAULT;
    regs_defaults(12)(REG_CONTROL_HDMI_SBIT_SEL5_MSB downto REG_CONTROL_HDMI_SBIT_SEL5_LSB) <= REG_CONTROL_HDMI_SBIT_SEL5_DEFAULT;
    regs_defaults(13)(REG_CONTROL_HDMI_SBIT_SEL6_MSB downto REG_CONTROL_HDMI_SBIT_SEL6_LSB) <= REG_CONTROL_HDMI_SBIT_SEL6_DEFAULT;
    regs_defaults(13)(REG_CONTROL_HDMI_SBIT_SEL7_MSB downto REG_CONTROL_HDMI_SBIT_SEL7_LSB) <= REG_CONTROL_HDMI_SBIT_SEL7_DEFAULT;
    regs_defaults(13)(REG_CONTROL_HDMI_SBIT_MODE0_MSB downto REG_CONTROL_HDMI_SBIT_MODE0_LSB) <= REG_CONTROL_HDMI_SBIT_MODE0_DEFAULT;
    regs_defaults(13)(REG_CONTROL_HDMI_SBIT_MODE1_MSB downto REG_CONTROL_HDMI_SBIT_MODE1_LSB) <= REG_CONTROL_HDMI_SBIT_MODE1_DEFAULT;
    regs_defaults(13)(REG_CONTROL_HDMI_SBIT_MODE2_MSB downto REG_CONTROL_HDMI_SBIT_MODE2_LSB) <= REG_CONTROL_HDMI_SBIT_MODE2_DEFAULT;
    regs_defaults(13)(REG_CONTROL_HDMI_SBIT_MODE3_MSB downto REG_CONTROL_HDMI_SBIT_MODE3_LSB) <= REG_CONTROL_HDMI_SBIT_MODE3_DEFAULT;
    regs_defaults(13)(REG_CONTROL_HDMI_SBIT_MODE4_MSB downto REG_CONTROL_HDMI_SBIT_MODE4_LSB) <= REG_CONTROL_HDMI_SBIT_MODE4_DEFAULT;
    regs_defaults(13)(REG_CONTROL_HDMI_SBIT_MODE5_MSB downto REG_CONTROL_HDMI_SBIT_MODE5_LSB) <= REG_CONTROL_HDMI_SBIT_MODE5_DEFAULT;
    regs_defaults(13)(REG_CONTROL_HDMI_SBIT_MODE6_MSB downto REG_CONTROL_HDMI_SBIT_MODE6_LSB) <= REG_CONTROL_HDMI_SBIT_MODE6_DEFAULT;
    regs_defaults(13)(REG_CONTROL_HDMI_SBIT_MODE7_MSB downto REG_CONTROL_HDMI_SBIT_MODE7_LSB) <= REG_CONTROL_HDMI_SBIT_MODE7_DEFAULT;
    regs_defaults(15)(REG_CONTROL_CNT_SNAP_DISABLE_BIT) <= REG_CONTROL_CNT_SNAP_DISABLE_DEFAULT;

    -- Define writable regs
    regs_writable_arr(0) <= '1';
    regs_writable_arr(4) <= '1';
    regs_writable_arr(5) <= '1';
    regs_writable_arr(8) <= '1';
    regs_writable_arr(12) <= '1';
    regs_writable_arr(13) <= '1';
    regs_writable_arr(15) <= '1';

    --==== Registers end ============================================================================

end Behavioral;
