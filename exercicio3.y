%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

typedef struct ast Ast;

typedef enum {
    DADO_INTEIRO,
    DADO_REAL,
    DADO_TEXTO
} TipoDado;

extern FILE *yyin;
int yylex(void);
void yyerror(const char *s);

// AST - Arvore de Sintaxe Abstrata

typedef enum {
    NODE_NUM,
    NODE_STRING,
    NODE_BK,

    NODE_VAR_VALUE,
    NODE_ARRAY_VALUE,

    NODE_SOMA,
    NODE_SUB,
    NODE_MULT,
    NODE_DIV,
    NODE_POT,
    NODE_NEG,

    NODE_MAIOR,
    NODE_MENOR,
    NODE_MAIOR_IGUAL,
    NODE_MENOR_IGUAL,
    NODE_IGUAL,
    NODE_DIFERENTE,
    NODE_AND,
    NODE_OR,
    NODE_NOT,

    NODE_DECL,
    NODE_DECL_ARRAY,
    NODE_ASSIGN,
    NODE_ASSIGN_ARRAY,
    NODE_READ,
    NODE_READ_ARRAY,
    NODE_PRINT,
    NODE_PRINT_LIST,
    NODE_BLOCK,
    NODE_IF,
    NODE_WHEN,
    NODE_DO_WHEN
} NodeType;

struct ast {
    NodeType tipo;
    TipoDado dado_tipo;
    struct ast *esq;
    struct ast *dir;
    struct ast *terceiro; // Guarda o SENAO do IF.
    double valor;
    char nome[100];
    char texto[512];
};

typedef struct valor {
    TipoDado tipo;
    double num;
    char *str;
} Valor;

typedef struct simbolo {
    char nome[100];
    TipoDado tipo;
    int eh_vetor;
    int tamanho;
    int inicializado;
    double num_valor;
    char *str_valor;
    double *num_vetor;
    char **str_vetor;
    struct simbolo *prox;
} Simbolo;

Simbolo *tabela = NULL;

Ast *novo_no(NodeType tipo, Ast *esq, Ast *dir);
Ast *novo_num(double valor);
Ast *novo_string(char *texto_com_aspas);
Ast *novo_bk(void);
Ast *novo_var_value(char *nome);
Ast *novo_array_value(char *nome, Ast *indice);
Ast *novo_decl(TipoDado tipo, char *nome);
Ast *novo_decl_array(TipoDado tipo, char *nome, Ast *tamanho);
void aplicar_tipo_declaracao(Ast *a, TipoDado tipo);
Ast *novo_assign(char *nome, Ast *valor);
Ast *novo_assign_array(char *nome, Ast *indice, Ast *valor);
Ast *novo_read(char *nome);
Ast *novo_read_array(char *nome, Ast *indice);
Ast *novo_print(Ast *lista);
Ast *novo_print_list(Ast *lista, Ast *item);
Ast *novo_if(Ast *cond, Ast *bloco_true, Ast *bloco_false);
Ast *novo_when(Ast *cond, Ast *bloco);
Ast *novo_do_when(Ast *bloco, Ast *cond);
Ast *novo_cmp(int op, Ast *esq, Ast *dir);

Valor eval(Ast *a);
void executar(Ast *a);
void liberar_ast(Ast *a);
int verdade(Valor v);
int print_itens(Ast *a);

char *duplicar_string(const char *s);
void remover_aspas(char *destino, const char *origem, int max);
const char *nome_tipo(TipoDado tipo);

Simbolo *buscar_simbolo(const char *nome);
Simbolo *criar_simbolo(const char *nome, TipoDado tipo, int eh_vetor);
void declarar_variavel(TipoDado tipo, const char *nome);
void declarar_vetor(TipoDado tipo, const char *nome, Ast *tamanho_ast);
void atribuir_variavel(const char *nome, Valor v);
void atribuir_vetor(const char *nome, Ast *indice_ast, Valor v);
Valor valor_variavel(const char *nome);
Valor valor_vetor(const char *nome, Ast *indice_ast);
void ler_variavel(const char *nome);
void ler_vetor(const char *nome, Ast *indice_ast);
int indice_valido(Simbolo *s, Ast *indice_ast);
Valor valor_num(double n);
Valor valor_str(char *s);

