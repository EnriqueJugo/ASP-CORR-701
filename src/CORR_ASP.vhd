library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.TdmaMinTypes.all;

entity CORR_ASP is
  port (
    clock : in std_logic;
    send  : out tdma_min_port;
    recv  : in tdma_min_port
  );
end entity;

architecture beh of CORR_ASP is
  constant CORR_WINDOW_MAX : integer := 63; -- Max size of correlation window
  type ram_arr is array(0 to CORR_WINDOW_MAX) of signed(15 downto 0);
  signal ram : ram_arr := (others => (others => '0'));

  signal count : integer range 0 to CORR_WINDOW_MAX := 0;

  type corr_state is (s0, s1, s2, s3, send1, send2);
  signal state : corr_state := s0;

  signal corr_pair_product : signed(31 downto 0) := (others => '0');
  signal corr_temp         : signed(31 downto 0) := (others => '0');
  signal multiplicand      : signed(15 downto 0) := (others => '0');
  signal multiplier        : signed(15 downto 0) := (others => '0');

  signal counter   : integer range 0 to CORR_WINDOW_MAX / 2 := 0;
  signal corr_rdy  : std_logic                              := '0';
  signal calculate : std_logic                              := '0';

  signal corr_send_temp : signed(31 downto 0) := (others => '0');

  signal corr_window_int : integer range 0 to 63;

  signal enable      : std_logic;
  signal reset       : std_logic;
  signal dest        : std_logic_vector(3 downto 0);
  signal passthrough : std_logic;

begin

  write_ram : process (clock)
  begin
    if rising_edge(clock) then
      if (recv.data(31 downto 28) = "1000") then
        for i in 0 to CORR_WINDOW_MAX - 2 loop
          ram(i) <= ram(i + 1);
        end loop;
        ram(CORR_WINDOW_MAX - 1) <= signed(recv.data(15 downto 0));
      end if;
    end if;
  end process;

  -- | 31..28 | 27..24 | 23..20 | 19 | 18    | 17..12      | 11            |
  -- | type   | addr   |  dest  | en | reset | corr_window | passthrough   |
  config : process (clock)
  begin
    if (recv.data(31 downto 28) = "1101") then
      enable      <= recv.data(19);
      reset       <= recv.data(18);
      dest        <= recv.data(23 downto 20);
      passthrough <= recv.data(11);

      corr_window_int <= to_integer(unsigned(recv.data(17 downto 12)));
      send.addr       <= std_logic_vector(resize(unsigned(dest), tdma_min_addr'length));

    end if;
  end process;

  corr : process (clock, reset)
  begin
    if (reset = '1') then
      state          <= s0;
      corr_rdy       <= '0';
      corr_temp      <= (others => '0');
      corr_send_temp <= (others => '0');
      counter        <= 0;
    elsif rising_edge(clock) then
      if (recv.data(31 downto 28) = "1000") then
        if (passthrough = '1') then
          send.data <= x"8000" & recv.data(15 downto 0);
        else
          if (enable <= '1') then
            if (count < corr_window_int) then
              count <= count + 1;
            end if;

            if (count = corr_window_int) then
              calculate <= '1';
            end if;

            case state is
              when s0 =>
                corr_rdy          <= '0';
                corr_pair_product <= (others => '0');
                send.data         <= (others => '0');
                if calculate = '1' then
                  corr_temp <= (others => '0');
                  counter   <= 0;
                  state     <= s1;
                  calculate <= '0';
                end if;

              when s1 =>
                multiplicand      <= ram(corr_window_int / 2 + counter);
                multiplier        <= ram(corr_window_int / 2 - counter - 1);
                corr_pair_product <= multiplicand * multiplier;
                state             <= s2;

                -- Buffer to complete multiplication
              when s2 =>
                state <= s3;

              when s3 =>
                corr_temp <= corr_temp + corr_pair_product;
                if (counter >= (corr_window_int / 2 - 1)) then
                  corr_rdy       <= '1';
                  corr_send_temp <= corr_temp;
                  state          <= send1;
                else
                  counter <= counter + 1;
                  state   <= s1;
                end if;

              when send1 =>
                send.data <= recv.data(31 downto 16) & std_logic_vector(corr_send_temp(31 downto 16));
                state     <= send2;

              when send2 =>
                send.data <= recv.data(31 downto 16) & std_logic_vector(corr_send_temp(15 downto 0));
                state     <= s0;

            end case;
          end if;
        end if;
      end if;
    end if;
  end process;
end architecture;
