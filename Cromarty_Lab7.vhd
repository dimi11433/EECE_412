library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity selected_stmt_mux_dec is 
    port(
        s: in std_logic_vector(1 downto 0);
        a, b, c, d: in std_logic;
        x: out std_logic;
        y: out std_logic_vector(3 down to 0)
    );
end selected_stmt_mux_dec;
architecture rtl of selected_stmt_mux_dec is 
    begin 
    with s select
        x <= a when "00",
             b when "01",
             c when "10",
             d when "11",
             "0" when others;

    with s select
        y <= "0001" when "00",
             "0010" when "01",
             "0100" when "10",
             "1000" when "11",
             "0000" when others;
end rtl;


