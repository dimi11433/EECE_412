library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--The code for a d FLIP FLOP
-- architecture flip of example_design is 
--     signal x_reg, x_next : std_logic;
--     begin
--     process(clk, reset)
--         begin
--             if( reset = '1')then
--                 x_reg <= '0';
--             else if (rising_edge(clk)) then
--                 x_reg <= x_next;
--             end if;
--     end process;
-- end flip;

entity cnter1or2 is
    port (
        clk : in std_logic;
        reset : in std_logic;
        ctrl : in std_logic;
        q : out std_logic_vector(3 downto 0)
    );
end cnter1or2;
architecture arch of cnter1or2 is
    signal r_reg, r_next : unsigned(3 downto 0);
    begin
        process(clk, reset)
        begin
            if (rising)then
                r_reg <= (others => '0');
            else if (rising_edge(clk)) then
                r_reg <= r_next;
            end if;
        end process;

        r_next <= r_reg + to_unsigned(1, 4) when ctrl = '1' else
            r_reg + to_unsigned(2, 4);

            
        q <= std_logic_vector(r_reg);
end arch;
