library ieee;
use ieee.std_logic_1164.all;

package address_constants is

  constant message_type_config      : std_logic_vector := "1010";
  constant message_type_signal      : std_logic_vector := "1000";
  constant message_type_correlate   : std_logic_vector := "1001";
  constant message_type_peak_detect : std_logic_vector := "1111";
  constant message_type_adc         : std_logic_vector := "";

end package; -- common_network_addresses