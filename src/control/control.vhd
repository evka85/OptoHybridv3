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

    -- GBT

    gbt_rxready_i : in std_logic;
    gbt_rxvalid_i : in std_logic;
    gbt_txready_i : in std_logic;

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
    vfat_reset_o : out std_logic;
    ext_sbits_o  : out std_logic_vector(5 downto 0);

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

    signal sbit_sel     : std_logic_vector(29 downto 0);
    signal sbit_mode    : std_logic_vector(1  downto 0);
    signal cluster_rate : std_logic_vector(31  downto 0);

    --== Loopback ==--

    signal loopback  : std_logic_vector(31  downto 0);

    --== TTC FMM ==--

    signal fmm_dont_wait : std_logic;
    signal fmm_trig_stop : std_logic;

    --== TTC Sync ==--

    signal bx0_local : std_logic;

    signal cnt_snap         : std_logic;
    signal cnt_snap_pulse   : std_logic;
    signal cnt_snap_disable : std_logic;

    signal ttc_bxn_offset  : std_logic_vector (11 downto 0);
    signal ttc_bxn_counter : std_logic_vector (11 downto 0);

    signal ttc_bx0_sync_err : std_logic;
    signal ttc_bxn_sync_err : std_logic;

    signal vfat_reset : std_logic;

    signal reset : std_logic;

    signal ext_sbits : std_logic_vector(5 downto 0);

    ------ Register signals begin (this section is generated by <optohybrid_top>/tools/generate_registers.py -- do not edit)
    signal regs_read_arr        : t_std32_array(REG_FPGA_CONTROL_NUM_REGS - 1 downto 0);
    signal regs_write_arr       : t_std32_array(REG_FPGA_CONTROL_NUM_REGS - 1 downto 0);
    signal regs_addresses       : t_std32_array(REG_FPGA_CONTROL_NUM_REGS - 1 downto 0);
    signal regs_defaults        : t_std32_array(REG_FPGA_CONTROL_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_read_pulse_arr  : std_logic_vector(REG_FPGA_CONTROL_NUM_REGS - 1 downto 0);
    signal regs_write_pulse_arr : std_logic_vector(REG_FPGA_CONTROL_NUM_REGS - 1 downto 0);
    signal regs_read_ready_arr  : std_logic_vector(REG_FPGA_CONTROL_NUM_REGS - 1 downto 0) := (others => '1');
    signal regs_write_done_arr  : std_logic_vector(REG_FPGA_CONTROL_NUM_REGS - 1 downto 0) := (others => '1');
    signal regs_writable_arr    : std_logic_vector(REG_FPGA_CONTROL_NUM_REGS - 1 downto 0) := (others => '0');
    -- Connect counter signal declarations
    signal cnt_sem_critical : std_logic_vector (15 downto 0) := (others => '0');
    signal cnt_sem_correction : std_logic_vector (15 downto 0) := (others => '0');
    signal cnt_bx0_lcl : std_logic_vector (23 downto 0) := (others => '0');
    signal cnt_bx0_rxd : std_logic_vector (23 downto 0) := (others => '0');
    signal cnt_l1a : std_logic_vector (15 downto 0) := (others => '0');
    signal cnt_bxn_sync_err : std_logic_vector (15 downto 0) := (others => '0');
    signal cnt_bx0_sync_err : std_logic_vector (15 downto 0) := (others => '0');
    ------ Register signals end ----------------------------------------------

begin

    process (clock_i) begin
        if (rising_edge(clock_i)) then
            reset <= reset_i;
        end if;
    end process;

    trig_stop_o   <= fmm_trig_stop;
    vfat_reset_o  <= vfat_reset;
    ext_sbits_o   <= ext_sbits;
    bxn_counter_o <= ttc_bxn_counter;
    cnt_snap_o    <= cnt_snap;

    -- clock the OR for fanout
    process (clock_i) begin
        if (rising_edge(clock_i)) then
            cnt_snap <= cnt_snap_pulse or cnt_snap_disable;
        end if;
    end process;
    --==============--
    --== Counters ==--
    --==============--

    -- This module implements a multitude of counters.

    -- counters_inst : entity work.counters
    -- port map(
    --     clock               => clock_i,
    --     reset_i             => reset,

    --     -- wishbone
    --     ttc_l1a             => ttc_l1a,
    --     ttc_bc0             => ttc_bc0,
    --     ttc_resync          => ttc_resync,
    --     ttc_bx0_sync_err    => ttc_bx0_sync_err,

    --     sbit_overflow_i     => sbit_overflow_i,

    --     active_vfats_i      => active_vfats_i,

    --     gbt_link_error_i    => gbt_link_error_i,

    --     mmcms_locked_i      => mmcms_locked_i,
    --     eprt_mmcm_locked_i  => eprt_mmcm_locked_i,
    --     dskw_mmcm_locked_i  => dskw_mmcm_locked_i,

    --     sem_correction_i    => sem_correction_i
    -- );

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
        vfat_reset => vfat_reset,

        -- clocks
        clock         => clock_i,
        gbt_eclk      => gbt_clock_i,

        -- signals
        mmcm_locked          => mmcms_locked_i,
        gbt_rxready          => gbt_rxready_i,
        gbt_rxvalid          => gbt_rxvalid_i,

        gbt_request_received => gbt_request_received_i,

        cluster_count        => cluster_count_i,

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

        sys_sbit_mode_i     => sbit_mode,
        sys_sbit_sel_i      => sbit_sel,
        ext_sbits_o         => ext_sbits
    );


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

    -- sem_mon_inst : entity work.sem_mon
    -- port map(
    --     clk_i               => clock_i,
    --     heartbeat_o         => open,
    --     initialization_o    => open,
    --     observation_o       => open,
    --     correction_o        => sem_correction,
    --     classification_o    => open,
    --     injection_o         => open,
    --     essential_o         => open,
    --     uncorrectable_o     => sem_critical
    -- );

    --===============================================================================================
    -- (this section is generated by <optohybrid_top>/tools/generate_registers.py -- do not edit)
    --==== Registers begin ==========================================================================

    -- IPbus slave instanciation
    ipbus_slave_inst : entity work.ipbus_slave
        generic map(
           g_NUM_REGS             => REG_FPGA_CONTROL_NUM_REGS,
           g_ADDR_HIGH_BIT        => REG_FPGA_CONTROL_ADDRESS_MSB,
           g_ADDR_LOW_BIT         => REG_FPGA_CONTROL_ADDRESS_LSB,
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
    regs_addresses(0)(REG_FPGA_CONTROL_ADDRESS_MSB downto REG_FPGA_CONTROL_ADDRESS_LSB) <= "00" & x"0";
    regs_addresses(1)(REG_FPGA_CONTROL_ADDRESS_MSB downto REG_FPGA_CONTROL_ADDRESS_LSB) <= "00" & x"2";
    regs_addresses(2)(REG_FPGA_CONTROL_ADDRESS_MSB downto REG_FPGA_CONTROL_ADDRESS_LSB) <= "00" & x"6";
    regs_addresses(3)(REG_FPGA_CONTROL_ADDRESS_MSB downto REG_FPGA_CONTROL_ADDRESS_LSB) <= "00" & x"a";
    regs_addresses(4)(REG_FPGA_CONTROL_ADDRESS_MSB downto REG_FPGA_CONTROL_ADDRESS_LSB) <= "00" & x"c";
    regs_addresses(5)(REG_FPGA_CONTROL_ADDRESS_MSB downto REG_FPGA_CONTROL_ADDRESS_LSB) <= "00" & x"e";
    regs_addresses(6)(REG_FPGA_CONTROL_ADDRESS_MSB downto REG_FPGA_CONTROL_ADDRESS_LSB) <= "00" & x"f";
    regs_addresses(7)(REG_FPGA_CONTROL_ADDRESS_MSB downto REG_FPGA_CONTROL_ADDRESS_LSB) <= "01" & x"0";
    regs_addresses(8)(REG_FPGA_CONTROL_ADDRESS_MSB downto REG_FPGA_CONTROL_ADDRESS_LSB) <= "01" & x"1";
    regs_addresses(9)(REG_FPGA_CONTROL_ADDRESS_MSB downto REG_FPGA_CONTROL_ADDRESS_LSB) <= "01" & x"2";
    regs_addresses(10)(REG_FPGA_CONTROL_ADDRESS_MSB downto REG_FPGA_CONTROL_ADDRESS_LSB) <= "01" & x"8";
    regs_addresses(11)(REG_FPGA_CONTROL_ADDRESS_MSB downto REG_FPGA_CONTROL_ADDRESS_LSB) <= "01" & x"c";
    regs_addresses(12)(REG_FPGA_CONTROL_ADDRESS_MSB downto REG_FPGA_CONTROL_ADDRESS_LSB) <= "01" & x"d";
    regs_addresses(13)(REG_FPGA_CONTROL_ADDRESS_MSB downto REG_FPGA_CONTROL_ADDRESS_LSB) <= "10" & x"0";
    regs_addresses(14)(REG_FPGA_CONTROL_ADDRESS_MSB downto REG_FPGA_CONTROL_ADDRESS_LSB) <= "10" & x"1";

    -- Connect read signals
    regs_read_arr(0)(REG_FPGA_CONTROL_LOOPBACK_DATA_MSB downto REG_FPGA_CONTROL_LOOPBACK_DATA_LSB) <= loopback;
    regs_read_arr(1)(REG_FPGA_CONTROL_RELEASE_DAY_MSB downto REG_FPGA_CONTROL_RELEASE_DAY_LSB) <= RELEASE_DAY;
    regs_read_arr(1)(REG_FPGA_CONTROL_RELEASE_MONTH_MSB downto REG_FPGA_CONTROL_RELEASE_MONTH_LSB) <= RELEASE_MONTH;
    regs_read_arr(1)(REG_FPGA_CONTROL_RELEASE_YEAR_MSB downto REG_FPGA_CONTROL_RELEASE_YEAR_LSB) <= RELEASE_YEAR;
    regs_read_arr(2)(REG_FPGA_CONTROL_SEM_CNT_SEM_CRITICAL_MSB downto REG_FPGA_CONTROL_SEM_CNT_SEM_CRITICAL_LSB) <= cnt_sem_critical;
    regs_read_arr(2)(REG_FPGA_CONTROL_SEM_CNT_SEM_CORRECTION_MSB downto REG_FPGA_CONTROL_SEM_CNT_SEM_CORRECTION_LSB) <= cnt_sem_correction;
    regs_read_arr(3)(REG_FPGA_CONTROL_VFAT_RESET_BIT) <= vfat_reset;
    regs_read_arr(4)(REG_FPGA_CONTROL_FMM_DONT_WAIT_BIT) <= fmm_dont_wait;
    regs_read_arr(4)(REG_FPGA_CONTROL_FMM_STOP_TRIGGER_BIT) <= fmm_trig_stop;
    regs_read_arr(5)(REG_FPGA_CONTROL_TTC_BX0_CNT_LOCAL_MSB downto REG_FPGA_CONTROL_TTC_BX0_CNT_LOCAL_LSB) <= cnt_bx0_lcl;
    regs_read_arr(6)(REG_FPGA_CONTROL_TTC_BX0_CNT_TTC_MSB downto REG_FPGA_CONTROL_TTC_BX0_CNT_TTC_LSB) <= cnt_bx0_rxd;
    regs_read_arr(7)(REG_FPGA_CONTROL_TTC_BXN_CNT_LOCAL_MSB downto REG_FPGA_CONTROL_TTC_BXN_CNT_LOCAL_LSB) <= ttc_bxn_counter;
    regs_read_arr(7)(REG_FPGA_CONTROL_TTC_BXN_SYNC_ERR_BIT) <= ttc_bxn_sync_err;
    regs_read_arr(7)(REG_FPGA_CONTROL_TTC_BX0_SYNC_ERR_BIT) <= ttc_bx0_sync_err;
    regs_read_arr(7)(REG_FPGA_CONTROL_TTC_BXN_OFFSET_MSB downto REG_FPGA_CONTROL_TTC_BXN_OFFSET_LSB) <= ttc_bxn_offset;
    regs_read_arr(8)(REG_FPGA_CONTROL_TTC_L1A_CNT_MSB downto REG_FPGA_CONTROL_TTC_L1A_CNT_LSB) <= cnt_l1a;
    regs_read_arr(9)(REG_FPGA_CONTROL_TTC_BXN_SYNC_ERR_CNT_MSB downto REG_FPGA_CONTROL_TTC_BXN_SYNC_ERR_CNT_LSB) <= cnt_bxn_sync_err;
    regs_read_arr(9)(REG_FPGA_CONTROL_TTC_BX0_SYNC_ERR_CNT_MSB downto REG_FPGA_CONTROL_TTC_BX0_SYNC_ERR_CNT_LSB) <= cnt_bx0_sync_err;
    regs_read_arr(10)(REG_FPGA_CONTROL_SBITS_CLUSTER_RATE_MSB downto REG_FPGA_CONTROL_SBITS_CLUSTER_RATE_LSB) <= cluster_rate;
    regs_read_arr(11)(REG_FPGA_CONTROL_HDMI_HDMI_OUTPUT_MSB downto REG_FPGA_CONTROL_HDMI_HDMI_OUTPUT_LSB) <= ext_sbits;
    regs_read_arr(11)(REG_FPGA_CONTROL_HDMI_SBIT_SEL_MODE_MSB downto REG_FPGA_CONTROL_HDMI_SBIT_SEL_MODE_LSB) <= sbit_mode;
    regs_read_arr(12)(REG_FPGA_CONTROL_HDMI_SBIT_SEL_MSB downto REG_FPGA_CONTROL_HDMI_SBIT_SEL_LSB) <= sbit_sel;
    regs_read_arr(14)(REG_FPGA_CONTROL_CNT_SNAP_DISABLE_BIT) <= cnt_snap_disable;

    -- Connect write signals
    loopback <= regs_write_arr(0)(REG_FPGA_CONTROL_LOOPBACK_DATA_MSB downto REG_FPGA_CONTROL_LOOPBACK_DATA_LSB);
    vfat_reset <= regs_write_arr(3)(REG_FPGA_CONTROL_VFAT_RESET_BIT);
    fmm_dont_wait <= regs_write_arr(4)(REG_FPGA_CONTROL_FMM_DONT_WAIT_BIT);
    ttc_bxn_offset <= regs_write_arr(7)(REG_FPGA_CONTROL_TTC_BXN_OFFSET_MSB downto REG_FPGA_CONTROL_TTC_BXN_OFFSET_LSB);
    sbit_mode <= regs_write_arr(11)(REG_FPGA_CONTROL_HDMI_SBIT_SEL_MODE_MSB downto REG_FPGA_CONTROL_HDMI_SBIT_SEL_MODE_LSB);
    sbit_sel <= regs_write_arr(12)(REG_FPGA_CONTROL_HDMI_SBIT_SEL_MSB downto REG_FPGA_CONTROL_HDMI_SBIT_SEL_LSB);
    cnt_snap_disable <= regs_write_arr(14)(REG_FPGA_CONTROL_CNT_SNAP_DISABLE_BIT);

    -- Connect write pulse signals
    soft_reset_o <= regs_write_pulse_arr(9);
    cnt_snap_pulse <= regs_write_pulse_arr(13);

    -- Connect write done signals

    -- Connect read pulse signals

    -- Connect counter instances

    COUNTER_FPGA_CONTROL_SEM_CNT_SEM_CRITICAL : entity work.counter
    generic map (g_WIDTH => 16)
    port map (
        ref_clk_i => clock_i,
        snap_i    => cnt_snap,
        reset_i   => reset,
        en_i      => sem_critical,
        data_o    => cnt_sem_critical
    );


    COUNTER_FPGA_CONTROL_SEM_CNT_SEM_CORRECTION : entity work.counter
    generic map (g_WIDTH => 16)
    port map (
        ref_clk_i => clock_i,
        snap_i    => cnt_snap,
        reset_i   => reset,
        en_i      => sem_correction,
        data_o    => cnt_sem_correction
    );


    COUNTER_FPGA_CONTROL_TTC_BX0_CNT_LOCAL : entity work.counter
    generic map (g_WIDTH => 24)
    port map (
        ref_clk_i => clock_i,
        snap_i    => cnt_snap,
        reset_i   => reset,
        en_i      => bx0_local,
        data_o    => cnt_bx0_lcl
    );


    COUNTER_FPGA_CONTROL_TTC_BX0_CNT_TTC : entity work.counter
    generic map (g_WIDTH => 24)
    port map (
        ref_clk_i => clock_i,
        snap_i    => cnt_snap,
        reset_i   => reset,
        en_i      => ttc_bc0,
        data_o    => cnt_bx0_rxd
    );


    COUNTER_FPGA_CONTROL_TTC_L1A_CNT : entity work.counter
    generic map (g_WIDTH => 16)
    port map (
        ref_clk_i => clock_i,
        snap_i    => cnt_snap,
        reset_i   => reset,
        en_i      => ttc_l1a,
        data_o    => cnt_l1a
    );


    COUNTER_FPGA_CONTROL_TTC_BXN_SYNC_ERR_CNT : entity work.counter
    generic map (g_WIDTH => 16)
    port map (
        ref_clk_i => clock_i,
        snap_i    => cnt_snap,
        reset_i   => reset,
        en_i      => ttc_bxn_sync_err,
        data_o    => cnt_bxn_sync_err
    );


    COUNTER_FPGA_CONTROL_TTC_BX0_SYNC_ERR_CNT : entity work.counter
    generic map (g_WIDTH => 16)
    port map (
        ref_clk_i => clock_i,
        snap_i    => cnt_snap,
        reset_i   => reset,
        en_i      => ttc_bx0_sync_err,
        data_o    => cnt_bx0_sync_err
    );

    -- Connect read ready signals

    -- Defaults
    regs_defaults(0)(REG_FPGA_CONTROL_LOOPBACK_DATA_MSB downto REG_FPGA_CONTROL_LOOPBACK_DATA_LSB) <= REG_FPGA_CONTROL_LOOPBACK_DATA_DEFAULT;
    regs_defaults(3)(REG_FPGA_CONTROL_VFAT_RESET_BIT) <= REG_FPGA_CONTROL_VFAT_RESET_DEFAULT;
    regs_defaults(4)(REG_FPGA_CONTROL_FMM_DONT_WAIT_BIT) <= REG_FPGA_CONTROL_FMM_DONT_WAIT_DEFAULT;
    regs_defaults(7)(REG_FPGA_CONTROL_TTC_BXN_OFFSET_MSB downto REG_FPGA_CONTROL_TTC_BXN_OFFSET_LSB) <= REG_FPGA_CONTROL_TTC_BXN_OFFSET_DEFAULT;
    regs_defaults(11)(REG_FPGA_CONTROL_HDMI_SBIT_SEL_MODE_MSB downto REG_FPGA_CONTROL_HDMI_SBIT_SEL_MODE_LSB) <= REG_FPGA_CONTROL_HDMI_SBIT_SEL_MODE_DEFAULT;
    regs_defaults(12)(REG_FPGA_CONTROL_HDMI_SBIT_SEL_MSB downto REG_FPGA_CONTROL_HDMI_SBIT_SEL_LSB) <= REG_FPGA_CONTROL_HDMI_SBIT_SEL_DEFAULT;
    regs_defaults(14)(REG_FPGA_CONTROL_CNT_SNAP_DISABLE_BIT) <= REG_FPGA_CONTROL_CNT_SNAP_DISABLE_DEFAULT;

    -- Define writable regs
    regs_writable_arr(0) <= '1';
    regs_writable_arr(3) <= '1';
    regs_writable_arr(4) <= '1';
    regs_writable_arr(7) <= '1';
    regs_writable_arr(11) <= '1';
    regs_writable_arr(12) <= '1';
    regs_writable_arr(14) <= '1';

    --==== Registers end ============================================================================

end Behavioral;
