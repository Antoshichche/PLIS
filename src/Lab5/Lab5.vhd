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
  component ila_0
          Port (
              clk    : in STD_LOGIC;
              probe0 : in STD_LOGIC_VECTOR(15 downto 0);
              probe1 : in STD_LOGIC_VECTOR(0 downto 0);
              probe2 : in STD_LOGIC_VECTOR(0 downto 0);
              probe3 : in STD_LOGIC_VECTOR(0 downto 0);
              probe4 : in STD_LOGIC_VECTOR(3 downto 0)
          );
      end component;
       component ila_1
               Port (
                   clk    : in STD_LOGIC;
                   probe0 : in STD_LOGIC_VECTOR(15 downto 0);
                   probe1 : in STD_LOGIC_VECTOR(0 downto 0);
                   probe2 : in STD_LOGIC_VECTOR(0 downto 0);
                   probe3 : in STD_LOGIC_VECTOR(0 downto 0);
                   probe4 : in STD_LOGIC_VECTOR(3 downto 0)
               );
           end component;
 component vio_0
        Port (
            clk        : in  STD_LOGIC;
            probe_in0  : in  STD_LOGIC;
            probe_in1  : in  STD_LOGIC
           
        );
    end component;

    -- Внутренние сигналы (габариты MMCM, FIFO и отладки)
    signal MMCME_1_buf   : std_logic;
    signal MMCME_2_buf   : std_logic;
    signal clk_100Mhz   : std_logic;
    signal locked_buf    : std_logic;
    signal fb_buf        : std_logic;
    signal idelay_rst        : std_logic;
    signal idelay_rdy       : std_logic :='0';
    signal cl            : std_logic;
    signal c2            : std_logic;
    signal bstart2            : std_logic;
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
signal bstart_sync1 : STD_LOGIC := '0';
signal bstart_sync2 : STD_LOGIC := '0';
signal bstart_meta1  : STD_LOGIC := '0';  -- для двухступенчатой синхронизации
signal bstart_meta2  : STD_LOGIC := '0';
signal clk1_counter : std_logic_vector(25 downto 0) := (others => '0');
signal clk2_counter : std_logic_vector(25 downto 0) := (others => '0');
signal bstart_delay_reg : std_logic_vector(63 downto 0) := (others => '0');  -- 16 тактов задержки
signal bstart_rd_en     : std_logic;
signal fifo_prog_full  : std_logic;
signal fifo_prog_empty : std_logic;
signal o_data_zeroed : std_logic_vector(15 downto 0);
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
            prog_full  => fifo_prog_full,
            prog_empty => fifo_prog_empty
        );

    -- MMCM
    clk_base: MMCM_BASE
        generic map (
            BANDWIDTH        => "OPTIMIZED",
            CLKFBOUT_MULT_F  => 8.0,--
            clkin1_period    => 8.0,
            CLKOUT2_DIVIDE   => 8,
            clkout1_phase    => 0.0,
            CLKOUT2_PHASE    => 180.0,
            CLKOUT0_DIVIDE_F => 10.0,
            clkout1_divide   => 16
        )
        port map(
            clkfbin   => cl,
            clkfbout  => c2,
            CLKOUT1   => MMCME_1,
            clkout2   => MMCME_2,
            CLKIN1    => buf_clk,
            CLKOUT0 => clk_100Mhz,
            PWRDWN    => '0',
            LOCKED    => MMCM_LOCKED,
            RST       => idelay_rst
        );
        -- Вариант 1: прямое подключение входного сброса (после IBUF)
        idelay_rst <= breset;
