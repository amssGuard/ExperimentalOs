GPARAMS = -m32 -ffreestanding -fno-use-cxa-atexit -nostdlib -fno-builtin -fno-rtti -fno-exceptions
ASPARAMS = --32
LDPARAMS = -melf_i386

objects = loader.o kernel.o

%.o: %.cpp
	g++ $(GPARAMS) -o $@ -c $<

%.o: %.s
	as $(ASPARAMS) -o $@ $<

adoKern.bin: linker.ld $(objects)
	ld $(LDPARAMS) -T $< -o $@ $(objects)

install: adoKern.bin
	sudo cp $< /boot/adoKern.bin

adoKern.iso: adoKern.bin
	mkdir iso
	mkdir iso/boot
	mkdir iso/boot/grub
	cp $< iso/boot/
	echo 'set timeout=0' >> iso/boot/grub/grub.cfg
	echo 'set default=0' >> iso/boot/grub/grub.cfg
	echo '' >> iso/boot/grub/grub.cfg
	echo 'menuentry "ExpOs"{' >> iso/boot/grub/grub.cfg
	echo '	multiboot /boot/adoKern.bin' >> iso/boot/grub/grub.cfg
	echo '	boot' >> iso/boot/grub/grub.cfg
	echo '}' >> iso/boot/grub/grub.cfg
	grub-mkrescue --output=$@ iso
	rm -rf iso

run: adoKern.iso
	(killall VirtualBox) || true
	VirtualBox --startvm "ExperimentalOs" &
