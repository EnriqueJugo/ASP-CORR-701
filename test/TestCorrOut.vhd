library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;

entity TestCorrOut is
  port (
    clock : in std_logic;
    send  : out tdma_min_port;
    recv  : in tdma_min_port
  );
end entity;

architecture sim of TestDac is

  signal channel_0          : signed(31 downto 0) := (others => '0'); -- now 32-bit
  signal temp_data          : signed(15 downto 0) := (others => '0'); -- stores first packet
  signal waiting_for_second : std_logic           := '0';

begin

  process (clock)
  begin
    if rising_edge(clock) then
      if recv.data(31 downto 28) = "1000" then
        if waiting_for_second = '0' then
          -- First 16-bit packet received
          temp_data          <= signed(recv.data(15 downto 0));
          waiting_for_second <= '1';
        else
          -- Second 16-bit packet received: combine both
          channel_0          <= temp_data & signed(recv.data(15 downto 0));
          waiting_for_second <= '0';
        end if;
      end if;
    end if;
  end process;

end architecture;
