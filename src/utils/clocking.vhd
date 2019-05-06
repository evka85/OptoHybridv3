----------------------------------------------------------------------------------
-- CMS Muon Endcap
-- GEM Collaboration
-- Optohybrid v3 Firmware -- Clocking
-- 2017/07/21 -- Initial port to version 3 electronics
-- 2017/07/22 -- Additional MMCM added to monitor and dejitter the eport clock
-- 2017/08/09 -- 200MHz iodelay refclk added to primary MMCM
-- 2019/05/02 -- Added BUFGCE outputs to disable clocks during MGT init
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.types_pkg.all;
use work.param_pkg.all;
use work.ipbus_pkg.all;
use work.registers.all;

entity clocking is
generic(
    g_ERROR_COUNT_MAX : integer := 4
);
port(

    -- fixed phase 320 MHz e-port clocks
    -- gbt_eclk_p  : in std_logic_vector (1 downto 0);
    -- gbt_eclk_n  : in std_logic_vector (1 downto 0);

    -- programmable frequency/phase deskew clocks
    logic_clock_p : in std_logic;
    logic_clock_n : in std_logic;
    elink_clock_p : in std_logic;
    elink_clock_n : in std_logic;

    gbt_clk40_o      : out std_logic; -- 40 MHz phase shiftable frame clock from GBT
    gbt_clk80_o      : out std_logic; -- 80 MHz phase shiftable frame clock from GBT
    gbt_clk160_0_o   : out std_logic; -- 160 MHz phase shiftable frame clock from GBT
    gbt_clk160_90_o  : out std_logic; -- 160 MHz phase shiftable frame clock from GBT
    gbt_clk160_180_o : out std_logic; -- 160 MHz phase shiftable frame clock from GBT
    gbt_clk320_o     : out std_logic; -- 320 MHz phase shiftable frame clock from GBT

    -- logic clocks
    clk_1x_alwayson_o : out std_logic;
    clk_4x_alwayson_o : out std_logic;

    clk_1x_o          : out std_logic;
    clk_2x_o          : out std_logic;
    clk_4x_o          : out std_logic;
    clk_5x_o          : out std_logic;
    clk_4x_90_o       : out std_logic;

    delay_refclk_o       : out std_logic;
    delay_refclk_reset_o : out std_logic;

    -- mmcm locked status monitors
    dskw_mmcm_locked_o   : out std_logic;
    eprt_mmcm_locked_o   : out std_logic;

    dskw_mmcm_reset_i   : in std_logic;
    eprt_mmcm_reset_i   : in std_logic;

    mmcms_locked_o   : out std_logic;

    clock_enable_i  : in std_logic;

    -- ipbus

    ipb_mosi_i : in  ipb_wbus;
    ipb_miso_o : out ipb_rbus;

    ipb_reset_i : in std_logic;

    cnt_snap : in std_logic

);
end clocking;


