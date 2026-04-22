library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;          
library unisim;
use unisim.vcomponents.all;

entity Lab4 is
    Port (
           clk      : in  STD_LOGIC;
           reset    : in  STD_LOGIC;   -- ������ 1 (BTN1)
           start    : in  STD_LOGIC;   -- ������ 2 (BTN2)
           
           inv_clk  : out STD_LOGIC;
           half_clk : out STD_LOGIC;
           brst_o   : out STD_LOGIC;
      
           
           led_o    : out STD_LOGIC    
           );
end Lab4;

architecture Behavioral of Lab4 is

    -- ================== ���������� ������� ==================
    signal breset, bstart, buf_clk     : STD_LOGIC;
    signal bhalf_clk, binv_clk         : STD_LOGIC;
    signal reset_z                     : STD_LOGIC;
    
    -- ��� ������� ~0.5 ��� (125 ��� * 0.5 = 62 500 000)
    signal blink_cnt : unsigned(25 downto 0) := (others => '0');
    signal led_reg   : STD_LOGIC := '0';
-- �������������� ������: ���������� ������� �� ������ start
        signal blink_enable : STD_LOGIC := '0';
        
    
    signal clk_enable : STD_LOGIC := '0';
    signal clk_1 : STD_LOGIC := '0';

    signal mmcm_clk_0 : STD_LOGIC := '0';
    signal mmcm_fbin : STD_LOGIC := '0';
    signal mmcm_fbout : STD_LOGIC := '0';
    signal mmcm_locked : STD_LOGIC := '0';

    signal idelay_rst   : STD_LOGIC := '0';
    signal idelay_rdy_i : STD_LOGIC := '0';
    signal rst_sync     : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal rdy_sync     : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal rst_cnt      : UNSIGNED(3 downto 0) := "0000";
    signal idelay_ctrl_rdy : STD_LOGIC;
       
begin

    -- ================== MMCM  ==================
    clk_base: MMCM_BASE
    generic map (
        BANDWIDTH        => "OPTIMIZED",
        CLKFBOUT_MULT_F  => 8.0,          -- 
        clkin1_period    => 8.0,          --  8.0 ��� 125 ���
        CLKOUT0_DIVIDE_F => 4.0,    -- 250 fpr reset and idelay
        clkout0_phase    => 0.0,
        CLKOUT1_PHASE    => -90.0,
        clkout1_divide   => 8            -- inv_clk ����� 250 ���
    )
    port map(
        clkfbin  => mmcm_fbin,
        clkfbout  => mmcm_fbout,
        CLKOUT0  => mmcm_clk_0,
        clkout1  => clk_1,
        CLKIN1   => buf_clk,
        LOCKED   => mmcm_locked,
        PWRDWN   => '0',
        RST      => '0'
    );

    mmcm_fbin <= mmcm_fbout;

    process(mmcm_clk_0)
        begin
            if rising_edge(mmcm_clk_0) then
                rst_sync <= rst_sync(0) & (not mmcm_locked);
                if rst_sync(1) = '1' then
                    rst_cnt <= (others => '0');
                    idelay_rst <= '1';
                elsif rst_cnt < 7 then  -- 7 cycles > 5 cycle minimum
                    rst_cnt <= rst_cnt + 1;
                    idelay_rst <= '1';
                else
                    idelay_rst <= '0';
                end if;
            end if;
    end process;

    IDELAYCTRL_INST : IDELAYCTRL
    port map (
        REFCLK  => mmcm_clk_0,
        RST     => idelay_rst,
        RDY     => idelay_rdy_i
    );

    process(clk_1)
        begin
            if rising_edge(clk_1) then
                if breset = '1' then
                    rdy_sync <= rdy_sync(1 downto 0) & idelay_rdy_i;
                else
                    rdy_sync <= "000";
                end if;
            end if;
    end process;

    clk_enable <= rdy_sync(2) and rdy_sync(1);

    BUFGCE_INST : BUFGCE
    port map (
        I  => clk_1,
        CE => clk_enable,
        O  => binv_clk
    );
    
    obuf_inv_clk:  obuf port map ( O => inv_clk,  I => binv_clk );
    -- obuf_half_clk: obuf port map ( O => half_clk, I => bhalf_clk );

    BUFG_clk: BUFG port map ( O => buf_clk, I => clk );

    reset_ibuf: ibuf port map ( O => breset, I => reset );
    start_ibuf: ibuf port map ( O => bstart, I => start );

    -- 
    use_SRL16E: SRL16E
        generic map (INIT => X"0000")
        port map (
            Q   => reset_z,
            A0  => '0', A1 => '0', A2 => '0', A3 => '1',
            CLK => binv_clk,
            CE  => '1',
            D   => breset
        );

    brst_o  <= reset_z;
    
    process(binv_clk)
        begin
            if rising_edge(binv_clk) then
    
                -- ������ reset ������ ��������� ��
                if reset_z = '1' then
                    led_reg      <= '0';
                    blink_cnt    <= (others => '0');
                    blink_enable <= '0';
    
                else
                    -- ������ start �������� ��� ������� (��������/��������� �������)
                    if bstart = '1' then
                        blink_enable <= '1';
                    end if;
    
                    -- ���� ������� ��������� - ������
                    if blink_enable = '1' then
                        blink_cnt <= blink_cnt + 1;
                        if blink_cnt = 62499999 then        -- ~0.5 �������
                            led_reg   <= not led_reg;
                            blink_cnt <= (others => '0');
                        end if;
                    else
                        led_reg <= '0';  
                    end if;
                end if;
            end if;
        end process;
    
        led_o <= led_reg;
    
    end Behavioral;
    
    
 ---------------������ �������� ������� -------------------------
 
 
