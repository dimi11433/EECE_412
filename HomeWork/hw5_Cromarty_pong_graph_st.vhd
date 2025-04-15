library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- btn connected to up/down pushbuttons for now but
-- eventually will get data from UART
entity pong_graph_st is
    port (
        clk, reset : in std_logic;
        btn : in std_logic_vector(1 downto 0);
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
    -- wall left and right boundary of wall (full height)
    constant WALL_X_L : integer := 32;
    constant WALL_X_R : integer := 35;
    -- paddle left, right, top, bottom and height left &
    -- right are constant. top & bottom are signals to
    -- allow movement. bar_y_t driven by reg below.
    constant BAR_X_L : integer := 600;
    constant BAR_X_R : integer := 603;
    signal bar_y_t, bar_y_b : unsigned(9 downto 0);
    constant BAR_Y_SIZE : integer := 72;
    -- reg to track top boundary (x position is fixed)
    signal bar_y_reg, bar_y_next : unsigned(9 downto 0);
    -- bar moving velocity when a button is pressed
    -- the amount the bar is moved.
    constant BAR_V : integer := 4;
    -- square ball -- ball left, right, top and bottom
    -- all vary. Left and top driven by registers below.
    constant BALL_SIZE : integer := 8;
    constant TRIANGLE_SIZE : integer := 16 -- the triangle size we are going to implement


    signal ball_x_l, ball_x_r : unsigned(9 downto 0);
    signal ball_y_t, ball_y_b : unsigned(9 downto 0);

    signal triangle_x_l, triangle_x_r : unsigned(9 downto 0); --cordinates for the sides of the triangle
    signal triangle_y_t, triangle_y_b : unsigned(9 downto 0)
    -- reg to track left and top boundary
    signal ball_x_reg, ball_x_next : unsigned(9 downto 0);
    signal ball_y_reg, ball_y_next : unsigned(9 downto 0);

    signal triangle_x_reg, triangle_x_next : unsigned(9 downto 0);
    signal triangle_y_reg, triangle_y_next : unsigned(9 downto 0);
    

    -- reg to track ball speed
    signal x_delta_reg, x_delta_next : unsigned(9 downto 0);
    signal y_delta_reg, y_delta_next : unsigned(9 downto 0);

    signal x_trig_delta_reg, x_trig_delta_next : unsigned(9 downto 0);
    signal y_trig_delta_reg, y_trig_delta_next : unsigned(9 downto 0);

    -- ball movement can be pos or neg
    constant BALL_V_P : unsigned(9 downto 0) := to_unsigned(2, 10);
    constant BALL_V_N : unsigned(9 downto 0) := unsigned(to_signed(-2, 10));

    constant TRIANGLE_V_P : unsigned(9 downto 0) := to_unsigned(4, 10);
    constant TRIANGLE_V_N : unsigned(9 downto 0) := unsigned(to_signed(-2, 10));
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

    type rom_trig_type is array (0 to 15) of std_logic_vector(0 to 15);
    constant TRIANGLE_ROM : rom_trig_type := (
        "1000000000000000",  
        "1100000000000000", 
        "1110000000000000",  
        "1111000000000000",  
        "1111100000000000",  
        "1111110000000000",  
        "1111111000000000",  
        "1111111100000000",  
        "1111111110000000",  
        "1111111111000000", 
        "1111111111100000", 
        "1111111111110000",  
        "1111111111111000",  
        "1111111111111100", 
        "1111111111111110", 
        "1111111111111111", 
    );
    signal rom_trig_addr, rom_trig_col : unsigned(4 downto 0); --This tracks the row and coloum in the triangle
    signal rom_trig_data : std_logic_vector(15 downto 0); -- this gets the row data 
    signal rom_trig_bit : std_logic; --this gets the column data 
    -- object output signals -- new signal to indicate if
    -- scan coord is within ball
    signal wall_on, bar_on, sq_ball_on, rd_ball_on, ra_trig_on, trig_on : std_logic;
    signal wall_rgb, bar_rgb, ball_rgb, trig_rgb : std_logic_vector(2 downto 0);
    -- ====================================================
begin
    process (clk, reset)
    begin
        if (reset = '1') then
            bar_y_reg <= (others => '0');
            ball_x_reg <= (others => '0');
            ball_y_reg <= (others => '0');
            x_delta_reg <= ("0000000100");
            y_delta_reg <= ("0000000100");
            triangle_x_reg <= (others => '0');
            triangle_y_reg <= (others => '0');
            x_trig_delta_reg <= ("0000000100");
            y_trig_delta_reg <= ("0000000100");
        elsif (clk'event and clk = '1') then
            bar_y_reg <= bar_y_next;
            ball_x_reg <= ball_x_next;
            ball_y_reg <= ball_y_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
            triangle_x_reg <= triangle_y_next;
            triangle_y_reg <= triangle_x_next;
            x_trig_delta_reg <= x_trig_delta_next;
            y_trig_delta_reg <= y_trig_delta_next;
        end if;
    end process;
    pix_x <= unsigned(pixel_x);
    pix_y <= unsigned(pixel_y);
    -- refr_tick: 1-clock tick asserted at start of v_sync,
    -- e.g., when the screen is refreshed -- speed is 60 Hz
    refr_tick <= '1' when (pix_y = 481) and (pix_x = 0)
        else
     '0';
    -- wall left vertical stripe
    wall_on <= '1' when (WALL_X_L <= pix_x) and
        (pix_x <= WALL_X_R) else
     '0';
    wall_rgb <= "001"; -- blue
    -- pixel within paddle
    bar_y_t <= bar_y_reg;
    bar_y_b <= bar_y_t + BAR_Y_SIZE - 1;
    bar_on <= '1' when (BAR_X_L <= pix_x) and
        (pix_x <= BAR_X_R) and (bar_y_t <= pix_y) and
        (pix_y <= bar_y_b) else
     '0';
    bar_rgb <= "010"; -- green
    -- Process bar movement requests
    process (bar_y_reg, bar_y_b, bar_y_t, refr_tick, btn)
    begin
        bar_y_next <= bar_y_reg; -- no move
        if (refr_tick = '1') then
            -- if btn 1 pressed and paddle not at bottom yet
            if (btn(1) = '0' and bar_y_b <
                (MAX_Y - 1 - BAR_V)) then
                bar_y_next <= bar_y_reg + BAR_V;
                -- if btn 0 pressed and bar not at top yet
            elsif (btn(0) = '0' and bar_y_t > BAR_V) then
                bar_y_next <= bar_y_reg - BAR_V;
            end if;
        end if;
    end process;
    -- set coordinates of square ball.
    ball_x_l <= ball_x_reg;
    ball_y_t <= ball_y_reg;
    ball_x_r <= ball_x_l + BALL_SIZE - 1;
    ball_y_b <= ball_y_t + BALL_SIZE - 1;

    --set coordinates of triangle.
    triagnle_x_l <= trigangle_x_reg;
    triangle_y_t <= triangle_y_reg:;
    triangle_x_r <= triangle_x_l + TRIANGLE_SIZE - 1;
    triangle_y_b <= triangle_y_l + TRIANGLE_SIZE - 1;

    -- pixel within square ball
    sq_ball_on <= '1' when (ball_x_l <= pix_x) and
        (pix_x <= ball_x_r) and (ball_y_t <= pix_y) and
        (pix_y <= ball_y_b) else
     '0';

    --pixel within square triangle 
    ra_trig_on <= '1' when (triangle_x_l <= pix_x) and 
        (pix_x <= triangle_x_r) and (triangle_y_t <= pix_y) and 
        (pix_y <= triangle_y_b)
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

    --now we need to do the same for the triangle
    
    -- Update the ball position 60 times per second.
    ball_x_next <= ball_x_reg + x_delta_reg when
        refr_tick = '1' else
        ball_x_reg;
    ball_y_next <= ball_y_reg + y_delta_reg when
        refr_tick = '1' else
        ball_y_reg;
    -- Set the value of the next ball position according to
    -- the boundaries.
    process (x_delta_reg, y_delta_reg, ball_y_t, ball_x_l,
        ball_x_r, ball_y_t, ball_y_b, bar_y_t, bar_y_b)
    begin
        x_delta_next <= x_delta_reg;
        y_delta_next <= y_delta_reg;
        -- ball reached top, make offset positive
        if (ball_y_t < 1) then
            y_delta_next <= BALL_V_P;
            -- reached bottom, make negative
        elsif (ball_y_b > (MAX_Y - 1)) then
            y_delta_next <= BALL_V_N;
            -- reach wall, bounce back
        elsif (ball_x_l <= WALL_X_R) then
            x_delta_next <= BALL_V_P;
            -- right corner of ball inside bar
        elsif ((BAR_X_L <= ball_x_r) and
            (ball_x_r <= BAR_X_R)) then
            -- some portion of ball hitting paddle, reverse dir
            if ((bar_y_t <= ball_y_b) and
                (ball_y_t <= bar_y_b)) then
                x_delta_next <= BALL_V_N;
            end if;
        end if;
    end process;
    process (video_on, wall_on, bar_on, rd_ball_on,
        wall_rgb, bar_rgb, ball_rgb)
    begin
        if (video_on = '0') then
            graph_rgb <= "000"; -- blank
        else
            if (wall_on = '1') then
                graph_rgb <= wall_rgb;
            elsif (bar_on = '1') then
                graph_rgb <= bar_rgb;
            elsif (rd_ball_on = '1') then
                graph_rgb <= ball_rgb;
            else
                graph_rgb <= "110"; -- yellow bkgnd
            end if;
        end if;
    end process;
end sq_ball_arch;