library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_arith;

entity Lab5_tb is
end Lab5_tb;

architecture Behavioral of Lab5_tb is

    component Lab5 Port (
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        start    : in  STD_LOGIC;
        in_data  : in  std_logic_vector(15 downto 0);
        S_led_o  : out STD_LOGIC;
        R_led_o  : out STD_LOGIC;
        brst_o   : out STD_LOGIC
    );
    end component;

    signal clk      : STD_LOGIC := '0';
    signal reset    : STD_LOGIC;
    signal start    : STD_LOGIC;
    signal reset_z  : STD_LOGIC;   -- brst_o
    signal in_data_sig : std_logic_vector(15 downto 0) := (others => '0');

    -- Сигналы для формирования входных данных (теперь используются без MMCM-выходов)
    signal count      : std_logic_vector(15 downto 0) := (others => '0');
    signal up_down    : std_logic := '0';   -- только инкремент

begin

    dut: Lab5
        port map (
            clk     => clk,
            reset   => reset,
            start   => start,
            in_data => in_data_sig,
            S_led_o => open,   -- или можно оставить сигналом, здесь не используется
            R_led_o => open,
            brst_o  => reset_z
        );

    -- Генерация входных данных: теперь тактируем от clk (100 МГц), как и MMCME_2
    data_in_counter: process (clk)
    begin
        if rising_edge(clk) then
            if up_down = '1' then
                count <= count - 1;
            else
                count <= count + 1;
            end if;
        end if;
    end process;
    in_data_sig <= count;

    -- Тактовый генератор 100 МГц (период 10 нс)
    clock_process: process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process;

    -- Сигнал сброса
   reset_process: process
    begin
        reset <= '0';
     --   wait;
        wait for 360 ns;   -- <-- увеличено с 600 нс до 2000 нс
        reset <= '1';
        wait for 200 ns;
        reset <= '0';
        wait for 1000 ns;
        reset <= '1';
        wait for 200 ns;
        reset <= '0';
       wait for 1000 ns;
        reset <= '1';
        wait;
    end process;

    -- Сигнал старта
    start_process: process
    begin
        start <= '0';
        wait for 360 ns;
        start <= '1';
        wait;
    end process;

end Behavioral;