%}

%union {
    double real;
    int op_log;
    char str[512];
    Ast *a;
    TipoDado tipo;
}

%token <real> NUM
%token <op_log> CMP
%token <str> VAR_NAME
%token <str> TXT

%token INICIO FIM
%token TIPO_INTEIRO TIPO_REAL TIPO_TEXTO
%token OUT IN
%token IF ELSE
%token WHEN DO
%token AND OR NOT
%token BK

%type <tipo> tipo
%type <a> programa lista_comandos comando declaracao lista_declaradores declarador atribuicao leitura escrita lista_print item_print destino_leitura condicional repeticao expr valor_atribuicao

%left OR
%left AND
%nonassoc CMP
%left '+' '-'
%left '*' '/'
%right NEG NOT
%right '^'

%%

programa:
      INICIO lista_comandos FIM {
          executar($2);
          liberar_ast($2);
      }
    | lista_comandos {
          executar($1);
          liberar_ast($1);
      }
    ;

lista_comandos:
      lista_comandos comando {
          $$ = novo_no(NODE_BLOCK, $1, $2);
      }
    | comando {
          $$ = $1;
      }
    ;

comando:
      declaracao fimcmd { $$ = $1; }
    | atribuicao fimcmd { $$ = $1; }
    | leitura fimcmd { $$ = $1; }
    | escrita fimcmd { $$ = $1; }
    | condicional { $$ = $1; }
    | repeticao { $$ = $1; }
    ;

fimcmd:
      ';'
    | /* vazio */
    ;

tipo:
      TIPO_INTEIRO { $$ = DADO_INTEIRO; }
    | TIPO_REAL    { $$ = DADO_REAL; }
    | TIPO_TEXTO   { $$ = DADO_TEXTO; }
    ;

declaracao:
      tipo lista_declaradores {
          aplicar_tipo_declaracao($2, $1);
          $$ = $2;
      }
    ;

lista_declaradores:
      lista_declaradores ',' declarador {
          $$ = novo_no(NODE_BLOCK, $1, $3);
      }
    | declarador {
          $$ = $1;
      }
    ;

declarador:
      VAR_NAME {
          $$ = novo_decl(DADO_REAL, $1);
      }
    | VAR_NAME '=' valor_atribuicao {
          $$ = novo_no(NODE_BLOCK, novo_decl(DADO_REAL, $1), novo_assign($1, $3));
      }
    | VAR_NAME '[' expr ']' {
          $$ = novo_decl_array(DADO_REAL, $1, $3);
      }
    ;

atribuicao:
      VAR_NAME '=' valor_atribuicao {
          $$ = novo_assign($1, $3);
      }
    | VAR_NAME '[' expr ']' '=' valor_atribuicao {
          $$ = novo_assign_array($1, $3, $6);
      }
    ;

valor_atribuicao:
      expr { $$ = $1; }
    ;

leitura:
      IN '(' destino_leitura ')' { $$ = $3; }
    ;

destino_leitura:
      VAR_NAME { $$ = novo_read($1); }
    | VAR_NAME '[' expr ']' { $$ = novo_read_array($1, $3); }
    ;

escrita:
      OUT '(' lista_print ')' { $$ = novo_print($3); }
    ;

lista_print:
      lista_print ',' item_print { $$ = novo_print_list($1, $3); }
    | item_print { $$ = $1; }
    ;

item_print:
      expr { $$ = $1; }
    | BK { $$ = novo_bk(); }
    ;

condicional:
      IF '(' expr ')' '{' lista_comandos '}' {
          $$ = novo_if($3, $6, NULL);
      }
    | IF '(' expr ')' '{' lista_comandos '}' ELSE '{' lista_comandos '}' {
          $$ = novo_if($3, $6, $10);
      }
    ;

repeticao:
      WHEN '(' expr ')' '{' lista_comandos '}' {
          $$ = novo_when($3, $6);
      }
    | DO '{' lista_comandos '}' WHEN '(' expr ')' fimcmd {
          $$ = novo_do_when($3, $7);
      }
    ;

