library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;

entity CORR_ASP is
  port (
    clock : in std_logic;
    send  : out tdma_min_port;
    recv  : in tdma_min_port
  );
end CORR_ASP;

architecture arch of CORR_ASP is
  signal correlation : signed(31 downto 0) := (others => '0');

  type state_t is (calc, send_low);
  signal state : state_t := calc;

  signal corr_window_int : integer range 0 to 63;

  constant MAX_LAG : integer := 63;

  signal enable      : std_logic;
  signal reset       : std_logic;
  signal dest        : std_logic_vector(3 downto 0);
  signal passthrough : std_logic;
begin

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

  corr : process (clock)
    type array_type is array(0 to MAX_LAG) of signed(15 downto 0);
    type corr_array_t is array (0 to MAX_LAG) of signed(31 downto 0);
    variable signal_array : array_type          := (others => (others => '0'));
    variable sig          : signed(15 downto 0) := (others => '0');

    variable corr_arr : corr_array_t := ((others => (others => '0')));
  begin
    if reset = '1' then
      correlation <= (others => '0');
      corr_arr     := (others => (others => '0'));
      signal_array := (others => (others => '0'));
      send.data <= (others   => '0');
    else
      if (enable = '1') then
        if rising_edge(clock) then
          case state is
            when calc =>

              -- PASSTHROUGH
              if passthrough = '1' then
                send.data <= recv.data;
              else

                if recv.data(31 downto 28) = "1000" then

                  -- FIFO
                  for i in MAX_LAG downto 1 loop
                    signal_array(i) := signal_array(i - 1);
                  end loop;

                  -- Insert new value
                  signal_array(0) := signed(recv.data(15 downto 0));

                  corr_arr := (others => (others => '0'));
                  for i in 0 to MAX_LAG loop
                    corr_arr(i) := corr_arr(i) + (signal_array(0) * signal_array(i));

                    if i = corr_window_int then
                      exit;
                    end if;
                  end loop;

                  correlation <= corr_arr(corr_window_int);
                  send.data   <= x"8000" & std_logic_vector(correlation(31 downto 16));
                  state       <= send_low;
                end if;
              end if;

            when send_low =>
              send.data <= x"8000" & std_logic_vector(correlation(31 downto 16));
              state     <= calc;
          end case;
        end if;
      else
        send.data <= (others => '0');
      end if;
    end if;
  end process;

end architecture;
