library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;

entity AspDp is
  generic (
    forward : natural
  );
  port (
    clock : in std_logic;
    send  : out tdma_min_port;
    recv  : in tdma_min_port
  );
end entity;

architecture sim of AspDp is
  type state is (INIT, DATA_ONE, DATA_TWO, DATA_THREE, DATA_FOUR);

  signal avg : signed(15 downto 0);
  type data_array is array (0 to 3) of signed(15 downto 0);

  signal data_count : state      := INIT;
  signal data       : data_array := (others => (others => '0'));
begin
  send.addr <= std_logic_vector(to_unsigned(forward, tdma_min_addr'length));
  process (clock)

    variable average : signed(15 downto 0) := (others => '0');
  begin
    if (rising_edge(clock)) then
      if (recv.data(31 downto 28) = "1000") then
        if (data_count = INIT) then
          data_count <= DATA_ONE;
        elsif (data_count = DATA_ONE) then
          average := (data(0) + data(1) + data(2) + data(3)) / 4;

          average := average sll 1;

          if (average > 4096) then
            average := to_signed(4096, average'length);
          elsif (average <- 4096) then
            average := to_signed(-4096, average'length);
          end if;
          avg <= average;

          send.data <= x"8" & recv.data(27 downto 16) & std_logic_vector(average(15 downto 0));
          data(0)   <= signed(recv.data(15 downto 0));

          data_count <= DATA_TWO;
        elsif (data_count = DATA_TWO) then
          data(1) <= signed(recv.data(15 downto 0));

          data_count <= DATA_THREE;
        elsif (data_count = DATA_THREE) then
          data(2) <= signed(recv.data(15 downto 0));

          data_count <= DATA_FOUR;
        elsif (data_count = DATA_FOUR) then
          data(3) <= signed(recv.data(15 downto 0));

          data_count <= DATA_ONE;
        end if;

      end if;
    end if;
  end process;

end architecture;
