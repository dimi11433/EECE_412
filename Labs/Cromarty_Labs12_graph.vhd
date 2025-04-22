library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pong_graph_st is
  port(
    clk       : in  std_logic;
    reset     : in  std_logic;
    video_on  : in  std_logic;
    pixel_x   : in  std_logic_vector(9 downto 0);
    pixel_y   : in  std_logic_vector(9 downto 0);
    up_btn    : in  std_logic;    -- Move spaceship up
    down_btn  : in  std_logic;    -- Move spaceship down
    left_btn  : in  std_logic;    -- Move spaceship left
    right_btn : in  std_logic;    -- Move spaceship right
    fire_btn  : in  std_logic;    -- Firing button
    rgb_next  : out std_logic_vector(2 downto 0)
  );
end pong_graph_st;

architecture Behavioral of pong_graph_st is

  -- Screen parameters
  constant H_RES : integer := 640;
  constant V_RES : integer := 480;

  -- Spaceship parameters
  constant SHIP_WIDTH  : integer := 24;
  constant SHIP_HEIGHT : integer := 16;
  constant SHIP_SPEED  : integer := 4;
  signal ship_x        : integer range 0 to H_RES - SHIP_WIDTH := (H_RES - SHIP_WIDTH)/2;
  signal ship_y        : integer range 0 to V_RES - SHIP_HEIGHT := (V_RES - SHIP_HEIGHT)/2;

--   -- Bouncing ball parameters (optional)
--   constant BALL_SIZE : integer := 4;
--   signal ball_x      : integer range 0 to H_RES - BALL_SIZE := H_RES/2;
--   signal ball_y      : integer range 0 to V_RES - BALL_SIZE := V_RES/2;
--   signal ball_dx     : integer range -5 to 5 := 2;
--   signal ball_dy     : integer range -5 to 5 := 2;

  -- Missile parameters
  constant MIS_WIDTH    : integer := 8;
  constant MIS_HEIGHT   : integer := 4;
  constant MIS_SPEED    : integer := 6;
  signal missile_x      : integer range 0 to H_RES := 0;
  signal missile_y      : integer range 0 to V_RES := 0;
  signal missile_active : std_logic := '0';

  -- Bitmap ROM for spaceship (16 rows of 24 bits)
  type rom_type_16 is array(0 to 15) of std_logic_vector(0 to SHIP_WIDTH-1);
  constant SPACESHIP_ROM : rom_type_16 := (
      "000000000000000000000000",
      "000000000000000111110000",
      "000000000000001111111110",
      "000000111111111111111100",
      "000111111111111111111000",
      "001111111111111111110000",
      "011111110111111111110000",
      "111111100011111111110000",
      "011111110111111111110000",
      "001111111111111111110000",
      "000111111111111111110000",
      "000000111111111111111100",
      "000000000000001111111110",
      "000000000000000111110000",
      "000000000000000000000000",
      "000000000000000000000000"
  );

  -- Bitmap type for missile
  type bmp_row_t is array (natural range <>) of std_logic;
  type bmp_t     is array (natural range <>) of bmp_row_t;
  constant missile_bmp : bmp_t := (
    "11000011",
    "11100111",
    "11100111",
    "11000011"
  );

  -- On-signals
  signal ship_on    : std_logic;
  signal ball_on    : std_logic;
  signal missile_on : std_logic;

begin

  -- Spaceship movement (full 2D) process
  ship_proc: process(clk, reset)
  begin
    if reset = '1' then
      ship_x <= (H_RES - SHIP_WIDTH)/2;
      ship_y <= (V_RES - SHIP_HEIGHT)/2;
    elsif rising_edge(clk) then
      if up_btn = '1' and ship_y > 0 then
        ship_y <= ship_y - SHIP_SPEED;
      elsif down_btn = '1' and ship_y < V_RES - SHIP_HEIGHT then
        ship_y <= ship_y + SHIP_SPEED;
      end if;
      if left_btn = '1' and ship_x > 0 then
        ship_x <= ship_x - SHIP_SPEED;
      elsif right_btn = '1' and ship_x < H_RES - SHIP_WIDTH then
        ship_x <= ship_x + SHIP_SPEED;
      end if;
    end if;
  end process;

  -- Bouncing ball process (optional)
--   ball_proc: process(clk, reset)
--   begin
--     if reset = '1' then
--       ball_x  <= H_RES/2;
--       ball_y  <= V_RES/2;
--       ball_dx <= 2;
--       ball_dy <= 2;
--     elsif rising_edge(clk) then
--       if ball_x <= 0 or ball_x >= H_RES - BALL_SIZE then
--         ball_dx <= -ball_dx;
--       end if;
--       if ball_y <= 0 or ball_y >= V_RES - BALL_SIZE then
--         ball_dy <= -ball_dy;
--       end if;
--       ball_x <= ball_x + ball_dx;
--       ball_y <= ball_y + ball_dy;
--     end if;
--   end process;

  -- Missile launch & movement
  missile_proc: process(clk, reset)
  begin
    if reset = '1' then
      missile_active <= '0';
    elsif rising_edge(clk) then
      if fire_btn = '1' and missile_active = '0' then
        missile_active <= '1';
        missile_x      <= ship_x + SHIP_WIDTH;
        missile_y      <= ship_y + SHIP_HEIGHT/2 - MIS_HEIGHT/2;
      elsif missile_active = '1' then
        if missile_x > 0 then
          missile_x <= missile_x - MIS_SPEED;
        else
          missile_active <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Ship on/off
  ship_on <= '1' when video_on = '1' and
                    to_integer(unsigned(pixel_x)) >= ship_x and to_integer(unsigned(pixel_x)) < ship_x + SHIP_WIDTH and
                    to_integer(unsigned(pixel_y)) >= ship_y and to_integer(unsigned(pixel_y)) < ship_y + SHIP_HEIGHT and
                    SPACESHIP_ROM(to_integer(unsigned(pixel_y)) - ship_y)(to_integer(unsigned(pixel_x)) - ship_x) = '1'
             else '0';

--   -- Ball on/off
--   ball_on <= '1' when video_on = '1' and
--                     to_integer(unsigned(pixel_x)) >= ball_x and to_integer(unsigned(pixel_x)) < ball_x + BALL_SIZE and
--                     to_integer(unsigned(pixel_y)) >= ball_y and to_integer(unsigned(pixel_y)) < ball_y + BALL_SIZE
--              else '0';

  -- Missile on/off
  missile_on <= '1' when video_on = '1' and missile_active = '1' and
                       to_integer(unsigned(pixel_x)) >= missile_x and to_integer(unsigned(pixel_x)) < missile_x + MIS_WIDTH and
                       to_integer(unsigned(pixel_y)) >= missile_y and to_integer(unsigned(pixel_y)) < missile_y + MIS_HEIGHT and
                       missile_bmp(to_integer(unsigned(pixel_y)) - missile_y)(to_integer(unsigned(pixel_x)) - missile_x) = '1'
                  else '0';

  -- RGB assignment
  process(ship_on, ball_on, missile_on)
  begin
    if missile_on = '1' then
      rgb_next <= "100";  -- Red for missile
    elsif ball_on = '1' then
      rgb_next <= "010";  -- Green for ball
    elsif ship_on = '1' then
      rgb_next <= "001";  -- Blue for spaceship
    else
      rgb_next <= "000";  -- Background
    end if;
  end process;

end Behavioral;
