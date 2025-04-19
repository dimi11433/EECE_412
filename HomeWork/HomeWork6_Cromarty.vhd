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

-- entity cnter1or2 is
--     port (
--         clk : in std_logic;
--         reset : in std_logic;
--         ctrl : in std_logic;
--         q : out std_logic_vector(3 downto 0)
--     );
-- end cnter1or2;
-- architecture arch of cnter1or2 is
--     signal r_reg, r_next : unsigned(3 downto 0);
--     begin
--         process(clk, reset)
--         begin
--             if (rising)then
--                 r_reg <= (others => '0');
--             elsif (rising_edge(clk)) then
--                 r_reg <= r_next;
--             end if;
--         end process;

--         r_next <= r_reg + to_unsigned(1, 4) when ctrl = '1' else
--             r_reg + to_unsigned(2, 4);

            
--         q <= std_logic_vector(r_reg);
-- end arch;

-- entity b8Counter is
--     port(
--         clk: in std_logic;
--         reset: in std_logic;
--         up: in std_logic;
--         q: out std_logic_vector(7 downto 0)
--     );
-- end b8Counter;
-- architecture rtl of b8Counter is
--     signal r_reg, r_next: unsigned(7 downto 0);
--     begin
--         process(clk, reset)
--         begin
--             if(reset = '1')then
--                 r_reg <= (others => '0');
--             elsif(rising_edge(clk)) then
--                 r_reg <= r_next;
--             end if;
--         end process;

--         r_next <= r_reg + to_unsigned(1, 8) when up = '1' else
--             r_reg - to_unsigned(1,8);

--         q <= std_logic_vector(r_reg);
-- end rtl;

-- assume type state_type is (IDLE, TEST, AB0, LOAD, OP);
signal state, next_state : state_type;

-- combinational next‐state logic
process(state, start, a, b, count_0)
begin
  case state is
    when IDLE =>
      ready <= '1';
      if start = '1' then
        next_state <= TEST;
      else
        next_state <= IDLE;
      end if;
    when TEST =>  
      -- “start=1” is already implied, so we only test a or b = 0
      if (a = 0) or (b = 0) then
        next_state <= AB0;
      else
        next_state <= LOAD;
      end if;
    when AB0 =>
      -- load r := 0, n := b_in, a := a_in
      next_state <= OP;
    when LOAD =>
      -- load r := 0, n := b_in, a := a_in
      next_state <= OP;
    when OP =>
      -- r := r + a;  n := n - 1
      if count_0 = '0' then
        next_state <= OP;         -- keep looping
      else                        -- we’ve finished one multiply
        if start = '1' then
          next_state <= TEST;     -- back‑to‑back
        else
          next_state <= IDLE;     -- go idle until next start
        end if;
      end if;
    when others =>
      next_state <= IDLE;

  end case;
end process;