--    process(buf_clk)
--    begin
--        if rising_edge(buf_clk) then
            
--            if reset_z = '1' then
--                -- ������ reset (BTN1) ������  ��������� ���������
--                led_reg   <= '0';
--                blink_cnt <= (others => '0');
                
--            else
--                -- ���������� ��������� (reset �������) 
--                blink_cnt <= blink_cnt + 1;
                
--                if blink_cnt = 62499999 then        -- ~0.5 ������� �� 125 ���
--                    led_reg   <= not led_reg;
--                    blink_cnt <= (others => '0');
--                end if;
--            end if;
            
--        end if;
--    end process;

--    led_o <= led_reg;
  

--end Behavioral;











--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.std_logic_arith;
--library unisim;
--use unisim.vcomponents.all;

--entity Lab4 is
--    Port ( 
--           clk : in STD_LOGIC;
--           reset : in STD_LOGIC;
--           start : in STD_LOGIC;
--         -- counter : out STD_LOGIC_VECTOR(15 downto 0);
--           inv_clk : out STD_LOGIC;
--           half_clk : out STD_LOGIC;
--           brst_o : out STD_LOGIC;
--           start_1: out STD_LOGIC;
           
--           S_led_o: out STD_LOGIC;
--           R_led_o: out STD_LOGIC
--           );
           
--end Lab4;

--architecture Behavioral of Lab4 is
--signal counter_up: STD_LOGIC_VECTOR(15 downto 0):="0000000000000000";
--signal buf_counter_out: STD_LOGIC_VECTOR(15 downto 0);
--signal buf_clk: STD_LOGIC;
--signal bhalf_clk, binv_clk: STD_LOGIC;
--signal reset_z: STD_LOGIC;
--signal breset: STD_LOGIC;
--signal bstart: STD_LOGIC;

--signal S_led: STD_LOGIC:='0';
--signal R_led: STD_LOGIC:='0';

--begin 

--clk_base: MMCM_BASE
--generic map (
--BANDWIDTH => "OPTIMIZED",
--CLKFBOUT_MULT_F => 8.0,
--clkin1_period => 8.0,
--CLKOUT0_DIVIDE_F => 8.0,
--clkout0_phase => 45.0,
--CLKOUT1_PHASE => -90.0,
--clkout1_divide => 4
--)
--port map(
--clkfbin => buf_clk,
--CLKOUT0 => bhalf_clk,
--clkout1 => binv_clk,
--CLKIN1 => buf_clk,
--PWRDWN => '0',
--RST => '0'
--);

