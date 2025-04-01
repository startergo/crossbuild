.PHONY: test clean

test:
	@echo "Testing cross-compiler with CROSS_TRIPLE=$(CROSS_TRIPLE)"
	@printf "#include <stdio.h>\nint main() { printf(\"Hello from $(CROSS_TRIPLE)\\\\n\"); return 0; }\n" > helloworld.c
	cc helloworld.c -o helloworld$(if $(findstring mingw,$(CROSS_TRIPLE)),.exe,)
	file helloworld$(if $(findstring mingw,$(CROSS_TRIPLE)),.exe,)

clean:
	rm -f helloworld helloworld.exe helloworld.c
