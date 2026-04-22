library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Lab4_tb is
end Lab4_tb;

architecture Behavioral of Lab4_tb is

component Lab4    Port ( 
       clk : in STD_LOGIC;
       reset : in STD_LOGIC;
       start : in STD_LOGIC;
       inv_clk : out STD_LOGIC;
    --    half_clk : out STD_LOGIC;
       brst_o : out STD_LOGIC
       );
end component;

signal clk, reset, start, half_clk,inv_clk,reset_z: STD_LOGIC;

begin
dut: Lab4 port map (clk => clk, reset =>reset, start => start, inv_clk => inv_clk, brst_o => reset_z);

clock_process: process
begin
    clk <='0';
    wait for 10 ns;
    clk <='1';
    wait for 10 ns;
end process;

reset_process: process
begin 
    reset <='1';
    wait for 200 ns;
    reset <='0';
    wait for 80 ns;
    reset <='1';
    wait for 1020ns;
    reset <='0';
    wait for 80 ns;
    reset <='1';
    wait;
end process;

start_process: process
begin
    start <='0';
    wait for 360 ns;
    start <='1';
    wait;
end process;
    
end Behavioral;
