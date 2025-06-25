
#  ExperimentalOS

A lightweight experimental kernel written in C++ and assembly. This documentation explains key parts of the boot process, multiboot header, stack setup, and GDT configuration used to enter protected mode.

---

##  Multiboot Header (Defined in `loader.s`)

GRUB loads a kernel only if it contains a valid Multiboot header.

| Field      | Value             | Description                                      |
|------------|------------------|--------------------------------------------------|
| `MAGIC`    | `0x1BADB002`      | Required magic number for Multiboot              |
| `FLAGS`    | `0x3`             | Bit 0: Align modules, Bit 1: Provide memory info |
| `CHECKSUM` | `-(MAGIC + FLAGS)`| Makes the sum of all 3 fields = 0 (validation)   |

> 📝 **Note:** The multiboot header must be within the **first 8 KiB** of the kernel binary, or GRUB will not boot it.

---

##  Stack Setup Before `kernelMain`

### Diagram: Stack Before Calling `kernelMain(void* mb_struct, uint32_t magic)`

```

+--------------------+
\|   kernel\_stack     | <- esp is set to here
+--------------------+
\|   %eax (magic)     | <- pushed before call
+--------------------+
\|   %ebx (mb\_struct) | <- pushed before call
+--------------------+
\| return address     | <- inserted by call
+--------------------+

````

Matches the expected `kernelMain` function signature.

---

##  Segment Selectors - Internal Format

Segment selectors are 16-bit values used in protected mode.

| Bits  | Meaning                   |
|-------|---------------------------|
| 0–1   | Requested Privilege Level (RPL) |
| 2     | Table Indicator (TI): 0 = GDT, 1 = LDT |
| 3–15  | Index in GDT or LDT       |

### Example: `0x08`

- Index = `1` (2nd entry in GDT)
- TI = `0` (GDT)
- RPL = `0` (Ring 0 — kernel mode)



---

##  GDT Load (`lgdt`) and Table Setup

```cpp
uint32_t i[2];
i[0] = (uint32_t)&nullSegmentSelector;
i[1] = sizeof(GlobalDescriptorTable) << 16;

asm volatile("lgdt (%0)" : : "p" (((uint8_t *) i) + 2));
```

###  Why `+2`?

The CPU expects the structure format for `lgdt` to be:

```cpp
struct {
   uint16_t size;
   void* base_address;
};
```

We're packing that manually:

| Index | Value                | Notes                     |
| ----- | -------------------- | ------------------------- |
| i\[0] | Address of GDT table | Skipped using `+2` offset |
| i\[1] | GDT size (shifted)   | Lower 16 bits hold size   |

This is why we shift the pointer forward 2 bytes using `((uint8_t*)i) + 2`.

---

##  Kernel Memory Map (Physical)

```
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

---

##  Project Files Overview

| File         | Description                                                     |
| ------------ | --------------------------------------------------------------- |
| `loader.s`   | Boot entry point loaded by GRUB, sets up stack and jumps to C++ |
| `kernel.cpp` | Main C++ kernel function (receives multiboot info)              |
| `gdt.h/.cpp` | Sets up Global Descriptor Table and loads it with `lgdt`        |
| `types.h`    | Type aliases for `uint32_t`, etc.                               |
| `linker.ld`  | Linker script placing kernel at `0x100000`                      |
| `Makefile`   | Build script compiling and linking the kernel                   |

---

##  Coming Soon

* Paging setup
* Interrupt Descriptor Table (IDT)
* System call interface




