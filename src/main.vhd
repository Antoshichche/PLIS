library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_arith;
library unisim;
use unisim.vcomponents.all;
library unimacro;
use unimacro.Vcomponents.all;

entity main is
    Port (
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        start    : in  STD_LOGIC;
        S_led_o  : out STD_LOGIC;
        R_led_o  : out STD_LOGIC
    );
end main;

architecture Behavioral of main is

    component fifo_generator_0 is
        Port (
            rst        : in  STD_LOGIC;
            wr_clk     : in  STD_LOGIC;
            rd_clk     : in  STD_LOGIC;
            din        : in  STD_LOGIC_VECTOR(15 downto 0);
            wr_en      : in  STD_LOGIC;
            rd_en      : in  STD_LOGIC;
            dout       : out STD_LOGIC_VECTOR(15 downto 0);
            full       : out STD_LOGIC;
            empty      : out STD_LOGIC;
            prog_full  : out STD_LOGIC;
            prog_empty : out STD_LOGIC
        );
    end component;

    -- Arch Signals
    -- Clock management
    signal MMCME_1_buf   : std_logic;
    signal MMCME_2_buf   : std_logic;
    signal MMCME_1, MMCME_2 : STD_LOGIC := '0';
    signal MMCM_LOCKED      : std_logic;
    signal fb_buf        : std_logic;
    signal cl            : std_logic;
    signal c2            : std_logic;

    -- FIFO
    signal counter_up    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal o_data         : std_logic_vector(15 downto 0);
    signal buf_counter_out: STD_LOGIC_VECTOR(15 downto 0);
    signal rd_en_in, wr_en_in : std_logic := '0';
    signal o_full, o_empty     : std_logic := '0';
    signal p_full, p_empty     : std_logic := '0';

    -- Globals, utils, set, reset, etc.
    signal breset, bstart, buf_clk : STD_LOGIC := '0';
    signal reset_z       : STD_LOGIC := '0';
    signal n_reset_z       : STD_LOGIC := '1';
    signal S_led, R_led : STD_LOGIC := '0';


begin

    -- FIFO
    fifo: fifo_generator_0
        port map (
            -- EK If reset is 0 work, if 1 disabled. More common way.
            -- In your module if 1, work if 0 disabled.
            -- rst        => reset_z,
            rst        => n_reset_z,
            wr_clk     => MMCME_2_buf,
            rd_clk     => MMCME_1_buf,
            din        => counter_up,
            wr_en      => wr_en_in,
            rd_en      => rd_en_in,
            dout       => o_data,
            full       => o_full,
            empty      => o_empty,
            prog_full  => p_full, -- EK "open" operator for unconnected pins in test benches only
            prog_empty => p_empty
        );

    -- MMCM
    clk_base: MMCM_BASE
        generic map (
            BANDWIDTH        => "OPTIMIZED",
            CLKFBOUT_MULT_F  => 8.0,
            clkin1_period    => 8.0,
            CLKOUT2_DIVIDE   => 8,
            clkout1_phase    => 0.0,
            CLKOUT2_PHASE    => 180.0,
            clkout1_divide   => 16
        )
        port map(
            clkfbin   => cl,
            clkfbout  => c2,
            CLKOUT1   => MMCME_1,
            clkout2   => MMCME_2,
            CLKIN1    => buf_clk,
            PWRDWN    => '0',
            LOCKED    => MMCM_LOCKED,
            RST       => '0'
        );

    -- Buffers
    -- Global
    BUFG_clk: BUFG port map (O => buf_clk, I => clk);
    BUFG_fb:  BUFG port map (O => cl, I => c2);
    BUFG_mmcm1: BUFG port map (O => MMCME_1_buf, I => MMCME_1);
    BUFG_mmcm2: BUFG port map (O => MMCME_2_buf, I => MMCME_2);
    -- Input
    reset_ibuf: ibuf port map (O => breset, I => reset);
    start_ibuf: ibuf port map (O => bstart, I => start);
    -- Output
    sled_obuf : obuf port map (O => S_led_o, I => S_led);
    rled_obuf : obuf port map (O => R_led_o, I => R_led);

    -- 
    use_SRL16E: SRL16E
        generic map (INIT => X"0000")
        port map (
            Q   => reset_z,
            A0  => '0', A1 => '0', A2 => '0', A3 => '1',
            CLK => MMCME_2_buf,
            CE  => '1',
            D   => breset
        );

    -- Start Reset control
    st_rst_ctrl: process(MMCME_2_buf)
    begin
        if rising_edge(MMCME_2_buf) then
            if (reset_z = '1' AND bstart = '1') then
                counter_up <= counter_up + 1;
                -- EK Counter will be overflowed by yourself.
                -- You don't need to control x"FFFF" value.
                -- if (counter_up = X"FFFF") then
                --     counter_up <= (others => '0');
                -- end if;
            else
                counter_up <= (others => '0');
            end if;
        end if;
    end process;

    leds_ctrl: process(MMCME_2_buf)
    begin
        if rising_edge(MMCME_2_buf) then
            if (reset_z = '0') then
                R_led <= '0';
            else
                R_led <= '1';
            end if;
            if (bstart = '1') then
                S_led <= '1';
            else
                S_led <= '0';
            end if;
        end if;
    end process;

    -- FIFO 
    -- process (MMCME_2_buf, MMCME_1_buf) 
    -- EK Two clock domain is one process!
    -- Use Clock Domain Crossing or split you processes.

    fifo_rd_ctrl : process (MMCME_2_buf) 
    begin
        if rising_edge(MMCME_1_buf) then
            if (o_empty = '0') then
                rd_en_in <= '1';
            else
                rd_en_in <= '0';
            end if;
        end if;
    end process;

    fifo_wd_ctrl : process (MMCME_2_buf) 
    begin
        if rising_edge(MMCME_2_buf) then
            if (o_full = '0') then
                wr_en_in <= '1';
            else
                wr_en_in <= '0';
            end if;
        end if;
    end process;

    n_reset_z <= not reset_z;

end Behavioral;
