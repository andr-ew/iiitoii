# iiitoii

 a collection of [iii](https://monome.org/docs/iii/) community scripts ported to norns + crow. available as a standalone script and as a [mod](https://monome.org/docs/norns/mods/).

 currently in * beta *

## hardware

**required**

- [norns](https://github.com/p3r7/awesome-monome-norns)
- [crow](https://monome.org/docs/crow/)
- [grid](https://monome.org/docs/grid/) (128 or 256) or [arc](https://monome.org/docs/arc) (any 4 rings supported, 2025 edition recommended)

**also supported**

- ii devices

## install

install from the maiden catalog

 ## docs
 - **E1:** select script
 - **K2:** same as built-in arc button

### as a mod

first, [enable](https://monome.org/docs/norns/mods/#enabling--disabling-a-mod) the mod. then, load a script. be sure that the script does not use the monome device you are planning to use (arc/grid). there should be an "iiitoii" section in the params list - here you can select the desired script & access the arc button if needed

iii script settings are saved & recalled across norns scripts & psets

### scripts

#### cycles [[original](https://monome.org/docs/iii/library/cycles)]

position values sent to crow outputs 1-4, fixed to 0-7 volts. min, max, cc, and channel pages are removed

#### snows [[original](https://monome.org/docs/iii/library/snows)]

volt/octave for each ring at crow outputs 1-4

#### just-snow

based on the suggestion by tehn — snows, but note changes are sent to a sustaining just friends (identity - 4n). led position is at crow outputs 1-4, same as cycles. I recommend patching these to VCAs modulating the levels of first four outs of jf. button accesses the same menu functions from cycles

#### (forthcoming) erosion

## TODO

- top-level option to communicate with a second ii-connected crow, in place of the usb-connected crow (which would be freed up for use by a running script)
- maybe terminal print-outs from the iii script can show up on screen, like in diii
- add grid functions to adapter layer
- support running both grid & arc scripts at once, maybe device selection & using multiples of each device


## adding a script

! contributions welcome !

a partial adapter for iii's new api has been created to ease conversion from iii. see `lib/loader`. this doesn't currently cover all functions, and may need to be expanded as iii is updated (contributions welcome).

when running as a mod global variables are also safe within the script files as they are run in a sandbox

also note the new `cleanup` callback & `iiitoii` class for interacting with crow voltages
