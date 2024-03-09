const std = @import("std");

// Driver: GPIO
//
// This is a basic gpio pin driver that has been specifically designed for the
// Raspberry Pi 4B (and written in Zig!). The drivers makes the following guarantees:
//      1. Zero-Allocation: Out of the box, all 57 pins are usable without zero allocations
//                          being required!
//
//      2. No Assumptions:  There are no assumptions about the environment
//                          that the driver is operating in (which can be limiting, but
//                          there will be an interrupt-able version at some point).
//

// constants
const gpio_base = 0xfe_200_000;
const offset_fsel_base = 0x00;
const offset_set_base = 0x1c;
const offset_clear_base = 0x28;
const offset_read_base = 0x34;

// compile time allocation of the all supported raspberry pi 4
// gpio pins.
pub const Pins: [58]Pin = for (0..1) |_| {
    var dummy_array: [58]Pin = undefined;
    for (0..58) |i| {
        dummy_array[i] = CreatePin(i);
    }

    break dummy_array;
};

// represents a gpio pin's characteristics, all information was
// taken directly from the datasheet.
//
// (Page. 65)
// https://datasheets.raspberrypi.com/bcm2711/bcm2711-peripherals.pdf
const Pin = struct {
    // attributes
    n: u6,                                      // the pin number
    pin_type: PinFunction = PinFunction.None,   // the pin's set function

    // in-memory registers as pointers, actual addresses
    // are calculated with the CreatePin function.
    fsel: *align(4) u32,
    set: *align(4) u32,
    clear: *align(4) u32,
    level: *align(4) u32,

    // configures this pin with a given function type
    pub fn FuncSelect(self: @This(), pin_type: PinFunction) !void {
        // this is done so that the compiler can be assured that the shifted
        // amount won't lead to undefined behavior.

        const shift_am: u5 = @truncate((self.n % 10) * 3);
        //                                                ^^ is the max number that can 
        //                                                   be represented in the register
        const value: u32 = 0 | @intFromEnum(pin_type);

        self.pin_type = pin_type;
        self.fsel.* |= (value << shift_am);
    }

    // sets the pin to "high"
    pub fn Set(self: @This()) PinError!void {
        try self.HasFunctionBeenSet();
        if (self.pin_type == PinFunction.Input) {
            // we do check to make sure that we are not setting a pin that
            // has been designated as an input.
            return PinError.ErrIncorrectPinFunction;
        }

        const shift_am: u5 = @truncate((self.n % 32));
        self.set.* |= (0b1 << shift_am);
    }

    // sets the pin to "low"
    pub fn Clear(self: @This()) !void {
        try self.HasFunctionBeenSet();
        if (self.pin_type == PinFunction.Input) {
            // we do check to make sure that we are not setting a pin that
            // has been designated as an input.
            return PinError.ErrIncorrectPinFunction;
        }

        const shift_am: u5 = @truncate((self.n % 32));
        self.clear.* |= (0b1 << shift_am);
    }

    // performs a basic "read" of the pin.
    pub fn Read(self: @This()) !u1 {
        const shift_am: u5 = @truncate((self.n % 32));
        const returned_value: u1 = 0b1 & (self.level.* >> shift_am);
        return returned_value;
    }

    // enforces that the programmer must consciously set a function to the
    // pin they are trying to use. There is no direct enforcement between the
    // action they are doing and the function that's been selected, since
    // ALT function may also require setting and clearing and this gets the
    // point of safety across without sacrificing readability.
    fn HasFunctionBeenSet(self: @This()) PinError!void {
        if (self.pin_type == PinFunction.None) {
            // we want to explicitly define the pin's function,
            // not doing so may cause potentially unexpected behavior.
            return PinError.ErrPinFunctionNotSet;
        }
    }
};

// a helper function that creates pins at compile time.
fn CreatePin(n: u6) Pin {
    // the following variable(s) are made to help with readability, but can be
    // inlined.
    const singleBitGranularityOffset = CalculateOffset(n, 1);

    return Pin{
        .n = n,
        .fsel = @ptrFromInt(gpio_base + offset_fsel_base + CalculateOffset(n, 3)),
        .set = @ptrFromInt(gpio_base + offset_set_base + singleBitGranularityOffset),
        .clear = @ptrFromInt(gpio_base + offset_clear_base + singleBitGranularityOffset),
        .level = @ptrFromInt(gpio_base + offset_read_base + singleBitGranularityOffset),
    };
}

// helper funtion to calculate the offset from a register base
// from a known pin number and data granularity.
fn CalculateOffset(pin: u6, data_granularity: u6) u32 {
    // a gpio register represents the state of 'x' number of pins.
    // we know 'x' to be 32 / data_granularity (where data_granularity
    // is the number of bits it takes to represent that 'state')
    //
    // therefore we calculate the offset by taking the pin number and
    // dividing it by 'x'; we then find the byte offset by multiplying
    // by 4 (32 bits).
    return (pin / ((32 / data_granularity))) * 4;
}

// gpio pins must first be configured for a specific function.
// the different categories of functions are listed below and
// can be found in the documentation:
//
// (Page. 67)
// https://datasheets.raspberrypi.com/bcm2711/bcm2711-peripherals.pdf
const PinFunction = enum(u3) {
    None = 0b0,
    Input = 0b000,
    Output = 0b001,
    ALT0 = 0b100,
    ALT1 = 0b101,
    ALT2 = 0b110,
    ALT3 = 0b111,
    ALT4 = 0b011,
    ALT5 = 0b010,
};

// in an effort to use zig errors as part of the drivers, this error set 
// contains errors that can be encountered when operating with the pins.
const PinError = error{
    ErrPinFunctionNotSet,
    ErrIncorrectPinFunction,
};

test "offset calculation is correct" {
    const test_pins = [_]u6{ 2, 9, 17, 21, 39, 40, 57 };
    const test_offsets = [_]u8{ 0, 0, 4, 8, 0xc, 0x10, 0x14 };

    for (test_pins, test_offsets) |pin, offset| {
        const calculated_offset = CalculateOffset(pin, 3);
        try std.testing.expect(calculated_offset == offset);
    }
}
