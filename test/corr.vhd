library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_1164.all;

use work.address_constants;
library work;
use work.TdmaMinTypes.all;

entity cor_asp is
  generic (
    FORWARD     : natural;
    CORR_WINDOW : integer := 10
  );
  port (
    clock : in std_logic;
    send  : out tdma_min_port;
    recv  : in tdma_min_port
  );
end cor_asp;

architecture arch of cor_asp is
  signal correlation : signed(31 downto 0) := (others => '0');

  type state_t is (calc, send_low);
  signal state : state_t := calc;
begin

  send.addr <= std_logic_vector(to_unsigned(FORWARD, tdma_min_addr'length));

  process (clock)
    type array_type is array(0 to CORR_WINDOW) of signed(15 downto 0);
    type corr_array_t is array (0 to CORR_WINDOW) of signed(31 downto 0);
    variable signal_array : array_type          := (others => (others => '0'));
    variable corr_accum   : signed(31 downto 0) := (others => '0');
    variable sig          : signed(15 downto 0) := (others => '0');

    variable corr_arr : corr_array_t := ((others => (others => '0')));
  begin
    if rising_edge(clock) then
      case state is
        when calc =>
          if recv.data(31 downto 28) = "1000" then
            for i in CORR_WINDOW downto 1 loop
              signal_array(i) := signal_array(i - 1);
            end loop;

            -- Insert new value
            sig             := signed(recv.data(15 downto 0));
            signal_array(0) := sig;

            corr_arr := (others => (others => '0'));
            for i in 0 to CORR_WINDOW loop
              corr_arr(i) := corr_arr(i) + (signal_array(0) * signal_array(i));
            end loop;

            correlation <= corr_arr(CORR_WINDOW);
            send.data   <= x"8000" & std_logic_vector(correlation(31 downto 16));
            state       <= send_low;
          end if;

        when send_low =>
          send.data <= x"8000" & std_logic_vector(correlation(31 downto 16));
          state     <= calc;
      end case;
    end if;
  end process;

end architecture;