expr:
      expr '+' expr { $$ = novo_no(NODE_SOMA, $1, $3); }
    | expr '-' expr { $$ = novo_no(NODE_SUB, $1, $3); }
    | expr '*' expr { $$ = novo_no(NODE_MULT, $1, $3); }
    | expr '/' expr { $$ = novo_no(NODE_DIV, $1, $3); }
    | expr '^' expr { $$ = novo_no(NODE_POT, $1, $3); }
    | '-' expr %prec NEG { $$ = novo_no(NODE_NEG, $2, NULL); }
    | NOT expr { $$ = novo_no(NODE_NOT, $2, NULL); }
    | expr AND expr { $$ = novo_no(NODE_AND, $1, $3); }
    | expr OR expr { $$ = novo_no(NODE_OR, $1, $3); }
    | expr CMP expr { $$ = novo_cmp($2, $1, $3); }
    | '(' expr ')' { $$ = $2; }
    | NUM { $$ = novo_num($1); }
    | TXT { $$ = novo_string($1); }
    | VAR_NAME { $$ = novo_var_value($1); }
    | VAR_NAME '[' expr ']' { $$ = novo_array_value($1, $3); }
    ;

%%

#include "lex.yy.c"

void yyerror(const char *s) {
    printf("Erro sintatico: %s\n", s);
}

Valor valor_num(double n) {
    Valor v;
    v.tipo = DADO_REAL;
    v.num = n;
    v.str = NULL;
    return v;
}

Valor valor_str(char *s) {
    Valor v;
    v.tipo = DADO_TEXTO;
    v.num = 0;
    v.str = s;
    return v;
}

char *duplicar_string(const char *s) {
    char *nova;

    if (s == NULL) {
        s = "";
    }

    nova = malloc(strlen(s) + 1);
    if (nova == NULL) {
        printf("Erro de memoria ao duplicar string.\n");
        exit(1);
    }

    strcpy(nova, s);
    return nova;
}

void remover_aspas(char *destino, const char *origem, int max) {
    int tam, inicio, fim, qtd;

    if (origem == NULL) {
        destino[0] = '\0';
        return;
    }

    tam = strlen(origem);
    inicio = 0;
    fim = tam;

    if (tam >= 2 && origem[0] == '"' && origem[tam - 1] == '"') {
        inicio = 1;
        fim = tam - 1;
    }

    qtd = fim - inicio;
    if (qtd >= max) {
        qtd = max - 1;
    }

    strncpy(destino, origem + inicio, qtd);
    destino[qtd] = '\0';
}

const char *nome_tipo(TipoDado tipo) {
    switch (tipo) {
        case DADO_INTEIRO: return "inteiro";
        case DADO_REAL: return "real";
        case DADO_TEXTO: return "texto";
    }
    return "desconhecido";
}

Ast *novo_no(NodeType tipo, Ast *esq, Ast *dir) {
    Ast *novo = malloc(sizeof(Ast));

    if (novo == NULL) {
        printf("Erro de memoria ao criar no da AST.\n");
        exit(1);
    }

    novo->tipo = tipo;
    novo->dado_tipo = DADO_REAL;
    novo->esq = esq;
    novo->dir = dir;
    novo->terceiro = NULL;
    novo->valor = 0;
    novo->nome[0] = '\0';
    novo->texto[0] = '\0';

    return novo;
}

Ast *novo_num(double valor) {
    Ast *novo = novo_no(NODE_NUM, NULL, NULL);
    novo->valor = valor;
    return novo;
}

Ast *novo_string(char *texto_com_aspas) {
    Ast *novo = novo_no(NODE_STRING, NULL, NULL);
    remover_aspas(novo->texto, texto_com_aspas, 512);
    return novo;
}

Ast *novo_bk(void) {
    return novo_no(NODE_BK, NULL, NULL);
}

Ast *novo_var_value(char *nome) {
    Ast *novo = novo_no(NODE_VAR_VALUE, NULL, NULL);
    strncpy(novo->nome, nome, 99);
    novo->nome[99] = '\0';
    return novo;
}

