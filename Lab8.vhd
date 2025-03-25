library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity nested_if_max is
    Port(
        a, b, c: in std_logic_vector(1 downto 0)
        max: in std_logic_vector(1 downto 0)
    );
end nested_if_max;

architecture rtl of nested_if_max is
    signal ua, ub, uc: unsigned(1 downto 0);
    signal umax: unsigned(1 downto 0);

    begin 
        ua <= unsigned(a);
        ub <= unsigned(b);
        uc <= unsigned(c);

        process(ua, ub, uc)
            if(ua > ub) then
                if(ua > uc) then
                    max <= ua;
                else 
                    max <= uc;
                end if;
            else
                if(ub > uc) then 
                    max <= ub;
                else 
                    max <= uc;
                end if;
            end if;
        end process;
    max <= std_logic_vector(umax);
end rtl;
                    
            
            

