# Compiles with https://www.brutaldeluxe.fr/products/crossdevtools/merlin/
# a.k.a. https://github.com/apple2accumulator/merlin32

AC=java -jar AppleCommander-1.3.5-ac.jar
PGM=del2bs40
PGM2=del2bs80
SRC=$(PGM).s
SRC2=$(PGM2).s
VOL=del2bs
DSK=$(VOL).dsk
ADDR=0x0300

$(DSK): $(PGM) $(PGM2)
	@#$(AC) -pro140 $(DSK) $(VOL) ---- Broken in 1.3.5 and others
	cp prodos.dsk $(DSK)
	$(AC) -p $(DSK) $(PGM) BIN $(ADDR) < $(PGM)
	$(AC) -p $(DSK) $(PGM2) BIN $(ADDR) < $(PGM2)

$(PGM): $(SRC)
	merlin32 . $(SRC)
	@# Merlin fails to provide a non-0 exit code on failure so
	@# it needs to be simulated by checking for the error_output.txt
	@# file.
	test -e $(PGM)

$(PGM2): $(SRC2)
	merlin32 . $(SRC2)
	@# Merlin fails to provide a non-0 exit code on failure so
	@# it needs to be simulated by checking for the error_output.txt
	@# file.
	test -e $(PGM2)

clean:
	$(RM) $(PGM) $(PGM2) $(DSK) error_output.txt _FileInformation.txt

