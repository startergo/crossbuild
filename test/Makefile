.PHONY: test clean

test:
	@echo "Testing cross-compiler with CROSS_TRIPLE=$(CROSS_TRIPLE)"
	@echo "#include <stdio.h>" > helloworld.c
	@echo "int main() { printf(\"Hello from $(CROSS_TRIPLE)\\n\"); return 0; }" >> helloworld.c
	cc helloworld.c -o helloworld$(if $(findstring mingw,$(CROSS_TRIPLE)),.exe,)
	file helloworld$(if $(findstring mingw,$(CROSS_TRIPLE)),.exe,)

clean:
