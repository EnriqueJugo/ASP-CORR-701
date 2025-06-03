library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;

entity AspAvg is
  generic (
    forward    : natural; -- your existing address offset
    MAX_WINDOW : natural := 32 -- maximum number of samples supported
  );
  port (
    clock : in std_logic;
    send  : out tdma_min_port;
    recv  : in tdma_min_port
  );
end entity;

architecture sim of AspAvg is

  -- circular data buffer, size = MAX_WINDOW
  type data_array is array (0 to MAX_WINDOW - 1) of signed(15 downto 0);
  signal data_buf : data_array := (others => (others => '0'));

  signal idx : integer range 0 to MAX_WINDOW - 1 := 0;
  signal avg : signed(15 downto 0)               := (others => '0');

  -- dynamic config registers
  signal window_len_reg : integer range 1 to MAX_WINDOW := 1;
  signal avg_mode       : std_logic                     := '0'; -- '0'=moving, '1'=block

begin

  send.addr <= std_logic_vector(to_unsigned(forward, tdma_min_addr'length));

  -- 1) decode control packet, update window length & mode
  process (clock)
    variable wl : integer;
  begin
    if rising_edge(clock) then
      if recv.data(31 downto 28) = "1000" then
        wl := to_integer(unsigned(recv.data(27 downto 23))) + 1;
        if wl > MAX_WINDOW then
          wl := MAX_WINDOW;
        end if;
        window_len_reg <= wl;
        avg_mode       <= recv.data(22);
      end if;
    end if;
  end process;

  -- 2) averaging process
  process (clock)
    variable sum     : signed(31 downto 0);
    variable raw_avg : signed(31 downto 0);
    -- for block mode
    variable block_sum : signed(31 downto 0)           := (others => '0');
    variable block_cnt : integer range 0 to MAX_WINDOW := 0;
  begin
    if rising_edge(clock) then

      -- both modes sample from the same circular buffer
      if recv.data(31 downto 28) = "1000" then
        data_buf(idx) <= signed(recv.data(15 downto 0));
        idx           <= (idx + 1) mod MAX_WINDOW;

        -- MOVING AVERAGE (sliding window)
        sum := (others => '0');
        for j in 0 to MAX_WINDOW - 1 loop
          if j < MAX_WINDOW then
            sum := sum + resize(data_buf(j), sum'length);
          end if;
        end loop;
        raw_avg := sum / MAX_WINDOW;

        -- if (raw_avg > 4096) then
        --   raw_avg := to_signed(4096, raw_avg'length);
        -- elsif (raw_avg <- 4096) then
        --   raw_avg := to_signed(-4096, raw_avg'length);
        -- end if;

        avg <= resize(raw_avg, avg'length);

        -- send averaged result through NoC
        send.data <= x"8"
        & recv.data(27 downto 16)
        & std_logic_vector(resize(avg, 16));

      end if;
    end if;
  end process;

end architecture;