--obuf_inv_clk: obuf
--port map
--(
--    O => inv_clk,
--    I => binv_clk
--);
 
--obuf_half_clk: obuf
--port map
--(
--     O => half_clk,
--     I => bhalf_clk
--);

--BUFG_clk: BUFG
--port map
--( 
--  O => buf_clk,
--  I => clk 
-- );
 
---- reset_ibuf: ibuf
---- port map
---- (
----  O => breset,
----  I => reset
---- );
 
---- start_ibuf: ibuf
---- port map
---- (
----  O => bstart,
----  I => start
---- );

---- counter_obuf: for i in 0 to 15 generate
---- obuf_out: obuf_lvttl
---- port map
---- ( 
----  O => counter(i),
----  I => buf_counter_out(i)   
---- );
-- --end generate;

--use_SRL16E: SRL16E
--    generic map (INIT => X"0000")
--        port map (
--            Q => reset_z, -- �������� ������ ���������� ��������
--            A0 => '0', -- ����� ������������ ����� ������ ���������� ��������
--            A1 => '0',
--            A2 => '0',
--            A3 => '1',
--            CLK => buf_clk, -- ������ ������������
--            CE => '1', -- ������ ����������
--            D => breset -- ������� ������ ���������� ��������
--          );
--brst_o <= reset_z;
--start_1 <= bstart;

----test_reset_start: process(clk)
----    begin
----        if rising_edge(buf_clk) then
----            -- ������ ����� �������� '0' / '1' - ��� ����� �������������� ������ ������� ������
----            breset <= '1';     -- 
----            bstart <= '1';     -- 
----        end if;
----    end process;
    
    
----process(clk, reset_z,bstart,S_led,R_led)
----    begin
----        if(rising_edge(buf_clk)) then
----            if( reset_z = '1' AND bstart = '1') then
----                counter_up <= counter_up + "0000000000000001";
----                if (counter_up = "1111111111111111") then
----                    counter_up <= "0000000000000000";
----                end if;
----            end if;   
----            if( reset_z ='1') then
----                --counter_up <= "0000000000000000";
----                R_led <= not R_led;
----             else
----                R_led <= R_led;
----                counter_up <= "0000000000000000";
----             end if;
----             if(bstart = '1') then
----                S_led <= not S_led;
----             else
----                S_led <= S_led;
----             end if;                   
----        end if;
----  end process;
----  buf_counter_out <= counter_up;
----  S_led_o <= S_led;
----  R_led_o <= R_led; 
----  end Behavioral;





--process(buf_clk)
--    begin
--        if rising_edge(buf_clk) then
            
--            if reset_z = '1' then
--                -- ������ reset (BTN1) ������ - ��������� ���������
--                led_reg   <= '0';
--                blink_cnt <= (others => '0');
                
--            else
--                -- ���������� ��������� (reset �������) - ������ �����
--                blink_cnt <= blink_cnt + 1;
                
--                if blink_cnt = 62499999 then        -- ~0.5 ������� �� 125 ���
--                    led_reg   <= not led_reg;
--                    blink_cnt <= (others => '0');
--                end if;
--            end if;
            
--        end if;
--    end process;

--    led_o <= led_reg;
  

--end Behavioral;






--entity Lab4 is
--    Port (
--           clk      : in  STD_LOGIC;
--           S_led_o  : out STD_LOGIC;   -- ������ ���������
--           R_led_o  : out STD_LOGIC    -- ������ ���������
--           );
--end Lab4;

--architecture Behavioral of Lab4 is

--    signal Counter : STD_LOGIC_VECTOR(26 downto 0);
--    signal LED_blink : STD_LOGIC;

--begin

--    Prescaler: process(clk)
--    begin
--        if rising_edge(clk) then
            
--            if Counter < "1111010000100100000000000000" then   -- 0.5 ������� �� 125 ���
            
--                Counter <= Counter + 1;
               
--            else
--            LED_blink<= not LED_blink;
--                 Counter   <= (others => '0');
--            end if;
            
--        end if;
--    end process;

--    -- ������� �� ����������
--    S_led_o <= LED_blink;      
--    R_led_o <= not LED_blink;  

--end Behavioral;
