<img src="./assets/animation.gif">

<br>

>  All right, look. First of all, with the grain. With the grain. You see what I'm doing here? You let the tool do the work, you see? Just like you're riding the wave, you let the wave do the work. You don't fight the wave. You can't fight these big waves. 
>
> \- Big Z, Surf's Up (2007)

### Description

A Zig-like set of drivers for the Raspberry Pi 4B. Currently supported drivers are: [`gpio`](/src/gpio.zig).

### Library Guarantees
* **Zero-Allocation in Runtime**: We take advantage of Zig's comptime semantics to allow for a fully comptime allocation set of drivers. This means you can use these drivers in environments where you don't have an allocator! 
* **Low Performance Overhead**: We make sure to use ARMv8 instructions when the compiler doesn't include them, plus with our comptime guarantee, most of our driver operations are loads and stores!
* **Guaranteed Memory Safety**: We guarantee that use of our drivers will make the compiler complain! If you're using the zig compiler, it will detect out of bounds and illegal values in places you might not expect (this is because we use exact typing for all our inputs and outputs).
* **Runtime Error-Aware Drivers**: We provide some runtime error primitives where it makes sense. This allows you to use zig's error related features in places that you traditionally couldn't with languages like `C`.

## How to use it?

We are currently working with: `v0.12.0-dev.3090+f5aad4728`.

```
// inside of build.zig

// add the module 
const hapi = b.addModule("hapi", .{
    .root_source_file = .{
        .path = "./src/hapi/src/root.zig"
    }
});

...
...
...

// add the module to the executable you are working with.
exe.root_module.addImport("hapi", hapi);
```