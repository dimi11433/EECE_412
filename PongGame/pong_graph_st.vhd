library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity pong_graph_st is
    port(
        video_on: in std_logic;
        pixel_x, pixel_y: in std_logic_vector(9 downto 0);
        graph_rgb: out std_logic_vector(2 downto 0)
    );
end pong_graph_st;
architecture sq_ball_arch of pong_graph_st is
-- x, y coordinates (0,0 to (639, 479)
    signal pix_x, pix_y: unsigned(9 downto 0);
    constant MAX_X: integer := 640;
    constant MAX_Y: integer := 480;
    -- wall left and right boundary
    constant WALL_X_L: integer := 32;
    constant WALL_X_R: integer := 35;
    -- paddle left, right, top, bottom and height
    constant BAR_X_L: integer := 600;
    constant BAR_X_R: integer := 603;
    constant BAR_Y_SIZE: integer := 72;
    -- top boundary of paddle -- offset from screen middle
    constant BAR_Y_T: integer := MAX_Y/2 - BAR_Y_SIZE/2;
    constant BAR_Y_B: integer := BAR_Y_T + BAR_Y_SIZE - 1;
    -- square ball
    constant BALL_SIZE: integer := 8;
    constant BALL_X_L: integer := 580;
    constant BALL_X_R: integer:= BALL_X_L + BALL_SIZE - 1;
    constant BALL_Y_T: integer := 238;
        constant BALL_Y_B: integer:= BALL_Y_T + BALL_SIZE - 1;
    -- object output signals
    signal wall_on, bar_on, sq_ball_on: std_logic;
    signal wall_rgb, bar_rgb, ball_rgb: std_logic_vector(2 downto 0);
    begin
        pix_x <= unsigned(pixel_x);
        pix_y <= unsigned(pixel_y);
        -- wall left vertical stripe
        wall_on <= '1' when (WALL_X_L <= pix_x) and
        (pix_x <= WALL_X_R) else '0';
        wall_rgb <= "001"; -- blue
        -- pixel within paddle
        bar_on <= '1' when (BAR_X_L <= pix_x) and
        (pix_x <= BAR_X_R) and
        (BAR_Y_T <= pix_y) and
        (pix_y <= BAR_Y_B) else '0';
        bar_rgb <= "010"; -- green
        sq_ball_on <= '1' when (BALL_X_L <= pix_x) and
        (pix_x <= BALL_X_R) and
        (BALL_Y_T <= pix_y) and
        (pix_y <= BALL_Y_B) else '0';
        ball_rgb <= "100"; -- red
        process (video_on, wall_on, bar_on, sq_ball_on, wall_rgb, bar_rgb, ball_rgb)
            begin
                if (video_on = '0') then
                    graph_rgb <= "000"; -- blank
                else -- priority encoding implicit here
                    if (wall_on = '1') then
                        graph_rgb <= wall_rgb;
                    elsif (bar_on = '1') then
                        graph_rgb <= bar_rgb;
                    elsif (sq_ball_on = '1') then
                        graph_rgb <= ball_rgb;
                    else
                        graph_rgb <= "110"; -- yellow bkgnd
                    end if;
                end if;
            end process;
end sq_ball_arch;