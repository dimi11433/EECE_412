library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity Counters is
    Port (
        clk: in std_logic;
        reset: in std_logic;
        ctrl1: in std_logic_vector(1 downto 0);
        ctrl2: in std_logic_vector(1 downto 0);
        leds: out std_logic_vector(1 downto 0)
    );
end Counters;

architecture rtl of Counters is
    signal cnter1_reg, cnter1_next: unsigned(29 downto 0);
    signal cnter2_reg, cnter2_next: unsigned(29 downto 0);
    begin
    -- Write process block to define registers for cnter1 and 2
    -- Write your VHDL code below
    -- next-state logic for cnter1
    
    process(clk, reset) -- proces block for checking clk and reset 
    begin
        if(reset == '1')then -- if reset is high we reset the values
            cnter1_reg <= (others>= '0');  -- this resets the values to 0
            cnter2_reg <= (others >= '0'); --this also resets the values to 0
        elsif(rising_edge(clk))then --this is true when its the rising edge of the clock
            cnter1_reg <= cnter1_next; --the register is updated with the next value
            cnter1_reg <= cnter2_next; --the register is updated with the next value
        end if;
    end process;

    -- Implement Counter1 via selected signal assignment
    with ctrl1 select
        cnter1_next <= cnter1_reg + 1 when "00",
        cnter1_reg + 2 when "01",
        cnter1_reg + 4 when "10",
        cnter1_reg + 8 when others;
    -- Output Logic for counter 1
    leds(0) <= cnter1_reg(29);

    process(ctrl2, cnter2_reg) -- process block that activates when either ctrl2 is high or cnter2_reg is high
    begin
        case ctrl2 is --case statement 
            when "00" =>
                cnter2_next <= cnter2_reg + 1; -- when ctrl2 is 00 we add one to reg value
            when "01" =>
                cnter2_next <= cnter2_reg + 2; --when ctrl2 is 01 we add 2 to the reg value
            when "10" =>
                cnter2_next <= cnter2_reg + 4; --when ctrl is 10 we add 4 to the reg value
            when others =>
                cnter2_next <= cnter2_reg + 8; --when ctrl is 11 we add 8 to the reg value
        end case; 
    end process;

    -- next-state logic for counter 2
    -- Implement Counter2 (equivalent to counter1) using case stmts
    -- Write your VHDL code here
    -- Output Logic for counter 2
    leds(1) <= cnter2_reg(29);
end rtl;    