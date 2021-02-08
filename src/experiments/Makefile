CFLAGS = -ggdb -Wall -Wno-unused-parameter -Wextra -std=c99 -no-pie -pedantic -m64 -O0 -march=native

DEPS = ../helper/libbmp.c ../helper/utils.c
ROMBOS = Rombos_00 Rombos_01 Rombos_02 Rombos_03 Rombos_04 Rombos_05 Rombos_06
BORDES = Bordes_00 
NIVEL = Nivel_00

FILTROS_ENTREGA = Rombos_asm Bordes_asm Nivel_asm
FILTROS_ENTREGA_OBJ = $(addsuffix .o, $(FILTROS_ENTREGA))

FILTROS = $(ROMBOS) $(BORDES) $(NIVEL)
FILTROS_OBJ = $(addsuffix .o, $(FILTROS))

FILTROSC = Rombos_c Bordes_c Nivel_c
FILTROSCO0_OBJ = $(addsuffix _O0.o, $(FILTROSC)) 
FILTROSCO1_OBJ = $(addsuffix _O1.o, $(FILTROSC))
FILTROSCO2_OBJ = $(addsuffix _O2.o, $(FILTROSC))
FILTROSCO3_OBJ = $(addsuffix _O3.o, $(FILTROSC))

all: experiments $(FILTROS_ENTREGA_OBJ) $(FILTROS_OBJ) $(FILTROSCO3_OBJ) $(FILTROSCO2_OBJ) $(FILTROSCO1_OBJ) $(FILTROSCO0_OBJ)

experiments: experiments.c $(FILTROS_ENTREGA_OBJ) $(FILTROS_OBJ) $(FILTROSCO3_OBJ) $(FILTROSCO2_OBJ) $(FILTROSCO1_OBJ) $(FILTROSCO0_OBJ)
	gcc $(CFLAGS) -o experiments experiments.c $(DEPS) $(FILTROS_ENTREGA_OBJ) $(FILTROS_OBJ) $(FILTROSCO3_OBJ) $(FILTROSCO2_OBJ) $(FILTROSCO1_OBJ) $(FILTROSCO0_OBJ)

$(FILTROS_ENTREGA_OBJ): %.o: ../filters/%.asm 
	cp ../filters/$*.asm ./$*.asm
	nasm -f elf64 -g -F dwarf -o $@ $<

$(FILTROS_OBJ): %.o: %.asm 
	nasm -f elf64 -g -F dwarf -o $@ $<

$(FILTROSCO3_OBJ): %_O3.o: ../filters/%.c
	sed -e 's/$*/$*_O3/g' ../filters/$*.c > $*_O3.c
	gcc -c -ggdb -Wall -Wno-unused-parameter -Wextra -std=c99 -no-pie -pedantic -m64 -O3 -o $*_O3.o $*_O3.c

$(FILTROSCO2_OBJ): %_O2.o: ../filters/%.c
	sed -e 's/$*/$*_O2/g' ../filters/$*.c > $*_O2.c
	gcc -c -ggdb -Wall -Wno-unused-parameter -Wextra -std=c99 -no-pie -pedantic -m64 -O2 -o $*_O2.o $*_O2.c

$(FILTROSCO1_OBJ): %_O1.o: ../filters/%.c
	sed -e 's/$*/$*_O1/g' ../filters/$*.c > $*_O1.c
	gcc -c -ggdb -Wall -Wno-unused-parameter -Wextra -std=c99 -no-pie -pedantic -m64 -O1 -o $*_O1.o $*_O1.c

$(FILTROSCO0_OBJ): %_O0.o: ../filters/%.c
	sed -e 's/$*/$*_O0/g' ../filters/$*.c > $*_O0.c
	gcc -c -ggdb -Wall -Wno-unused-parameter -Wextra -std=c99 -no-pie -pedantic -m64 -O0 -o $*_O0.o $*_O0.c

clean:
	rm -f *.o experiments


