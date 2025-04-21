library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- btn connected to up/down pushbuttons for now but
-- eventually will get data from UART
entity pong_graph_st is
    port (
        clk, reset : in std_logic;
        btn : in std_logic_vector(4 downto 0);
        video_on : in std_logic;
        pixel_x, pixel_y : in std_logic_vector(9 downto 0);
        graph_rgb : out std_logic_vector(2 downto 0)
    );
end pong_graph_st;
architecture sq_ball_arch of pong_graph_st is
    -- Signal used to control speed of ball and how
    -- often pushbuttons are checked for paddle movement.
    signal refr_tick : std_logic;
    -- x, y coordinates (0,0 to (639, 479)
    signal pix_x, pix_y : unsigned(9 downto 0);
    -- screen dimensions
    constant MAX_X : integer := 640;
    constant MAX_Y : integer := 480;
    

    -- paddle left, right, top, bottom and height left &
    -- right are constant. top & bottom are signals to
    -- allow movement. spaceship_y_top driven by reg below.

    signal spaceship_y_top, spaceship_y_bottom : unsigned(9 downto 0);
    signal spaceship_x_start, spaceship_x_end : unsigned(9 downto 0);

    constant SPACESHIP_Y_SIZE : integer := 24;
    constant SPACESHIP_X_SIZE : integer := 16;
    -- reg to track top boundary and bottom (x position is  notfixed)
    signal spaceship_y_reg, spaceship_y_next : unsigned(9 downto 0);
    signal spaceship_x_reg, spaceship_x_next : unsigned(9 downto 0);
    -- bar moving velocity when a button is pressed
    -- the amount the bar is moved.
    constant SPACESHIP_MOVE : integer := 4;
    constant FIRING_DX : integer := 4;
    
    -- square ball -- ball left, right, top and bottom
    -- all vary. Left and top driven by registers below.
    constant FIRING_BALL_SIZE : integer := 8;

    signal ball_x_l, ball_x_r : unsigned(9 downto 0);
    signal ball_y_t, ball_y_b : unsigned(9 downto 0);

    -- reg to track left and top boundary
    signal ball_x_reg, ball_x_next : unsigned(9 downto 0);
    signal ball_y_reg, ball_y_next : unsigned(9 downto 0);

    -- spaceship image
    type rom_type_16 is array(0 to 23) of std_logic_vector(0 to 15);
    constant SPACESHIP_ROM : rom_type_16 := (
        "0000000100000000",
        "0000001110000000",
        "0000011111000000",
        "0000111111100000",
        "0000111111100000",
        "0000111111100000",
        "0001111111110000",
        "0001111011110000",
        "0001110001110000",
        "0001111011110000",
        "0001111111110000",
        "0001111111110000",
        "0001111111110000",
        "0001111111110000",
        "0011111111111000",
        "0111111111111100",
        "0111111111111100",
        "0111111111111100",
        "0111111111111100",
        "0111111111111100",
        "0011100000011000",
        "0011000000011000",
        "0010000000001000",
        "0000000000000000"
    );
    -- round ball image
    type rom_type is array(0 to 7) of std_logic_vector(0 to 7);
    constant BALL_ROM : rom_type := (
        "00111100",
        "01111110",
        "11111111",
        "11111111",
        "11111111",
        "11111111",
        "01111110",
        "00111100");
    signal rom_addr, rom_col : unsigned(2 downto 0);
    signal rom_data : std_logic_vector(7 downto 0);
    signal rom_bit : std_logic;
    -- object output signals -- new signal to indicate if
    -- scan coord is within ball
    signal  spaceship_on, sq_ball_on, rd_ball_on : std_logic;
    signal spaceship_rgb, ball_rgb : std_logic_vector(2 downto 0);
    -- ====================================================
begin
    process (clk, reset)
    begin
        if (reset = '1') then
            spaceship_x_reg <= to_unsigned(MAX_X - SPACESHIP_X_SIZE - 1, 10);
            spaceship_y_reg <= to_unsigned((MAX_Y - SPACESHIP_Y_SIZE)/2,   10);
            ball_y_reg <= to_unsigned(MAX_X - SPACESHIP_X_SIZE - 1, 10);
            ball_x_reg <= to_unsigned((MAX_Y - SPACESHIP_Y_SIZE)/2,   10);
            --spaceship_y_reg <= (others => '0');
            --spaceship_x_reg <= (others => '0');
        elsif (clk'event and clk = '1') then
            spaceship_y_reg <= spaceship_y_next;
            spaceship_x_reg <= spaceship_x_next;
            ball_y_reg <= spaceship_y_next;
            ball_x_reg <= spaceship_x_next;
            if(btn(4) = '1')then
                ball_x_reg <= ball_x_next;
            end if;
        end if;
    end process;
    pix_x <= unsigned(pixel_x);
    pix_y <= unsigned(pixel_y);
    -- refr_tick: 1-clock tick asserted at start of v_sync,
    -- e.g., when the screen is refreshed -- speed is 60 Hz
    refr_tick <= '1' when (pix_y = 481) and (pix_x = 0)
        else
        '0';

    -- pixel within paddle
    spaceship_y_top <= spaceship_y_reg;
    spaceship_x_start <= spaceship_x_reg;
    spaceship_y_bottom <= spaceship_y_top + SPACESHIP_Y_SIZE - 1;
    spaceship_x_end <= spaceship_x_start + SPACESHIP_X_SIZE - 1;
    spaceship_on <= '1' when (spaceship_x_start <= pix_x) and
        (pix_x <= spaceship_x_end) and (spaceship_y_top <= pix_y) and
        (pix_y <= spaceship_y_bottom) else
        '0';
    spaceship_rgb <= "010"; -- green
    -- Process bar movement requests
    process (spaceship_y_reg, spaceship_y_bottom, spaceship_y_top, spaceship_x_reg, spaceship_x_start, spaceship_x_end, refr_tick, btn)
    begin
        spaceship_y_next <= spaceship_y_reg; -- no move
        spaceship_x_next <= spaceship_x_reg;
        if (refr_tick = '1') then
            -- if btn 1 pressed and paddle not at bottom yet
            if (btn(1) = '1' and spaceship_y_bottom <
                (MAX_Y - 1 - SPACESHIP_MOVE)) then
                spaceship_y_next <= spaceship_y_reg + SPACESHIP_MOVE;
                -- if btn 0 pressed and bar not at top yet
            elsif (btn(0) = '1' and spaceship_y_top > SPACESHIP_MOVE) then
                spaceship_y_next <= spaceship_y_reg - SPACESHIP_MOVE;
                --if butn 3 is pressed and bar is at right most
            elsif (btn(3) = '1') and (spaceship_x_end < MAX_X -1 - SPACESHIP_MOVE)  then
                spaceship_x_next <= spaceship_x_reg + SPACESHIP_MOVE;
            elsif (btn(2) = '1') and (spaceship_x_start > SPACESHIP_MOVE) then
                spaceship_x_next <= spaceship_x_reg - SPACESHIP_MOVE;
            end if;
        end if;
    end process;
    -- set coordinates of square ball.
    ball_x_l <= ball_x_reg;
    ball_y_t <= ball_y_reg;
    ball_x_r <= ball_x_l + FIRING_BALL_SIZE - 1;
    ball_y_b <= ball_y_t + FIRING_BALL_SIZE - 1;
    -- pixel within square ball
    sq_ball_on <= '1' when (ball_x_l <= pix_x) and
        (pix_x <= ball_x_r) and (ball_y_t <= pix_y) and
        (pix_y <= ball_y_b) else
        '0';
    -- map scan coord to ROM addr/col -- use low order three
    -- bits of pixel and ball positions.
    -- ROM row
    rom_addr <= pix_y(2 downto 0) - ball_y_t(2 downto 0);
    -- ROM column
    rom_col <= pix_x(2 downto 0) - ball_x_l(2 downto 0);
    -- Get row data
    rom_data <= BALL_ROM(to_integer(rom_addr));
    -- Get column bit
    rom_bit <= rom_data(to_integer(rom_col));
    -- Turn ball on only if within square and ROM bit is 1.
    rd_ball_on <= '1' when (sq_ball_on = '1') and
        (rom_bit = '1') else
        '0';
    ball_rgb <= "100"; -- red
    -- Update the ball position 60 times per second.
    ball_x_next <= ball_x_reg + FIRING_DX when
        refr_tick = '1' else
        ball_x_reg;
    -- Set the value of the next ball position according to
    -- the boundaries.
    
    process (video_on, wall_on, spaceship_on, rd_ball_on,
        wall_rgb, spaceship_rgb, ball_rgb)
    begin
        if (video_on = '0') then
            graph_rgb <= "000"; -- blank
        else
            if (spaceship_on = '1') then
                graph_rgb <= spaceship_rgb;
            elsif (rd_ball_on = '1') then
                graph_rgb <= ball_rgb;
            else
                graph_rgb <= "110"; -- yellow bkgnd
            end if;
        end if;
    end process;
end sq_ball_arch;
