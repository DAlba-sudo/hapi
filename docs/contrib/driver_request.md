## Driver Request: < Insert Driver Type >

> < Insert TLDR for what hardware the driver seeks to provide access to and any features that you'd like to see in it (i.e., zero-alloc, certain memory constraints, etc)>

### Targeted Hardware

The following section describes the hardware that the driver seeks to target.

**Hardware:** <Example: GPIO>

- Link To Datasheet/Resources: [BCM2711](https://datasheets.raspberrypi.com/bcm2711/bcm2711-peripherals.pdf) *(Page: 65)*.

### Desired Features

The following section describes the desired features and or constraints the driver must accomodate.

- [ ] Feature #1
- [ ] Feature #2
- [ ] Feature #3

### Basic Driver API

*This is not meant to be exhaustive, just meant to show some consideration as to how the driver(s) are made and allows for proper review/documentation.*

The following section describes the API that the driver seeks to provide to the user. This is considered a critical aspect of driver design and should be specified *before writing any production-level code*.

> feel free to code something up to help figure out what API/abstraction makes sense!

```Zig
// I only really care about function declarations, 
// no need to fill out the actual struct
//
// Replace all this with your actual code! 
const Pin = struct {...}

// Function List
Pin.Set() PinError!void
Pin.Clear() PinError!void
Pin.FuncSelect(PinFunction) void 
```