Ast *novo_array_value(char *nome, Ast *indice) {
    Ast *novo = novo_no(NODE_ARRAY_VALUE, indice, NULL);
    strncpy(novo->nome, nome, 99);
    novo->nome[99] = '\0';
    return novo;
}

Ast *novo_decl(TipoDado tipo, char *nome) {
    Ast *novo = novo_no(NODE_DECL, NULL, NULL);
    novo->dado_tipo = tipo;
    strncpy(novo->nome, nome, 99);
    novo->nome[99] = '\0';
    return novo;
}

Ast *novo_decl_array(TipoDado tipo, char *nome, Ast *tamanho) {
    Ast *novo = novo_no(NODE_DECL_ARRAY, tamanho, NULL);
    novo->dado_tipo = tipo;
    strncpy(novo->nome, nome, 99);
    novo->nome[99] = '\0';
    return novo;
}

void aplicar_tipo_declaracao(Ast *a, TipoDado tipo) {
    if (a == NULL) {
        return;
    }

    if (a->tipo == NODE_DECL || a->tipo == NODE_DECL_ARRAY) {
        a->dado_tipo = tipo;
        return;
    }

    if (a->tipo == NODE_BLOCK) {
        aplicar_tipo_declaracao(a->esq, tipo);
        aplicar_tipo_declaracao(a->dir, tipo);
        aplicar_tipo_declaracao(a->terceiro, tipo);
    }
}

Ast *novo_assign(char *nome, Ast *valor) {
    Ast *novo = novo_no(NODE_ASSIGN, valor, NULL);
    strncpy(novo->nome, nome, 99);
    novo->nome[99] = '\0';
    return novo;
}

Ast *novo_assign_array(char *nome, Ast *indice, Ast *valor) {
    Ast *novo = novo_no(NODE_ASSIGN_ARRAY, indice, valor);
    strncpy(novo->nome, nome, 99);
    novo->nome[99] = '\0';
    return novo;
}

Ast *novo_read(char *nome) {
    Ast *novo = novo_no(NODE_READ, NULL, NULL);
    strncpy(novo->nome, nome, 99);
    novo->nome[99] = '\0';
    return novo;
}

Ast *novo_read_array(char *nome, Ast *indice) {
    Ast *novo = novo_no(NODE_READ_ARRAY, indice, NULL);
    strncpy(novo->nome, nome, 99);
    novo->nome[99] = '\0';
    return novo;
}

Ast *novo_print(Ast *lista) {
    return novo_no(NODE_PRINT, lista, NULL);
}

Ast *novo_print_list(Ast *lista, Ast *item) {
    return novo_no(NODE_PRINT_LIST, lista, item);
}

Ast *novo_if(Ast *cond, Ast *bloco_true, Ast *bloco_false) {
    Ast *novo = novo_no(NODE_IF, cond, bloco_true);
    novo->terceiro = bloco_false;
    return novo;
}

Ast *novo_when(Ast *cond, Ast *bloco) {
    return novo_no(NODE_WHEN, cond, bloco);
}

Ast *novo_do_when(Ast *bloco, Ast *cond) {
    return novo_no(NODE_DO_WHEN, bloco, cond);
}

Ast *novo_cmp(int op, Ast *esq, Ast *dir) {
    NodeType tipo;

    switch (op) {
        case 1: tipo = NODE_MAIOR; break;
        case 2: tipo = NODE_MENOR; break;
        case 3: tipo = NODE_MAIOR_IGUAL; break;
        case 4: tipo = NODE_MENOR_IGUAL; break;
        case 5: tipo = NODE_IGUAL; break;
        case 6: tipo = NODE_DIFERENTE; break;
        default: tipo = NODE_IGUAL; break;
    }

    return novo_no(tipo, esq, dir);
}

Simbolo *buscar_simbolo(const char *nome) {
    Simbolo *atual = tabela;

    while (atual != NULL) {
        if (strcmp(atual->nome, nome) == 0) {
            return atual;
        }
        atual = atual->prox;
    }

    return NULL;
}

