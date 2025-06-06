library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;

entity TestTopLevel is
  generic (
    ports : positive := 8
  );
end entity;

architecture sim of TestTopLevel is

  signal clock : std_logic := '1';

  signal send_port : tdma_min_ports(0 to ports - 1);
  signal recv_port : tdma_min_ports(0 to ports - 1);
  signal a         : std_logic_vector(7 downto 0);
  signal b         : std_logic_vector(7 downto 0);
begin

  clock <= not clock after 10 ns;

  tdma_min : entity work.TdmaMin
    generic map(
      ports => ports
    )
    port map
    (
      clock => clock,
      sends => send_port,
      recvs => recv_port
    );

  asp_adc : entity work.TestAdc
    generic map(
      forward => 2
    )
    port map
    (
      clock => clock,
      send  => send_port(0),
      recv  => recv_port(0)
    );

  corrout : entity work.TestCorrOut
    port map
    (
      clock => clock,
      send  => send_port(1),
      recv  => recv_port(1)
    );

  asp_dp : entity work.AspAvg
    generic map(
      forward    => 3,
      MAX_WINDOW => 100
    )
    port map
    (
      clock => clock,
      send  => send_port(2),
      recv  => recv_port(2)
    );

  cor_asp_inst : entity work.CORR_ASP
    port map
    (
      clock => clock,
      send  => send_port(3),
      recv  => recv_port(3)
    );

end architecture;