IDELAYCTRL_inst : IDELAYCTRL
            port map (
                RDY    => idelay_rdy,     -- 1-bit output: Ready output
                REFCLK => clk_100Mhz,      -- 1-bit input: Reference clock input
                RST    => idelay_rst    -- 1-bit input: Active high reset input
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


process(MMCME_2_buf)
begin
    if rising_edge(MMCME_2_buf) then
        if reset_z = '1' then
            bstart_delay_reg <= (others => '0');
        else
            bstart_delay_reg <= bstart_delay_reg(62 downto 0) & bstart_sync2;
        end if;
    end if;
end process;

-- Выходной сигнал - старший бит сдвигового регистра (после 16 тактов)
bstart_rd_en <= bstart_delay_reg(63);



process(MMCME_1_buf)
begin
    if rising_edge(MMCME_1_buf) then
        clk1_counter <= clk1_counter + 1;
    end if;
end process;

process(MMCME_2_buf)
begin
    if rising_edge(MMCME_2_buf) then
        clk2_counter <= clk2_counter + 1;
    end if;
end process;


    -- FIFO управление
     fifo_rd_ctrl : process (MMCME_2_buf, fifo_prog_full, fifo_prog_empty, rd_en_in, bstart_sync2) 
       begin
           if rising_edge(MMCME_2_buf) then
               if (fifo_prog_full = '0' and fifo_prog_empty = '0' and bstart_rd_en = '1') then
                   rd_en_in <= '1';
                elsif (fifo_prog_full = '0' and fifo_prog_empty = '1' ) then
                 rd_en_in <= '0';   
                elsif (fifo_prog_full = '1' and fifo_prog_empty = '0' and bstart_rd_en = '1') then
                   rd_en_in <= '1';
                  elsif (fifo_prog_full = '1' and fifo_prog_empty = '1') then
                   rd_en_in <= '0';
              
               else
                   rd_en_in <= 'U';
               end if;
           end if;
       end process;
   
       fifo_wd_ctrl : process (MMCME_1_buf, fifo_prog_full, fifo_prog_empty, wr_en_in, bstart_sync1) 
       begin
           if rising_edge(MMCME_1_buf) then
               if (fifo_prog_full = '0' and fifo_prog_empty = '0' and bstart_sync1 = '1') then
                   wr_en_in <= '1' after 5 ns;
                elsif (fifo_prog_full = '0' and fifo_prog_empty = '1' and bstart_sync1 = '1') then   
                   wr_en_in <= '1' after 5 ns;
                elsif (fifo_prog_full = '1' and fifo_prog_empty = '0') then   
                   wr_en_in <= '0';
                   elsif (fifo_prog_full = '1' and fifo_prog_empty = '1') then   
                   wr_en_in <= '0';
               else
                   wr_en_in <= 'U';
               end if;
           end if;
       end process;
       
       ------empty = 1, когда нет данных; full = 1, когда нельзя записать.
--rr : process(MMCME_2_buf, MMCME_1_buf)
--variable sist : std_logic :='0';
--begin
--if rising_edge(MMCME_1_buf)then

--bstart <= sist;
--end if;
--if rising_edge(MMCME_2_buf) then
--bstart2 <= sist;

--end if;
--end process;



-- Синхронизация breset в домен MMCME_1_buf (для ILA_1)
process(MMCME_1_buf)
begin
    if rising_edge(MMCME_1_buf) then
        bstart_meta1 <= bstart;
        bstart_sync1 <= bstart_meta1;
    end if;
end process;

-- Синхронизация breset в домен MMCME_2_buf (для ILA_2)
process(MMCME_2_buf)
begin
    if rising_edge(MMCME_2_buf) then
        bstart_meta2 <= bstart;
        bstart_sync2 <= bstart_meta2;
    end if;
end process;
    -- Выходы (только требуемые)
    S_led_o <= S_led;
    R_led_o <= R_led;
debug_dout <= o_data;
o_data_zeroed <= o_data when (fifo_prog_empty = '0') else (others => '0');
 vio_inst: vio_0
        port map (
            clk       => buf_clk,      -- тактовый сигнал (буферизированный)
            probe_in0 => S_led,
            probe_in1 => R_led
          
        );
   ila_mmcm1_inst : ila_0
                port map (
                    clk    => MMCME_1_buf,
                    probe0 => data15,
                    probe1(0) => bstart_sync1,
                     probe2(0) => fifo_prog_full, 
                     probe3(0) => wr_en_in,
                     probe4 => clk1_counter(3 downto 0)
                );
ila_mmcm2_inst : ila_1
                                port map (
                                    clk    => MMCME_2_buf,
                                    probe0 => o_data_zeroed,
                                    probe1(0) => bstart_sync2,
                                     probe2(0) => fifo_prog_empty, 
                                     probe3(0) => rd_en_in,
                                     probe4 => clk2_counter(3 downto 0)
                                );

end Behavioral;


--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.std_logic_arith;
--library unisim;
--use unisim.vcomponents.all;
--library unimacro;
--use unimacro.Vcomponents.all;

--entity Lab5 is
--    Port (
--        clk      : in  STD_LOGIC;
--        reset    : in  STD_LOGIC;
--        start    : in  STD_LOGIC;
--        S_led_o  : out STD_LOGIC;
--        R_led_o  : out STD_LOGIC
--    );
--end Lab5;

--architecture Behavioral of Lab5 is

--    component fifo_generator_0 is
--        Port (
--            rst        : in  STD_LOGIC;
--            wr_clk     : in  STD_LOGIC;
--            rd_clk     : in  STD_LOGIC;
--            din        : in  STD_LOGIC_VECTOR(15 downto 0);
--            wr_en      : in  STD_LOGIC;
--            rd_en      : in  STD_LOGIC;
--            dout       : out STD_LOGIC_VECTOR(15 downto 0);
--            full       : out STD_LOGIC;
--            empty      : out STD_LOGIC;
--            prog_full  : out STD_LOGIC;
--            prog_empty : out STD_LOGIC
--        );
--    end component;

--    -- Arch Signals
--    -- Clock management
--    signal MMCME_1_buf   : std_logic;
--    signal MMCME_2_buf   : std_logic;
--    signal MMCME_1, MMCME_2 : STD_LOGIC := '0';
--    signal MMCM_LOCKED      : std_logic;
--    signal fb_buf        : std_logic;
--    signal cl            : std_logic;
--    signal c2            : std_logic;

--    -- FIFO
--    signal counter_up    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
--    signal o_data         : std_logic_vector(15 downto 0);
--    signal buf_counter_out: STD_LOGIC_VECTOR(15 downto 0);
--    signal rd_en_in, wr_en_in : std_logic := '0';
--    signal o_full, o_empty     : std_logic := '0';
--    signal p_full, p_empty     : std_logic := '0';

--    -- Globals, utils, set, reset, etc.
--    signal breset, bstart, buf_clk : STD_LOGIC := '0';
--    signal reset_z       : STD_LOGIC := '0';
--    signal n_reset_z       : STD_LOGIC := '1';
--    signal S_led, R_led : STD_LOGIC := '0';


--begin

--    -- FIFO
--    fifo: fifo_generator_0
--        port map (
--            -- EK If reset is 0 work, if 1 disabled. More common way.
--            -- In your module if 1, work if 0 disabled.
--            -- rst        => reset_z,
--            rst        => n_reset_z,
--            wr_clk     => MMCME_2_buf,
--            rd_clk     => MMCME_1_buf,
--            din        => counter_up,
--            wr_en      => wr_en_in,
--            rd_en      => rd_en_in,
--            dout       => o_data,
--            full       => o_full,
--            empty      => o_empty,
--            prog_full  => p_full, -- EK "open" operator for unconnected pins in test benches only
--            prog_empty => p_empty
--        );

--    -- MMCM
--    clk_base: MMCM_BASE
--        generic map (
--            BANDWIDTH        => "OPTIMIZED",
--            CLKFBOUT_MULT_F  => 8.0,
--            clkin1_period    => 8.0,
--            CLKOUT2_DIVIDE   => 8,
--            clkout1_phase    => 0.0,
--            CLKOUT2_PHASE    => 180.0,
--            clkout1_divide   => 16
--        )
--        port map(
--            clkfbin   => cl,
--            clkfbout  => c2,
--            CLKOUT1   => MMCME_1,
--            clkout2   => MMCME_2,
--            CLKIN1    => buf_clk,
--            PWRDWN    => '0',
--            LOCKED    => MMCM_LOCKED,
--            RST       => '0'
--        );

--    -- Buffers
--    -- Global
--    BUFG_clk: BUFG port map (O => buf_clk, I => clk);
--    BUFG_fb:  BUFG port map (O => cl, I => c2);
--    BUFG_mmcm1: BUFG port map (O => MMCME_1_buf, I => MMCME_1);
--    BUFG_mmcm2: BUFG port map (O => MMCME_2_buf, I => MMCME_2);
--    -- Input
--    reset_ibuf: ibuf port map (O => breset, I => reset);
--    start_ibuf: ibuf port map (O => bstart, I => start);
--    -- Output
--    sled_obuf : obuf port map (O => S_led_o, I => S_led);
--    rled_obuf : obuf port map (O => R_led_o, I => R_led);

--    -- 
--    use_SRL16E: SRL16E
--        generic map (INIT => X"0000")
--        port map (
--            Q   => reset_z,
--            A0  => '0', A1 => '0', A2 => '0', A3 => '1',
--            CLK => MMCME_2_buf,
--            CE  => '1',
--            D   => breset
--        );

--    -- Start Reset control
--    st_rst_ctrl: process(MMCME_2_buf)
--    begin
--        if rising_edge(MMCME_2_buf) then
--            if (reset_z = '1' AND bstart = '1') then
--                counter_up <= counter_up + 1;
--                -- EK Counter will be overflowed by yourself.
--                -- You don't need to control x"FFFF" value.
--                -- if (counter_up = X"FFFF") then
--                --     counter_up <= (others => '0');
--                -- end if;
--            else
--                counter_up <= (others => '0');
--            end if;
--        end if;
--    end process;

--    leds_ctrl: process(MMCME_2_buf)
--    begin
--        if rising_edge(MMCME_2_buf) then
--            if (reset_z = '0') then
--                R_led <= '0';
--            else
--                R_led <= '1';
--            end if;
--            if (bstart = '1') then
--                S_led <= '1';
--            else
--                S_led <= '0';
--            end if;
--        end if;
--    end process;

--    -- FIFO 
--    -- process (MMCME_2_buf, MMCME_1_buf) 
--    -- EK Two clock domain is one process!
--    -- Use Clock Domain Crossing or split you processes.

--    fifo_rd_ctrl : process (MMCME_2_buf) 
--    begin
--        if rising_edge(MMCME_1_buf) then
--            if (o_empty = '0') then
--                rd_en_in <= '1';
--            else
--                rd_en_in <= '0';
--            end if;
--        end if;
--    end process;

--    fifo_wd_ctrl : process (MMCME_2_buf) 
--    begin
--        if rising_edge(MMCME_2_buf) then
--            if (o_full = '0') then
--                wr_en_in <= '1';
--            else
--                wr_en_in <= '0';
--            end if;
--        end if;
--    end process;

--    n_reset_z <= not reset_z;

--end Behavioral;
