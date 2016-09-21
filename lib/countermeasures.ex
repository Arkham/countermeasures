defmodule Countermeasures do
  use Application

  def start(_, _) do
    {:ok, laser} = Gpio.start_link(17, :output)
    Gpio.write(laser, 0)

    {:ok, buzzer} = Gpio.start_link(18, :output)
    Gpio.write(buzzer, 1)

    {:ok, sensors} = I2c.start_link("i2c-1", 0x48)

    {:ok, vibration} = Gpio.start_link(23, :input)

    spawn(fn -> loop(%{buzzer: buzzer, vibration: vibration, sensors: sensors}) end)

    IO.puts "Intrusion Countermeasures On!"

    {:ok, self}
  end

  def loop(%{buzzer: buzzer, vibration: vibration, sensors: sensors} = state) do
    :timer.sleep(100)

    value = read_sensor(sensors, 0)

    if value > 45 do
      IO.puts "Intruder detected: laser triggered! (#{value})"
      Gpio.write(buzzer, 0)
      loop(state)
    end

    value = read_sensor(sensors, 1)

    if value < 110 do
      IO.puts "Intruder detected: temp triggered! (#{value})"
      Gpio.write(buzzer, 0)
      loop(state)
    end

    value = Gpio.read(vibration)

    if value == 0 do
      IO.puts "Intruder detected: vibration triggered! (#{value})"
      Gpio.write(buzzer, 0)
      loop(state)
    end

    value = read_sensor(sensors, 2)

    if value < 110 do
      IO.puts "Intruder detected: noise triggered! (#{value})"
      Gpio.write(buzzer, 0)
      loop(state)
    end

    # no sensor triggered
    Gpio.write(buzzer, 1)
    loop(state)
  end

  defp read_sensor(pid, channel) do
    {channel_value, _} = Integer.parse("#{channel + 40}", 16)
    I2c.write(pid, <<channel_value>>)
    I2c.read(pid, 1)
    <<value>> = I2c.read(pid, 1)
    value
  end
end
