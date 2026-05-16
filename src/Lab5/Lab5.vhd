library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_arith;
library unisim;
use unisim.vcomponents.all;
library unimacro;
use unimacro.Vcomponents.all;

entity Lab5 is
    Port (
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        start    : in  STD_LOGIC;
        in_data  : in  std_logic_vector(15 downto 0);
        S_led_o  : out STD_LOGIC;
        R_led_o  : out STD_LOGIC;
       
       
        brst_o   : out STD_LOGIC
    );
end Lab5;

architecture Behavioral of Lab5 is

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

    -- Внутренние сигналы (габариты MMCM, FIFO и отладки)
    signal MMCME_1_buf   : std_logic;
    signal MMCME_2_buf   : std_logic;
    signal locked_buf    : std_logic;
    signal fb_buf        : std_logic;
    signal cl            : std_logic;
    signal c2            : std_logic;
    signal breset, bstart, buf_clk : STD_LOGIC;
    signal reset_z       : STD_LOGIC;
    signal MMCME_1, MMCME_2 : STD_LOGIC := '0';
    signal counter_up    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal buf_counter_out: STD_LOGIC_VECTOR(15 downto 0);
    signal buff_o_data   : std_logic_vector(15 downto 0);
    signal rd_en_in, wr_en_in : std_logic := '0';
    signal o_full, o_empty     : std_logic := '0';
    signal S_led, R_led : STD_LOGIC := '0';
    signal MMCM_LOCKED      : std_logic;
    signal o_data         : std_logic_vector(15 downto 0);
    signal data15         : std_logic_vector(15 downto 0):= (others => '0');
signal debug_dout : std_logic_vector(15 downto 0);

begin

    -- FIFO
    fifo: fifo_generator_0
        port map (
            rst        => reset_z,
            wr_clk     => MMCME_1_buf,
            rd_clk     => MMCME_2_buf,
            din        => data15,
            wr_en      => wr_en_in,
            rd_en      => rd_en_in,
            dout       => o_data,
            full       => o_full,
            empty      => o_empty,
            prog_full  => open,
            prog_empty => open
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

    -- Буферизация входных данных
    form_buffer_fifo_in: for i in 0 to 15 generate
        ibuf_in_data: ibuf_LVTTL
            port map (
                O => buff_o_data(i),
                I => in_data(i)
            );
    end generate;

    BUFG_clk: BUFG port map (O => buf_clk, I => clk);
    BUFG_fb:  BUFG port map (O => cl, I => c2);
    --BUFG_fb2: BUFG port map (O => fb_buf, I => c2);
    reset_ibuf: ibuf port map (O => breset, I => reset);
    start_ibuf: ibuf port map (O => bstart, I => start);
    BUFG_mmcm1: BUFG port map (O => MMCME_1_buf, I => MMCME_1);
    BUFG_mmcm2: BUFG port map (O => MMCME_2_buf, I => MMCME_2);
    --BUFG_locked: BUFG port map (O => locked_buf, I => MMCM_LOCKED);

    -- Сброс
    use_SRL16E: SRL16E
        generic map (INIT => X"0000")
        port map (
            Q   => reset_z,
            A0  => '0', A1 => '0', A2 => '0', A3 => '1',
            CLK => MMCME_2_buf,
            CE  => '1',
            D   => breset
        );

    brst_o <= reset_z;
form_counter: process(MMCME_1_buf, bstart)
    begin
        if bstart='0' then
            data15 <= "0000000000000000" after 2 ns;
        else
            if rising_edge (MMCME_1_buf) then
                data15 <= data15 +'1';
            end if;
        end if;
    end process;
    -- Основной процесс
    process(MMCME_2_buf)
    begin
        if rising_edge(MMCME_2_buf) then
            if (reset_z = '1' AND bstart = '1') then
                counter_up <= counter_up + 1;
                if (counter_up = X"FFFF") then
                    counter_up <= (others => '0');
                end if;
            end if;
            if (reset_z = '0') then
                counter_up <= (others => '0');
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

    -- FIFO управление
    process (o_full, o_empty, MMCME_2_buf, MMCME_1_buf)
    begin
        if rising_edge(MMCME_1_buf) then
            if (o_full = '0' and bstart='1') then
                wr_en_in <= '1' after 2 ns;
            else
                wr_en_in <= '0'after 2 ns;
            end if;
        end if;
        if rising_edge(MMCME_2_buf) then
            if (o_empty = '0') then
                rd_en_in <= '1'after 2 ns;
            else
                rd_en_in <= '0'after 2 ns;
            end if;
        end if;
    end process;

    -- Выходы (только требуемые)
    S_led_o <= S_led;
    R_led_o <= R_led;
debug_dout <= o_data;


   

end Behavioral;