architecture Behavioral of clocking is

    signal clk_5x       : std_logic;
    signal gbt_clk160_0 : std_logic;

    signal mmcm_locked : std_logic_vector(1 downto 0);
    signal mmcm_unlocked : std_logic_vector(1 downto 0);

    signal clock : std_logic;

    ------ Register signals begin (this section is generated by <optohybrid_top>/tools/generate_registers.py -- do not edit)
    signal regs_read_arr        : t_std32_array(REG_CLOCKING_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_write_arr       : t_std32_array(REG_CLOCKING_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_addresses       : t_std32_array(REG_CLOCKING_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_defaults        : t_std32_array(REG_CLOCKING_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_read_pulse_arr  : std_logic_vector(REG_CLOCKING_NUM_REGS - 1 downto 0) := (others => '0');
    signal regs_write_pulse_arr : std_logic_vector(REG_CLOCKING_NUM_REGS - 1 downto 0) := (others => '0');
    signal regs_read_ready_arr  : std_logic_vector(REG_CLOCKING_NUM_REGS - 1 downto 0) := (others => '1');
    signal regs_write_done_arr  : std_logic_vector(REG_CLOCKING_NUM_REGS - 1 downto 0) := (others => '1');
    signal regs_writable_arr    : std_logic_vector(REG_CLOCKING_NUM_REGS - 1 downto 0) := (others => '0');
    -- Connect counter signal declarations
    signal cnt_eprt_mmcm_unlocked : std_logic_vector (7 downto 0) := (others => '0');
    signal cnt_dskw_mmcm_unlocked : std_logic_vector (7 downto 0) := (others => '0');
    ------ Register signals end ----------------------------------------------

begin

    clk_1x_o <= clock;

    mmcm_unlocked <= not mmcm_locked;

    clk_5x_o <= clk_5x;
    delay_refclk_o <= clk_5x;


    logic_clocking : entity work.logic_clocking
    port map(

        clk_in1_p   => logic_clock_p,
        clk_in1_n   => logic_clock_n,

        clk40_o     => clock,
        clk80_o     => clk_2x_o,
        clk160_o    => clk_4x_o,
        clk160_90_o => clk_4x_90_o,
        clk200_o    => clk_5x,

        clk40_o_ce     => clock_enable_i,
        clk80_o_ce     => clock_enable_i,
        clk160_o_ce    => clock_enable_i,
        clk160_90_o_ce => clock_enable_i,
        clk200_o_ce    => clock_enable_i,

        clk40_alwayson_o     => clk_1x_alwayson_o,
        clk160_alwayson_o     => clk_4x_alwayson_o,

        locked_o    => mmcm_locked(0)
    );

    gbt_clocking : entity work.gbt_clocking
    port map(

        clk_in1_p    => elink_clock_p,
        clk_in1_n    => elink_clock_n,

        clk40_o      => gbt_clk40_o,
        clk80_o      => gbt_clk80_o,
        clk320_o     => gbt_clk320_o,
        clk160_0_o   => gbt_clk160_0,
        clk160_90_o   => gbt_clk160_90_o,

        clk40_o_ce      => clock_enable_i,
        clk80_o_ce      => clock_enable_i,
        clk320_o_ce     => clock_enable_i,
        clk160_0_o_ce   => clock_enable_i,
        clk160_90_o_ce  => clock_enable_i,

        locked_o      => mmcm_locked(1)
    );

    gbt_clk160_0_o   <=     gbt_clk160_0;
    gbt_clk160_180_o <= not gbt_clk160_0;

    mmcms_locked_o     <= mmcm_locked(0) and mmcm_locked(1);

    dskw_mmcm_locked_o <= mmcm_locked(0);
    eprt_mmcm_locked_o <= mmcm_locked(1);

    delay_refclk_reset_o <= not (mmcm_locked(0));



    --===============================================================================================
    -- (this section is generated by <optohybrid_top>/tools/generate_registers.py -- do not edit)
    --==== Registers begin ==========================================================================

    -- IPbus slave instanciation
    ipbus_slave_inst : entity work.ipbus_slave
        generic map(
           g_NUM_REGS             => REG_CLOCKING_NUM_REGS,
           g_ADDR_HIGH_BIT        => REG_CLOCKING_ADDRESS_MSB,
           g_ADDR_LOW_BIT         => REG_CLOCKING_ADDRESS_LSB,
           g_USE_INDIVIDUAL_ADDRS => true
       )
       port map(
           ipb_reset_i            => ipb_reset_i,
           ipb_clk_i              => clock,
           ipb_mosi_i             => ipb_mosi_i,
           ipb_miso_o             => ipb_miso_o,
           usr_clk_i              => clock,
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
    regs_addresses(0)(REG_CLOCKING_ADDRESS_MSB downto REG_CLOCKING_ADDRESS_LSB) <= "00";

    -- Connect read signals
    regs_read_arr(0)(REG_CLOCKING_GBT_MMCM_LOCKED_BIT) <= mmcm_locked(1);
    regs_read_arr(0)(REG_CLOCKING_LOGIC_MMCM_LOCKED_BIT) <= mmcm_locked(0);
    regs_read_arr(0)(REG_CLOCKING_GBT_MMCM_UNLOCKED_CNT_MSB downto REG_CLOCKING_GBT_MMCM_UNLOCKED_CNT_LSB) <= cnt_eprt_mmcm_unlocked;
    regs_read_arr(0)(REG_CLOCKING_LOGIC_MMCM_UNLOCKED_CNT_MSB downto REG_CLOCKING_LOGIC_MMCM_UNLOCKED_CNT_LSB) <= cnt_dskw_mmcm_unlocked;

    -- Connect write signals

    -- Connect write pulse signals

    -- Connect write done signals

    -- Connect read pulse signals

    -- Connect counter instances

    COUNTER_CLOCKING_GBT_MMCM_UNLOCKED_CNT : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 8
    )
    port map (
        ref_clk_i => clock,
        reset_i   => ipb_reset_i,
        en_i      => mmcm_unlocked(1),
        snap_i    => '1',
        count_o   => cnt_eprt_mmcm_unlocked
    );


    COUNTER_CLOCKING_LOGIC_MMCM_UNLOCKED_CNT : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 8
    )
    port map (
        ref_clk_i => clock,
        reset_i   => ipb_reset_i,
        en_i      => mmcm_unlocked(0),
        snap_i    => '1',
        count_o   => cnt_dskw_mmcm_unlocked
    );


    -- Connect rate instances

    -- Connect read ready signals

    -- Defaults

    -- Define writable regs

    --==== Registers end ============================================================================

end Behavioral;
