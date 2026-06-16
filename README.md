Linguagem DBe (.dbe)

Compilar e executar:
make

Executar outro arquivo:
./analisador arquivo.dbe

Principais recursos:
- Comentarios: // e d/ \b
- Tipos: inteiro, real, texto
- Declaracao simples: inteiro x
- Declaracao multipla: inteiro x, y
- Declaracao com inicializacao: inteiro x = 4, y
- Vetores com tamanho dinamico: inteiro n; ler(n); inteiro vetor[n]
- Leitura: ler(x), ler(vetor[i])
- Escrita: escrever("texto", x, BK)
- Condicional: SE (...) { ... } SENAO { ... }
- Repeticao: when (...) { ... }
- Do-while: do { ... } when (...)

Observacao:
A declaracao multipla foi implementada na gramatica como uma lista de declaradores.
Quando ha inicializacao, a AST cria um bloco: primeiro declara a variavel, depois atribui o valor.
Exemplo: inteiro x = 4, y
vira internamente algo parecido com:
- declarar x
- atribuir 4 a x
- declarar y