# ExperimentalOs


This is what GRUB looks for in your binary to identify it as a multiboot-compliant kernel.

Multiboot Header Fields(defined in loader.s)
```
|Field     |Value             |Description                                     |
|----------|------------------|------------------------------------------------|
|`MAGIC`   |`0x1BADB002`      |Required magic number for Multiboot             |
|`FLAGS`   |`0x3`             |Bit 0: Align modules, Bit 1: Provide memory info|
|`CHECKSUM`|`-(MAGIC + FLAGS)`|Must make the sum of all three fields = 0 (for  validation)|
```
This header must appear within the first 8 KiB of the kernel binary so GRUB can find it.

--------------------------------------------------------------------------------------
<h3>Stack Setup Before <a>KernelMain</a></h3>
<h5> Diagram: Stack Before Calling <a>kernelMain</a></h5>
```pgsql
+--------------------+
|   kernel_stack     | <- esp is set to here
+--------------------+
|   %eax (magic)     | <- pushed before call
+--------------------+
|   %ebx (mb_struct) | <- pushed before call
+--------------------+
| return address     | <- inserted by call
+--------------------+
```
The call stack will look like this when [kernelMain(void* mb, uint32_t magic)] is called. This matches the function signature exactly.
_____________________________________________________
<h3>How Segment Selectors Work Internally</h3>
```
|Bits |Meaning                  |
|-----|-------------------------|
| 0–1 |Requested privilege level|
|  2  |Table Indicator (GDT/LDT)|
| 3–15|Index into GDT table     |
```

So 0x80 means:
- Index = 1(i.e. second entry, which is [codeSegmentSelector])
- TI = 0 (GDT)
- RPL  0 (Kernel mode)
| Selector = (index * 8) + (Tl << 2) + RPL
__________________________________________________________________________
<h3>How <a>lgdt</a> Loads the GDT</h3>
```cpp
uint32_t i[2];
i[0] = (uint32_t)&nullSegmentSelector;
i[1] = sizeof(GlobalDescriptorTable) << 16;

asm volatile("lgdt (%0)" : : "p" (((uint8_t *) i)+2));
```

<h5>Why <a>((uint8_t*)i)+2</a>?</h5>
Because the CPU expects this structure:
```c
struct {
   uint16_t size;
   void* address;
}
```
You're manually packing that into i:
```
|Index|        Value       |          Notes         |
|-----|--------------------|------------------------|
|i[0] |address of GDT table|(will go to offset +2)  |
|i[1] |size of GDT << 16   |lower 16 bits = GDT size|
```
```lua
0x00000000 ------------------------> Real Mode Memory (BIOS, IVT)
0x0009FC00 ------------------------> End of usable conventional memory
0x000A0000 - 0x000FFFFF -----------> Reserved (VGA, ROM BIOS, etc.)
0x00100000 ------------------------> Kernel loaded by GRUB (1 MB)
              |
              |--- .text (code)
              |--- .rodata
              |--- .data
              |--- .bss (includes kernel stack)

```
