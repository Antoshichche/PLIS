library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_arith;

entity tb_main is
end tb_main;

architecture Behavioral of tb_main is

    component main Port (
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        start    : in  STD_LOGIC;
        S_led_o  : out STD_LOGIC;
        R_led_o  : out STD_LOGIC
    );
    end component;

    signal clk      : STD_LOGIC := '0';
    signal reset    : STD_LOGIC;
    signal start    : STD_LOGIC;
    signal s_led    : STD_LOGIC;
    signal r_led    : STD_LOGIC;

    -- ������� ��� ������������ ������� ������ (������ ������������ ��� MMCM-�������)
    signal count      : std_logic_vector(15 downto 0) := (others => '0');
    signal up_down    : std_logic := '0';   -- ������ ���������

begin

    stand: main
        port map (
            clk     => clk,
            reset   => reset,
            start   => start,
            S_led_o => s_led,   -- ��� ����� �������� ��������, ����� �� ������������
            R_led_o => r_led
        );

    -- ��������� ������� ������: ������ ��������� �� clk (100 ���), ��� � MMCME_2
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

    -- �������� ��������� 100 ��� (������ 10 ��)
    clock_process: process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process;

    -- ������ ������
   reset_process: process
    begin
        reset <= '0';
     --   wait;
        wait for 360 ns;   -- <-- ��������� � 600 �� �� 2000 ��
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

    -- ������ ������
    start_process: process
    begin
        start <= '0';
        wait for 360 ns;
        start <= '1';
        wait;
    end process;

end Behavioral;

