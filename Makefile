# Compiles with https://www.brutaldeluxe.fr/products/crossdevtools/merlin/
#
ifeq ($(OS),Windows_NT)
    MERLIN_DIR=C:/opt/Merlin32_v1.0
    MERLIN_LIB=$(MERLIN_DIR)/Library
    MERLIN=$(MERLIN_DIR)/Windows/Merlin32
    RM=del /s
else
    MERLIN_DIR=$(HOME)/opt/Merlin32_v1.0
    MERLIN_LIB=$(MERLIN_DIR)/Library
    MERLIN=$(MERLIN_DIR)/Linux64/Merlin32
    RM=rm -f
endif

AC=java -jar AppleCommander-ac-1.4.0.jar
SRC=delhndlr.s
PGM=DELHNDLR
VOL=$(PGM)
DSK=$(PGM).dsk

$(DSK): $(PGM)
	$(AC) -pro140 $(DSK) $(VOL)
	$(AC) -p $(DSK) $(PGM) SYS < $(PGM)

$(PGM): $(SRC)
	$(MERLIN) $(MERLIN_LIB) $(SRC)
	@# Merlin fails to provide a non-0 exit code on failure so
	@# it needs to be simulated by checking for the error_output.txt
	@# file.
	@test -e $(PGM)

clean:
	$(RM) $(DSK) $(PGM) error_output.txt _FileInformation.txt

