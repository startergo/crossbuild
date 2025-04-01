.PHONY: test clean

test: info clean helloworld
	@echo "#include <stdio.h>" > helloworld.c
	@echo "int main() { printf(\"Hello world\\n\"); return 0; }" >> helloworld.c
	cc helloworld.c -o helloworld$(if $(findstring mingw,$(CROSS_TRIPLE)),.exe,)
	@ls -la
	@file helloworld$(if $(findstring mingw,$(CROSS_TRIPLE)),.exe,) || echo "File not found"

info:
	@echo "------------------------------------------------------------------------"
	@echo CROSS_TRIPLE: $(CROSS_TRIPLE)

clean:
	rm -f helloworld helloworld.exe helloworld.c
