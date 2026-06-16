all: analisador
	./analisador programa1.dbe

analisador: exercicio3.y exercicio3.l
	bison -d exercicio3.y
	flex -i exercicio3.l
	gcc exercicio3.tab.c -o analisador -lm

run:
	./analisador programa1.dbe

clean:
	rm -f analisador exercicio3.tab.c exercicio3.tab.h lex.yy.c