Simbolo *criar_simbolo(const char *nome, TipoDado tipo, int eh_vetor) {
    Simbolo *s = malloc(sizeof(Simbolo));

    if (s == NULL) {
        printf("Erro de memoria ao criar simbolo.\n");
        exit(1);
    }

    strncpy(s->nome, nome, 99);
    s->nome[99] = '\0';
    s->tipo = tipo;
    s->eh_vetor = eh_vetor;
    s->tamanho = 0;
    s->inicializado = 0;
    s->num_valor = 0;
    s->str_valor = duplicar_string("");
    s->num_vetor = NULL;
    s->str_vetor = NULL;
    s->prox = tabela;
    tabela = s;

    return s;
}

void declarar_variavel(TipoDado tipo, const char *nome) {
    if (buscar_simbolo(nome) != NULL) {
        printf("Erro semantico: variavel '%s' ja declarada.\n", nome);
        return;
    }

    criar_simbolo(nome, tipo, 0);
}

void declarar_vetor(TipoDado tipo, const char *nome, Ast *tamanho_ast) {
    Valor tam_valor;
    int tamanho;
    Simbolo *s;
    int i;

    if (buscar_simbolo(nome) != NULL) {
        printf("Erro semantico: variavel '%s' ja declarada.\n", nome);
        return;
    }

    tam_valor = eval(tamanho_ast);

    if (tam_valor.tipo == DADO_TEXTO || floor(tam_valor.num) != tam_valor.num || tam_valor.num <= 0) {
        printf("Erro semantico: tamanho do vetor '%s' deve ser inteiro positivo.\n", nome);
        return;
    }

    tamanho = (int) tam_valor.num;
    s = criar_simbolo(nome, tipo, 1);
    s->tamanho = tamanho;
    s->inicializado = 1;

    if (tipo == DADO_TEXTO) {
        s->str_vetor = calloc(tamanho, sizeof(char *));
        if (s->str_vetor == NULL) {
            printf("Erro de memoria ao alocar vetor de texto '%s'.\n", nome);
            exit(1);
        }
        for (i = 0; i < tamanho; i++) {
            s->str_vetor[i] = duplicar_string("");
        }
    } else {
        s->num_vetor = calloc(tamanho, sizeof(double));
        if (s->num_vetor == NULL) {
            printf("Erro de memoria ao alocar vetor numerico '%s'.\n", nome);
            exit(1);
        }
    }

    printf("Vetor '%s' alocado dinamicamente com %d posicoes.\n", nome, tamanho);
}

void atribuir_variavel(const char *nome, Valor v) {
    Simbolo *s = buscar_simbolo(nome);

    if (s == NULL) {
        printf("Erro semantico: variavel '%s' nao declarada.\n", nome);
        return;
    }

    if (s->eh_vetor) {
        printf("Erro semantico: '%s' e vetor. Use indice, exemplo: %s[0].\n", nome, nome);
        return;
    }

    if (s->tipo == DADO_TEXTO) {
        if (v.tipo != DADO_TEXTO) {
            printf("Erro semantico: variavel de texto '%s' precisa receber texto.\n", nome);
            return;
        }
        free(s->str_valor);
        s->str_valor = duplicar_string(v.str);
    } else {
        if (v.tipo == DADO_TEXTO) {
            printf("Erro semantico: variavel numerica '%s' nao pode receber texto.\n", nome);
            return;
        }

        if (s->tipo == DADO_INTEIRO) {
            s->num_valor = (int) v.num;
        } else {
            s->num_valor = v.num;
        }
    }

    s->inicializado = 1;
}

int indice_valido(Simbolo *s, Ast *indice_ast) {
    Valor indice_valor;
    int indice;

    indice_valor = eval(indice_ast);

    if (indice_valor.tipo == DADO_TEXTO || floor(indice_valor.num) != indice_valor.num) {
        printf("Erro semantico: indice do vetor '%s' deve ser inteiro.\n", s->nome);
        return -1;
    }

    indice = (int) indice_valor.num;

    if (indice < 0 || indice >= s->tamanho) {
        printf("Erro semantico: indice %d fora do limite do vetor '%s' de tamanho %d.\n", indice, s->nome, s->tamanho);
        return -1;
    }

    return indice;
}

void atribuir_vetor(const char *nome, Ast *indice_ast, Valor v) {
    Simbolo *s = buscar_simbolo(nome);
    int indice;

    if (s == NULL) {
        printf("Erro semantico: vetor '%s' nao declarado.\n", nome);
        return;
    }

    if (!s->eh_vetor) {
        printf("Erro semantico: '%s' nao e vetor.\n", nome);
        return;
    }

    indice = indice_valido(s, indice_ast);
    if (indice < 0) {
        return;
    }

    if (s->tipo == DADO_TEXTO) {
        if (v.tipo != DADO_TEXTO) {
            printf("Erro semantico: vetor de texto '%s' precisa receber texto.\n", nome);
            return;
        }
        free(s->str_vetor[indice]);
        s->str_vetor[indice] = duplicar_string(v.str);
    } else {
        if (v.tipo == DADO_TEXTO) {
            printf("Erro semantico: vetor numerico '%s' nao pode receber texto.\n", nome);
            return;
        }
        if (s->tipo == DADO_INTEIRO) {
            s->num_vetor[indice] = (int) v.num;
        } else {
            s->num_vetor[indice] = v.num;
        }
    }
}

Valor valor_variavel(const char *nome) {
    Simbolo *s = buscar_simbolo(nome);

    if (s == NULL) {
        printf("Erro semantico: variavel '%s' nao declarada.\n", nome);
        return valor_num(0);
    }

    if (s->eh_vetor) {
        printf("Erro semantico: '%s' e vetor. Use indice, exemplo: %s[0].\n", nome, nome);
        return valor_num(0);
    }

    if (!s->inicializado) {
        printf("Aviso semantico: variavel '%s' usada sem valor inicial.\n", nome);
    }

    if (s->tipo == DADO_TEXTO) {
        return valor_str(s->str_valor);
    }

    return valor_num(s->num_valor);
}

Valor valor_vetor(const char *nome, Ast *indice_ast) {
    Simbolo *s = buscar_simbolo(nome);
    int indice;

    if (s == NULL) {
        printf("Erro semantico: vetor '%s' nao declarado.\n", nome);
        return valor_num(0);
    }

    if (!s->eh_vetor) {
        printf("Erro semantico: '%s' nao e vetor.\n", nome);
        return valor_num(0);
    }

    indice = indice_valido(s, indice_ast);
    if (indice < 0) {
        return valor_num(0);
    }

    if (s->tipo == DADO_TEXTO) {
        return valor_str(s->str_vetor[indice]);
    }

    return valor_num(s->num_vetor[indice]);
}

void ler_variavel(const char *nome) {
    Simbolo *s = buscar_simbolo(nome);
    char buffer[512];
    double valor;

    if (s == NULL) {
        printf("Erro semantico: variavel '%s' nao declarada.\n", nome);
        return;
    }

    if (s->eh_vetor) {
        printf("Erro semantico: '%s' e vetor. Use indice na leitura.\n", nome);
        return;
    }

    printf("Digite valor para %s: ", nome);

    if (s->tipo == DADO_TEXTO) {
        scanf(" %511[^\n]", buffer);
        free(s->str_valor);
        s->str_valor = duplicar_string(buffer);
    } else {
        scanf(" %lf", &valor);
        if (s->tipo == DADO_INTEIRO) {
            s->num_valor = (int) valor;
        } else {
            s->num_valor = valor;
        }
    }

    s->inicializado = 1;
}

void ler_vetor(const char *nome, Ast *indice_ast) {
    Simbolo *s = buscar_simbolo(nome);
    int indice;
    char buffer[512];
    double valor;

    if (s == NULL) {
        printf("Erro semantico: vetor '%s' nao declarado.\n", nome);
        return;
    }

    if (!s->eh_vetor) {
        printf("Erro semantico: '%s' nao e vetor.\n", nome);
        return;
    }

    indice = indice_valido(s, indice_ast);
    if (indice < 0) {
        return;
    }

    printf("Digite valor para %s[%d]: ", nome, indice);

    if (s->tipo == DADO_TEXTO) {
        scanf(" %511[^\n]", buffer);
        free(s->str_vetor[indice]);
        s->str_vetor[indice] = duplicar_string(buffer);
    } else {
        scanf(" %lf", &valor);
        if (s->tipo == DADO_INTEIRO) {
            s->num_vetor[indice] = (int) valor;
        } else {
            s->num_vetor[indice] = valor;
        }
    }
}

