NAME=SwiftyAlgebra
MOD=$(NAME).swiftmodule $(NAME).swiftdoc
SRC=Workspace/SwiftyAlgebra/SwiftyAlgebra/Sources/**/*.swift

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

$(MOD): $(SRC)
	$(SWIFTC) -emit-library -emit-module $(SRC) -module-name $(NAME)
repl: $(MOD)
	$(SWIFT) -I. -L. -l$(NAME)
clean:
	-rm $(MOD) lib$(NAME).*
