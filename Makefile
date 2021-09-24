# Compiles with https://www.brutaldeluxe.fr/products/crossdevtools/merlin/
# a.k.a. https://github.com/apple2accumulator/merlin32
#

AC=java -jar AppleCommander-ac-1.4.0.jar
SRC=delhndlr.s
PGM=DELHNDLR
VOL=$(PGM)
DSK=$(PGM).dsk

$(DSK): $(PGM)
	#$(AC) -pro140 $(DSK) $(VOL)
	cp delhndlr.dsk $(DSK)
	$(AC) -p $(DSK) $(PGM) BIN 0x0801 < $(PGM)

$(PGM): $(SRC)
	merlin32 $(SRC)
	@# Merlin fails to provide a non-0 exit code on failure so
	@# it needs to be simulated by checking for the error_output.txt
	@# file.
	@test -e $(PGM)

clean:
	$(RM) $(PGM) $(DSK) error_output.txt _FileInformation.txt

