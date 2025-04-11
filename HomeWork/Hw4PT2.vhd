library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity Case_stmts is
    Port (
        s: in std_logic_vector(1 downto 0); --2bit input s
        z: out std_logic --one bit output z
    );
end Case_stmts;

architecture rtl of Case_stmts is
    begin
        process(s)
        begin
            case s is
                when "00" => --when s == 00
                    z <= '0'; --z = 0
                when "01" => --when s == 01
                    z <= '1'; --z = 1
                when "10" => --when s == 10
                    z <= '0'; z = 0
                when others => --when others aka when s == 11
                    z <= '1'; -- z= 1
            end case; --end case
        end process; --end process
end rtl;