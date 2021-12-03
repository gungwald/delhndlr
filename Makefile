# Compiles with https://www.brutaldeluxe.fr/products/crossdevtools/merlin/
# a.k.a. https://github.com/apple2accumulator/merlin32
#

AC=java -jar AppleCommander-1.3.5-ac.jar
PGM=del2bs
SRC=$(PGM).s
VOL=$(PGM)
DSK=$(PGM).dsk

$(DSK): $(PGM) $(PGM2)
	#$(AC) -pro140 $(DSK) $(VOL) ---- Broken in 1.3.5 and others
	cp prodos.dsk $(DSK)
	$(AC) -p $(DSK) $(PGM) BIN 0x0803 < $(PGM)

$(PGM): $(SRC)
	merlin32 $(SRC)
	@# Merlin fails to provide a non-0 exit code on failure so
	@# it needs to be simulated by checking for the error_output.txt
	@# file.
	@test -e $(PGM)

clean:
	$(RM) $(PGM) $(DSK) error_output.txt _FileInformation.txt

