library ieee;
use ieee.std_logic_1164.all;
entity pong_top_st is
    port (
        clk, reset : in std_logic;
        btn : in std_logic_vector(4 downto 0);
        hsync, vsync : out std_logic;
        --rgb_8bit: out std_logic_vector(23 downto 0);
        rgb_top : out std_logic_vector(2 downto 0);
        vga_pixel_tick : out std_logic;
        blank : out std_logic;
        comp_sync : out std_logic
    );
end pong_top_st;
architecture arch of pong_top_st is
    signal pixel_x, pixel_y : std_logic_vector(9 downto 0);
    signal video_on : std_logic;
    signal rgb_reg, rgb_next : std_logic_vector(2 downto 0);
    signal rgb : std_logic_vector(2 downto 0);
    signal p_tick : std_logic;
begin
    -- instantiate VGA sync
    vga_sync_unit : entity work.vga_sync
        port map(clk => clk, reset => reset, hsync => hsync, vsync => vsync, comp_sync => comp_sync, video_on => video_on, p_tick => p_tick, pixel_x => pixel_x, pixel_y => pixel_y);
    -- instantiate pixel generation circuit
    pong_grf_st_unit : entity
        work.pong_graph_st(Behavioral)
        port map(clk => clk, reset => reset, video_on => video_on, left_btn => btn(0), right_btn => btn(1) , up_btn => btn(2), down_btn => btn(3),  fire_btn => btn(4) , pixel_x => pixel_x, pixel_y => pixel_y, rgb_next => rgb_next);
    vga_pixel_tick <= p_tick;
    -- Set the high order bits of the video DAC for each
    -- of the three colors
    --rgb_8bit(7) <= rgb(0);
    --rgb_8bit(15) <= rgb(1);
    --rgb_8bit(23) <= rgb(2);
    rgb_top <= rgb;
    -- rgb buffer, graph_rgb is routed to the output through
    -- an output buffer -- loaded when p_tick = ?1?.
    -- This syncs. rgb output with buffered hsync/vsync sig.
    process (clk)
    begin
        if (clk'event and clk = '1') then
            if (p_tick = '1') then
                rgb_reg <= rgb_next;
            end if;
        end if;
    end process;
    rgb <= rgb_reg;
    blank <= video_on;
end arch;