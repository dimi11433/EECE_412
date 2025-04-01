library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity prior_encoder_if_stmts is
    port (
        r: in std_logic_vector(3 down to 0); --4bit input r
        code: out std_logic_vector(1 downto 0);--2 bit output code
        active: out std_logic --1 bit output active
    );
end prior_encoder_if_stmts;
architecture rtl of prior_encoder_if_stmts is
    process(r) --whenever the r input changes this activates
    begin
        code <= "00"; --base case
        active <= '0';--base case
        if(r(3) == '1')then --checks if the highest bit is equal to 1
            code <= "11"; -- if yes set code to 11 and active to high 
            active <= '1';
        elsif(r(2) == '1')then--checks if the second highest bit is equal to 1
            code <= "10"; --if yes set code to 10 and active to high 
            active <= '1';
        elsif(r(1) == '1')then --checks if third highest bit is equal to 1
            code <= "01"; --If yes set code to 01 and active to 1
            active <= '1';
        elsif(r(0) == '1')then--checks if the last bit is equal to 1
            code <= "00"; --If yes set code to 00 and active to 1
            active <= '1';
        else
            code <= "00"; --set code to 00 and active to 0 if anyother case
            active <= '0';
        end if 
    end process
end rtl;