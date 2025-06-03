library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.TdmaMinTypes.all;

entity auto_correlator_asp is
  generic (
    window_size : natural := 10 -- Must be even for symmetric correlation
  );
  port (
    clock       : in std_logic := '0';
    network_in  : in tdma_min_port;
    network_out : out tdma_min_port
  );
end auto_correlator_asp;

architecture behaviour of auto_correlator_asp is
  type buffer_type is array (0 to window_size - 1) of std_logic_vector(15 downto 0);
  signal buf                : buffer_type;
  signal index              : integer range 0 to window_size - 1 := 0;
  signal autocorr           : SIGNED(15 downto 0)                := (others => '0');
  signal next_address       : std_logic_vector(3 downto 0);
  signal config             : std_logic_vector(3 downto 0) := "0001";
  signal update_network_out : std_logic                    := '0';
  signal cleared            : std_logic                    := '0';
begin

  process (clock)
    variable temp_autocorr : SIGNED(31 downto 0);
    variable k             : integer;
    variable upper_16_bits : std_logic_vector(15 downto 0);
    variable mult_result   : SIGNED(63 downto 0);
  begin
    if rising_edge(clock) then
      if config = "0000" and cleared = '0' then
        for i in 0 to window_size - 1 loop
          buf(i) <= x"0000";
        end loop;
        index    <= 0;
        autocorr <= x"0000";
        cleared  <= '1';
      end if;

      if network_in.data(31 downto 28) = "1010" then
        next_address <= network_in.data(23 downto 20);
        config       <= network_in.data(19 downto 16);
      end if;

      if network_in.data(31 downto 28) = "1000" and config = "0001" then
        buf(index) <= network_in.data(15 downto 0);
        index      <= (index + 1) mod window_size;

        temp_autocorr := (others => '0');

        for k in 0 to (window_size / 2) - 1 loop
          mult_result := RESIZE(signed(buf((index + k) mod window_size)), 32) *
          RESIZE(signed(buf((index + window_size - 1 - k) mod window_size)), 32);
          temp_autocorr := temp_autocorr + mult_result(31 downto 0);
        end loop;
        autocorr         <= temp_autocorr(31 downto 16);
        network_out.addr <= "0000" & next_address;
        network_out.data <= "1000000000000000" & std_logic_vector(autocorr);
      end if;
    end if;
  end process;
end architecture;