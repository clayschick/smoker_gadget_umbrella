# SmokerGadget.Umbrella

Created the project using

```elixir
$ mix phx.new --umbrella --no-ecto smoker_gadget 
```

I created the Umbrella project because I could not get the Poncho project to build in a CI enviornment.

Then copied things from the smoker-gadget Poncho project.

The original README text is below

## Notes

### What to do next

- setup the Pi to use WIFI
- add an output graph to the UI
- find a box to put it all in and a way to hook into the grill - Try a cardboard box first
- keep updating the module and function docs
- write some unit tests
-- test the PID controller output - Done
-- test the Temperature read?
-- test the Fan adjustment?

- fix the livereload - don't know if I care

- add specs and dialyix - Done
- add more configuration - Done
-- PWM pin and frequency
-- pid_out multiplier
- add callbacks to PWM behaviour module and implement in the PWM module - Done
- build the docs and cleanup any exposed private or adapter modules - Done
- design the app - Done, but is this ever really done?
- figure out a way to profile a Nerves app - Done, can use observer over remote console
- buy a PWM fan like the Corsair SL series - Done


#### Reading from the RTD

The below example is setting the config register (0x80) and then reading from the data register (0x01).

Also, note the extra 8-bits of binary in the read transfer because I have to send as many bytes as I expect to receive and the RTD returns an extra byte at the beginning of the return binary.

```
iex(smokergadget@nerves.local)8> Circuits.SPI.transfer(ref, <<0x80, 0xB0>>)
{:ok, <<0, 0>>}
iex(smokergadget@nerves.local)9> Circuits.SPI.transfer(ref, <<0x01, 0x00, 0x00>>)
{:ok, <<0, 64, 182>>}
iex(smokergadget@nerves.local)10> Circuits.SPI.transfer(ref, <<0x80, 0xB0>>)
{:ok, <<0, 0>>}
iex(smokergadget@nerves.local)11> Circuits.SPI.transfer(ref, <<0x01, 0x00, 0x00>>)
{:ok, <<0, 64, 192>>}
```

In the adafruit python libray they:
- clear the faults by writting 146 to the config register
- sets the bias to true by writting 144 to the config register
-- this can be done once on initial config because I don't care about turning it on and off
- configure the chip for a one-shot data read by writting 176 to the config register
- read 16bits from register 0x01

## 12v fan driver

### Scematic

![Schematic](Pwm_driver_stripboard.png)

### Parts list

- Q1: any small N-channel MOSFET (e.g. 2N7000/BS170) _have some sort of MOSFET_
- C1: 0.1 uF electrolytic capacitor _think I have it_
- R1: 10 kΩ resistor - _have it_
- D1: Any small rectifier diode - _have it_
- 12v power supply or lifepo4 battery pack
- 12v PWM fan (like Corsair SL120 or something with high static pressure) or blower fan

## App design

The SPI and PWM modules are just modules (they are not GenServers or anything special) that I can load up as two Tasks since there is no state to store that must be accessed by different processes or by the same process at different points in time. I don't need to call Agent functions like `get_and_update` to affect state.

They could each be a supervised task.


## App development

Development run command:

```elixir
MIX_TARGET=host MIX_ENV=dev iex -S mix
```

Webpack will run as long as npm is available to run the node server

Current compile and deploy command:

```elixir
MIX_TARGET=rpi0 MIX_ENV=prod mix firmware && ./upload.sh 172.30.52.241 ./_build/rpi0/rpi0_prod/nerves/images/fw.fw
```

Rebuild the UI assets using this command from the ui/assets directory:

```elixir
npm run deploy
```

If this is a fresh clone of the app run `mix deps.get` from the ui dir so that the phoenix dep is installed.

Also run `npm install`.


This build uses the _nerves_init_gadget_ - https://github.com/nerves-project/nerves_init_gadget

Pretty much just followed the instructions for a new project.

Make sure to `export MIX_TARGET=rpi0`

I did `mix local.nerves` to update the Nerves archive.

Then ran:
```
$ mix nerves.new smokergadget --init-gadget
$ mix deps.get
$ mix firmware
$ mix firmware.burn
OR
$ mix firmware.burn -d /dev/sdb
```

Then stick the card in and boot using the USB console cable w/power.

Can also run a super command:
```
mix do deps.clean pigpiox, deps.get, compile && mix firmware && ./upload.sh 172.30.52.241
```

The above command first cleans, gets, and compiles the pigpiox dependency that I have been hacking on locally in order to try and add SPI support. That part of the command is not needed unless I'm doing library development.

## App Shutdown and Reboot

Using `Nerves.Runtime` library that somes with the _reboot_ and _shutdown_

```elixir
iex(15)> Nerves.Runtime.halt
```

## Network Configuration

See https://github.com/nerves-project/nerves_init_gadget#configuration

## Network Access

It took a few tries before I was able to get a response from `ping nerves.local`

```
ssh nerves.local
```

To exit the SSH session, type `~.`


## Network Deployment

I had to use the `upload.sh` script from nerves_firmware_ssh

```
$ mix firmware.gen.script
```

To deploy the changes do:
```
$ mix firmware
$ ./upload.sh <destination IP>
```
- Get the destination IP from the `ping` response - can also try using `nerves.local`
- Second arg is file path that defaults to the right place - `find . -name smokergadget.fw`

### Remote Update - Does not work without nerves_firmware_http which conflicts with nerves_firmware_ssh

POST the `_images/rpi3/fw.fw` file to `<board's ip>:8988/firmware'`. Example (using [httpie](https://httpie.org/)):
```
http POST 172.30.52.241:8988/firmware content-type:application/x-firmware x-reboot:true < _build/rpi0/dev/nerves/images/smokergadget.fw
```

## Remote Shell

Change `rel/vm.args` to:

```
-name smokergadget@nerves.local
-setcookie secret
```

Note the static IP of the pi - surly there is a better way to handle that!

Check `:runtime_tools` is in `mix.exs`:

```
  def application do
    [
      mod: {SmokerGadget.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end
```

#### using `:observer`

Start a hidden IEx session:

```
iex --name observer@172.30.52.242 --cookie secret
```
You will drop to a normal iex shell. Then run `:observer.start`. A GUI interface will open. In that GUI, go to `Nodes`->`connect`. Insert the *name* of the node, i.e the string after `-name` option in the `rel/vm.args` file. If everything is correct, it should connect and you will be able to see the apps in the *Applications* tab.

#### `remsh` (or the Erlang's `ssh`)

```
iex --name host@172.30.52.242 --remsh smokergadget@nerves.local --cookie secret
```
You will drop to the board's shell.

NOTE: the IP of the host is the local IP assigned to the usb gadget `en` network found when running `ifconfig`

## Pigpiox Library

Trying out the Pigpiox library https://hexdocs.pm/pigpiox/Pigpiox.html

* PWM module works like a champ so far

Using the Circuits.SPI module for SPI access

- I'd like to add SPI to pigpiox
- I've been working on this but it doesn't seem worth while

### Using the PWM module

Connect the pi using `ssh nerves.local`

Put a resistor in series with an LED

I'm using pin 12 (BCM 12 - PWM0)

Need to figure out the exact numbers I need to use for duty and frequency.

```elixir
iex(4)> alias Pigpiox.Pwm
Pigpiox.Pwm
Pwm.hardware_pwm(12, 8000, 10000)
:ok
```

## Circuits.SPI Library

ElixirALE was it's predecessor.

Uses a NIF. Would be cool if there was a NIF for PWM. Could I create one by stealing the code from the pigpiod python library?

### Using the SPI module to access Max31865 registers

SPI bus options (spi_opts parameter) include:
  * `mode`: This specifies the clock polarity and phase to use. (0)
  * `bits_per_word`: bits per word on the bus (8)
  * `speed_hz`: bus speed (1000000)
  * `delay_us`: delay between transaction (10)

Parameters:
  * `devname` is the Linux device name for the bus (e.g., "spidev0.0")
  * `spi_opts` is a keyword list to configure the bus
  * `opts` are any options to pass to GenServer.start_link

The configuration options for the serial connection to the max31865
chip. Taken from the datasheet and picked up from other libaries
for other languages, as an example.

  * The MAX31865 supports SPI modes 1 (polarity 0, phase 1) and 3
  * Everything says 50Hz/60Hz - other libaries use 500000
  * Leave the word size at 8 because all the registers are 8-bit

To connect to the SPI device.

```elixir
{:ok, ref} = Circuits.SPI.open("spidev0.0", mode: 1, speed_hz: 500_000)
```

Set the initial config.

```elixir
Circuits.SPI.transfer(ref, <<0x80, 0x90>>)
```

Can read the config to confirm. Ignore the first byte.

```elixir
Circuits.SPI.transfer(ref, <<0x00, 0x00>>)
{:ok, <<0, 144>>}
```
To read from the data registers set the config for a one-shot transfer

```elixir
Circuits.SPI.transfer(ref, <<0x80, 0xB0>>)
```

Then read the data registers.

```elixir
{:ok, <<_::size(8), digits::size(15), fault_bit::size(1)>>} =
      Circuits.SPI.transfer(ref, <<0x01, 0x00, 0x00>>)
```
This will return the value used to compute the resistance which can be used to compute the temperature.


## Troubleshooting

I added Nerves.Runtime.Shell as a dependency which gives you basic shell access from iex.

```elixir
iex(1)> Nerves.Runtime.Shell.start
```

### Logging

Using [RingLogger](https://github.com/nerves-project/ring_logger) which allows logging in a remote shell which `:console` cannot do.

To see log messages in the console use the `RingLogger.attach\0` and `RingLogger.detach\0` functions.

Or use these when unattached:

```elixir
iex(1)> RingLogger.next
```

```elixir
iex(1)> RingLogger.tail
```

```elixir
iex(1)> RingLogger.grep(~r/[Ee]rror/)
```

### If Application won't start

The device will still run even if the mix application will not start.

The arguments I was giving in the child spec when starting the ElixirAle.SPI Gensever
under a supervisor was causing the whole application to fail to start. I had no idea. I was
connecting to the IEx shell via ssh and and kept getting a `nil` when running `Process.whereis(SmokerGadget.SPISupervisor)`.
Plus the modules were not showing up when running `Process.registered()`.

Start the application and see what module is failing to load and the reason.

```elixir
iex(smokergadget@nerves.local)1> Application.ensure_all_started(:smokergadget)
{:error,
 {:smokergadget,
  {{:shutdown,
    {:failed_to_start_child, SmokerGadget.SPISupervisor,
     {%ArgumentError{
        message: "supervisors expect each child to be one of the following:\n\n  * a module\n  * a {module, arg} tuple\n  * a child specification as a map with at least the :id and :start fields\n  * or a tuple with 6 elements generated by Supervisor.Spec (deprecated)\n\nGot: {ElixirALE.SPI}\n"
      },
      [
        {Supervisor, :init_child, 1, [file: 'lib/supervisor.ex', line: 656]},
        {Enum, :"-map/2-lists^map/1-0-", 2, [file: 'lib/enum.ex', line: 1314]},
        {Supervisor, :init, 2, [file: 'lib/supervisor.ex', line: 625]},
        {:supervisor, :init, 1, [file: 'supervisor.erl', line: 295]},
        {:gen_server, :init_it, 2, [file: 'gen_server.erl', line: 374]},
        {:gen_server, :init_it, 6, [file: 'gen_server.erl', line: 342]},
        {:proc_lib, :init_p_do_apply, 3, [file: 'proc_lib.erl', line: 249]}
      ]}}}, {SmokerGadget.Application, :start, [:normal, []]}}}}
```

## Learn more

  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: http://www.nerves-project.org/
  * Discussion Slack elixir-lang #nerves ([Invite](https://elixir-slackin.herokuapp.com/))
  * Source: https://github.com/nerves-project/nerves

## Mistakes

## PWM overlay

NOTE: Don't need none of the shit in this section!

Just use a regular old firmware version for rpi0.

Info about the overlays provided in the base image is provided in the README
- https://github.com/raspberrypi/firmware/blob/master/boot/overlays/README

The overlay file `pwm.dtbo` is already included with the rpi0 images in `~/.nerves/artifacts/nerves_system_rpi0-portable-1.5.0/images/rpi-firmware/overlays`

### Steps involved:

1. Update config/config.exs - add location of custom fwup.conf file:

```elixir
config :nerves, :firmware,
  rootfs_overlay: "rootfs_overlay",
  fwup_conf: "config/fwup.conf"
```

2. Copy fwup.conf from `~/.nerves/artifacts/nerves_system_rpi0-portable-1.5.0/images` and add:

- Link to custom config.txt 
- TODO: figure out how to use ${NERVES_APP} variable - ${NERVES_APP}/config/config.txt
```
file-resource config.txt {
    host-path = "/Users/clayschick/Development/embedded/smokergadget/config/config.txt"
}
```

- Link to the overlay
```
file-resource pwm.dtbo {
    host-path = "${NERVES_SYSTEM}/images/rpi-firmware/overlays/pwm.dtbo"
}
```

- Finally add partition offest resources 
- NOTE: 3 locations in file
```
task complete {
  n-resource pwm.dtbo { fat_write(${BOOT_A_PART_OFFSET}, "overlays/pwm.dtbo") }
}

task upgrade.a {}
  on-resource pwm.dtbo { fat_write(${BOOT_A_PART_OFFSET}, "overlays/pwm.dtbo") }
}

task upgrade.b {}
  on-resource pwm.dtbo { fat_write(${BOOT_B_PART_OFFSET}, "overlays/pwm.dtbo") }
}
```

3. Copy config.txt from `~/.nerves/artifacts/nerves_system_rpi0-portable-1.5.0/images` and add:

```
dtoverlay=pwm
```

The below statement is not true!
- PWM works just fine even though the `grep` below will not return anything

From the shell you can run `dmseg | grep pwm`

