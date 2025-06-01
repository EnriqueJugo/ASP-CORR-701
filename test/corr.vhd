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

  signal config_register_write_enable : std_logic;
  signal config_reset                 : std_logic;

  -- NOC -> COR CONFIG REGS
  signal config_enable             : std_logic_vector(0 downto 0);
  signal config_address            : std_logic_vector(3 downto 0);
  signal config_bit_mode           : std_logic_vector(1 downto 0);
  signal config_correlation_window : std_logic_vector(4 downto 0);
  signal config_adc_wait           : std_logic_vector(3 downto 0);
  signal config_passthru           : std_logic;

  -- COR CONFIG REGS -> COR
  signal registered_config_enable   : std_logic_vector(0 downto 0);
  signal registered_config_address  : std_logic_vector(3 downto 0);
  signal registered_config_bit_mode : std_logic_vector(1 downto 0);
  signal registered_config_adc_wait : std_logic_vector(3 downto 0);
  signal registered_config_passthru : std_logic;

  signal num_unaddressed : integer             := 0;
  signal index_right     : integer             := 0;
  signal index_left      : integer             := 0;
  signal correlation     : signed(31 downto 0) := (others => '0');

  signal sig_sig : std_logic_vector(15 downto 0);
begin

  send.addr <= std_logic_vector(to_unsigned(FORWARD, tdma_min_addr'length));

  process (clock)
    type array_type is array(0 to 31) of signed(15 downto 0);
    variable signal_array : array_type := (others => (others => '0'));
    variable flag         : std_logic  := '0';
    variable sig          : signed(15 downto 0);
  begin
    if rising_edge(clock) then

      -- First-time setup
      if flag = '0' then
        index_right <= (CORR_WINDOW + 1) / 2;
        index_left  <= ((CORR_WINDOW + 1) / 2) - 1;
        correlation <= (others => '0');
        flag := '1';

        else -- normal operation

        if recv.data(31 downto 28) = "1000" and recv.data(16) = '0' then
          -- Parse new signal data
          sig_sig <= (recv.data(15 downto 0));

          -- Shift FIFO
          for i in 31 downto 1 loop
            signal_array(i) := signal_array(i - 1);
          end loop;

          -- Insert new value
          signal_array(0) := signed(recv.data(15 downto 0));
          num_unaddressed <= num_unaddressed + 1;

          if num_unaddressed > 16 then
            -- Accumulate correlation
            if index_right < CORR_WINDOW and index_left >= 0 and index_left <= 31 and index_right <= 31 then
              correlation <= correlation + signal_array(index_right) * signal_array(index_left);
              index_right <= index_right + 1;
              index_left  <= index_left - 1;

              else -- Correlation done, send result
              send.data       <= address_constants.message_type_correlate & std_logic_vector(resize(correlation, 28));
              index_right     <= (CORR_WINDOW + 1) / 2;
              index_left      <= ((CORR_WINDOW + 1) / 2) - 1;
              num_unaddressed <= 0;
              correlation     <= (others => '0');
            end if;
          end if;

        end if;
      end if;
    end if;
  end process;

end architecture;