int verdade(Valor v) {
    if (v.tipo == DADO_TEXTO) {
        return v.str != NULL && strlen(v.str) > 0;
    }
    return fabs(v.num) > 0.000001;
}

Valor eval(Ast *a) {
    Valor v1, v2;

    if (a == NULL) {
        return valor_num(0);
    }

    switch (a->tipo) {
        case NODE_NUM:
            return valor_num(a->valor);

        case NODE_STRING:
            return valor_str(a->texto);

        case NODE_BK:
            return valor_str("\n");

        case NODE_VAR_VALUE:
            return valor_variavel(a->nome);

        case NODE_ARRAY_VALUE:
            return valor_vetor(a->nome, a->esq);

        case NODE_SOMA:
            v1 = eval(a->esq);
            v2 = eval(a->dir);
            if (v1.tipo == DADO_TEXTO || v2.tipo == DADO_TEXTO) {
                printf("Erro semantico: soma aceita apenas numeros.\n");
                return valor_num(0);
            }
            return valor_num(v1.num + v2.num);

        case NODE_SUB:
            v1 = eval(a->esq);
            v2 = eval(a->dir);
            if (v1.tipo == DADO_TEXTO || v2.tipo == DADO_TEXTO) {
                printf("Erro semantico: subtracao aceita apenas numeros.\n");
                return valor_num(0);
            }
            return valor_num(v1.num - v2.num);

        case NODE_MULT:
            v1 = eval(a->esq);
            v2 = eval(a->dir);
            if (v1.tipo == DADO_TEXTO || v2.tipo == DADO_TEXTO) {
                printf("Erro semantico: multiplicacao aceita apenas numeros.\n");
                return valor_num(0);
            }
            return valor_num(v1.num * v2.num);

        case NODE_DIV:
            v1 = eval(a->esq);
            v2 = eval(a->dir);
            if (v1.tipo == DADO_TEXTO || v2.tipo == DADO_TEXTO) {
                printf("Erro semantico: divisao aceita apenas numeros.\n");
                return valor_num(0);
            }
            if (fabs(v2.num) < 0.000001) {
                printf("Erro semantico: divisao por zero.\n");
                return valor_num(0);
            }
            return valor_num(v1.num / v2.num);

        case NODE_POT:
            v1 = eval(a->esq);
            v2 = eval(a->dir);
            if (v1.tipo == DADO_TEXTO || v2.tipo == DADO_TEXTO) {
                printf("Erro semantico: potencia aceita apenas numeros.\n");
                return valor_num(0);
            }
            return valor_num(pow(v1.num, v2.num));

        case NODE_NEG:
            v1 = eval(a->esq);
            if (v1.tipo == DADO_TEXTO) {
                printf("Erro semantico: negativo aceita apenas numero.\n");
                return valor_num(0);
            }
            return valor_num(-v1.num);

        case NODE_MAIOR:
        case NODE_MENOR:
        case NODE_MAIOR_IGUAL:
        case NODE_MENOR_IGUAL:
        case NODE_IGUAL:
        case NODE_DIFERENTE:
            v1 = eval(a->esq);
            v2 = eval(a->dir);

            if (v1.tipo == DADO_TEXTO || v2.tipo == DADO_TEXTO) {
                if (a->tipo == NODE_IGUAL) {
                    return valor_num(strcmp(v1.str ? v1.str : "", v2.str ? v2.str : "") == 0);
                }
                if (a->tipo == NODE_DIFERENTE) {
                    return valor_num(strcmp(v1.str ? v1.str : "", v2.str ? v2.str : "") != 0);
                }
                printf("Erro semantico: textos so podem ser comparados com == ou !=.\n");
                return valor_num(0);
            }

            switch (a->tipo) {
                case NODE_MAIOR: return valor_num(v1.num > v2.num);
                case NODE_MENOR: return valor_num(v1.num < v2.num);
                case NODE_MAIOR_IGUAL: return valor_num(v1.num >= v2.num);
                case NODE_MENOR_IGUAL: return valor_num(v1.num <= v2.num);
                case NODE_IGUAL: return valor_num(fabs(v1.num - v2.num) < 0.000001);
                case NODE_DIFERENTE: return valor_num(fabs(v1.num - v2.num) >= 0.000001);
                default: return valor_num(0);
            }

        case NODE_AND:
            v1 = eval(a->esq);
            if (!verdade(v1)) {
                return valor_num(0);
            }
            v2 = eval(a->dir);
            return valor_num(verdade(v2));

        case NODE_OR:
            v1 = eval(a->esq);
            if (verdade(v1)) {
                return valor_num(1);
            }
            v2 = eval(a->dir);
            return valor_num(verdade(v2));

        case NODE_NOT:
            v1 = eval(a->esq);
            return valor_num(!verdade(v1));

        default:
            executar(a);
            return valor_num(0);
    }
}

