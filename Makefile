MOD=SwiftyAlgebra
SRC=Sources/**/*.swift
BIN=$(MOD).swiftmodule $(MOD).swiftdoc

SWIFTC=swiftc
SWIFT=swift
ifdef SWIFTPATH
	SWIFTC=$(SWIFTPATH)/swiftc
	SWIFT=$(SWIFTPATH)/swift
endif
OS := $(shell uname)
ifeq ($(OS),Darwin)
	SWIFTC=xcrun -sdk macosx swiftc
endif

module: $(BIN)
clean:
	-rm $(BIN) lib$(MOD).*
$(BIN): $(SRC)
	$(SWIFTC) -emit-library -emit-module $(SRC) -module-name $(MOD)
repl: $(BIN)
	$(SWIFT) -I. -L. -l$(MOD)
