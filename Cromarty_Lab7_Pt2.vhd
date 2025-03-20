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
    process(s)
        begin 
            case s is
                when "00" =>
                    x <= a;
                    y <= "0001";
                when "01" =>
                    x <= b;
                    y <= "0010";
                when "10" =>
                    x <= c;
                    y <= "0100";
                when "11" =>
                    x <= d;
                    y <= "1000";
                when others =>
                    x <= '0';
                    y <= "0000";
            end case;
    end process;
end rtl;