void executar(Ast *a) {
    int contador;

    if (a == NULL) {
        return;
    }

    switch (a->tipo) {
        case NODE_BLOCK:
            executar(a->esq);
            executar(a->dir);
            break;

        case NODE_DECL:
            declarar_variavel(a->dado_tipo, a->nome);
            break;

        case NODE_DECL_ARRAY:
            declarar_vetor(a->dado_tipo, a->nome, a->esq);
            break;

        case NODE_ASSIGN:
            atribuir_variavel(a->nome, eval(a->esq));
            break;

        case NODE_ASSIGN_ARRAY:
            atribuir_vetor(a->nome, a->esq, eval(a->dir));
            break;

        case NODE_READ:
            ler_variavel(a->nome);
            break;

        case NODE_READ_ARRAY:
            ler_vetor(a->nome, a->esq);
            break;

        case NODE_PRINT:
            if (!print_itens(a->esq)) {
                printf("\n");
            }
            break;

        case NODE_IF:
            if (verdade(eval(a->esq))) {
                executar(a->dir);
            } else {
                executar(a->terceiro);
            }
            break;

        case NODE_WHEN:
            contador = 0;
            while (verdade(eval(a->esq))) {
                executar(a->dir);
                contador++;
                if (contador > 100000) {
                    printf("Erro semantico: repeticao when interrompida por limite de seguranca.\n");
                    break;
                }
            }
            break;

        case NODE_DO_WHEN:
            contador = 0;
            do {
                executar(a->esq);
                contador++;
                if (contador > 100000) {
                    printf("Erro semantico: repeticao do-when interrompida por limite de seguranca.\n");
                    break;
                }
            } while (verdade(eval(a->dir)));
            break;

        default:
            eval(a);
            break;
    }
}

int print_itens(Ast *a) {
    Valor v;

    if (a == NULL) {
        return 0;
    }

    if (a->tipo == NODE_PRINT_LIST) {
        print_itens(a->esq);
        return print_itens(a->dir);
    }

    if (a->tipo == NODE_BK) {
        printf("\n");
        return 1;
    }

    v = eval(a);

    if (v.tipo == DADO_TEXTO) {
        printf("%s", v.str ? v.str : "");
    } else {
        if (fabs(v.num - (int)v.num) < 0.000001) {
            printf("%d", (int)v.num);
        } else {
            printf("%f", v.num);
        }
    }

    return 0;
}

void liberar_ast(Ast *a) {
    if (a == NULL) {
        return;
    }

    liberar_ast(a->esq);
    liberar_ast(a->dir);
    liberar_ast(a->terceiro);
    free(a);
}

int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = fopen("programa1.dbe", "r");
    }

    if (yyin == NULL) {
        printf("Erro: nao foi possivel abrir o arquivo de entrada.\n");
        printf("Uso: ./analisador arquivo.dbe\n");
        return 1;
    }

    yyparse();
    fclose(yyin);

    return 0;
}
