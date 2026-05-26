%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
int yyerror(const char *s);

extern FILE *yyin;
extern int line_num;

#define MAX_SIMB 300
#define TIPO_VAR 0
#define TIPO_FUNC 1
#define TIPO_MACRO 2
#define TIPO_INT 0

typedef struct {
    char *nombre;
    int clase;
    int tipo_dato;
    int aridad;
    int ambito;
    int activo;
    int usado;
} Simbolo;

Simbolo tabla[MAX_SIMB];

int ntabla = 0;
int ambito_actual = 0;
int semantic_errors = 0;
int syntax_errors = 0;

const char *clase_a_texto(int clase) {
    switch (clase) {
        case TIPO_VAR: return "Variable";
        case TIPO_FUNC: return "Funcion";
        case TIPO_MACRO: return "Macro";
        default: return "Desconocida";
    }
}

const char *tipo_a_texto(int tipo) {
    switch (tipo) {
        case TIPO_INT: return "int";
        default: return "desconocido";
    }
}

int es_literal_numerico(const char *texto) {
    if (texto == NULL || *texto == '\0') {
        return 0;
    }

    for (const char *p = texto; *p != '\0'; ++p) {
        if (*p < '0' || *p > '9') {
            return 0;
        }
    }

    return 1;
}

int yyerror(const char *s) {
    syntax_errors++;
    printf("Error sintactico en linea %d: %s\n", line_num, s);
    return 0;
}

void entrar_ambito() {
    ambito_actual++;
}

void salir_ambito() {
    for (int i = 0; i < ntabla; i++) {
        if (tabla[i].ambito == ambito_actual) {
            tabla[i].activo = 0;
        }
    }
    ambito_actual--;
}

int existe_en_ambito_actual(char *id) {
    for (int i = 0; i < ntabla; i++) {
        if (tabla[i].activo &&
            tabla[i].ambito == ambito_actual &&
            strcmp(tabla[i].nombre, id) == 0) {
            return 1;
        }
    }
    return 0;
}

int existe_global(char *id, int clase) {
    for (int i = 0; i < ntabla; i++) {
        if (tabla[i].activo &&
            tabla[i].ambito == 0 &&
            tabla[i].clase == clase &&
            strcmp(tabla[i].nombre, id) == 0) {
            return 1;
        }
    }
    return 0;
}

void agregar_variable(char *id, int tipo_dato) {
    if (existe_en_ambito_actual(id)) {
        printf("Error semantico en linea %d: redeclaracion de variable '%s'\n", line_num, id);
        semantic_errors++;
        return;
    }

    tabla[ntabla++] = (Simbolo){strdup(id), TIPO_VAR, tipo_dato, 0, ambito_actual, 1, 0};
}

void agregar_macro(char *id) {
    if (existe_global(id, TIPO_MACRO)) {
        printf("Error semantico en linea %d: macro '%s' ya definida\n", line_num, id);
        semantic_errors++;
        return;
    }

    tabla[ntabla++] = (Simbolo){strdup(id), TIPO_MACRO, TIPO_INT, 0, 0, 1, 0};
}

void agregar_funcion(char *id, int aridad) {
    if (existe_global(id, TIPO_FUNC)) {
        printf("Error semantico en linea %d: funcion '%s' ya declarada\n", line_num, id);
        semantic_errors++;
        return;
    }

    tabla[ntabla++] = (Simbolo){strdup(id), TIPO_FUNC, TIPO_INT, aridad, 0, 1, 0};
}

int buscar_tipo_variable(char *id) {
    for (int a = ambito_actual; a >= 0; a--) {
        for (int i = ntabla - 1; i >= 0; i--) {
            if (tabla[i].activo &&
                tabla[i].clase == TIPO_VAR &&
                tabla[i].ambito == a &&
                strcmp(tabla[i].nombre, id) == 0) {
                return tabla[i].tipo_dato;
            }
        }
    }
    return -1;
}

int buscar_aridad_funcion(char *id) {
    for (int i = 0; i < ntabla; i++) {
        if (tabla[i].activo &&
            tabla[i].clase == TIPO_FUNC &&
            strcmp(tabla[i].nombre, id) == 0) {
            return tabla[i].aridad;
        }
    }
    return -1;
}

int marcar_uso_variable(char *id) {
    for (int a = ambito_actual; a >= 0; a--) {
        for (int i = ntabla - 1; i >= 0; i--) {
            if (tabla[i].activo &&
                tabla[i].clase == TIPO_VAR &&
                tabla[i].ambito == a &&
                strcmp(tabla[i].nombre, id) == 0) {
                tabla[i].usado = 1;
                return 1;
            }
        }
    }

    return 0;
}

void verificar_destino_asignacion(char *izq) {
    if (buscar_tipo_variable(izq) == -1) {
        printf("Error semantico en linea %d: variable '%s' no declarada\n", line_num, izq);
        semantic_errors++;
    }
}

void verificar_operando(char *id) {
    if (!es_literal_numerico(id) && !marcar_uso_variable(id)) {
        printf("Error semantico en linea %d: variable '%s' no declarada\n", line_num, id);
        semantic_errors++;
    }
}

void verificar_condicion_if(char *id) {
    if (buscar_tipo_variable(id) == -1) {
        printf("Error semantico en linea %d: variable '%s' no declarada en la condicion del if\n", line_num, id);
        semantic_errors++;
    } else {
        marcar_uso_variable(id);
    }
}

void verificar_llamada_funcion(char *id, int argumentos) {
    int esperados = buscar_aridad_funcion(id);

    if (esperados == -1) {
        printf("Error semantico en linea %d: funcion '%s' no declarada\n", line_num, id);
        semantic_errors++;
        return;
    }

    if (esperados != argumentos) {
        printf("Error semantico en linea %d: funcion '%s' espera %d argumento(s), pero recibio %d\n",
               line_num,
               id, esperados, argumentos);
        semantic_errors++;
    }
}

void reportar_variables_no_usadas(void) {
    for (int i = 0; i < ntabla; i++) {
        if (tabla[i].clase == TIPO_VAR && !tabla[i].usado) {
            printf("Advertencia: variable '%s' declarada en el ambito %d pero no utilizada\n",
                   tabla[i].nombre, tabla[i].ambito);
        }
    }
}

void imprimir_tabla_simbolos(void) {
    printf("\n%-18s %-12s %-10s %-8s %-8s %-8s\n",
           "Nombre", "Clase", "Tipo", "Ambito", "Aridad", "Usado");
    printf("%-18s %-12s %-10s %-8s %-8s %-8s\n",
           "------------------", "------------", "----------", "--------", "--------", "--------");

    for (int i = 0; i < ntabla; i++) {
        printf("%-18s %-12s %-10s %-8d %-8d %-8s\n",
               tabla[i].nombre,
               clase_a_texto(tabla[i].clase),
               tipo_a_texto(tabla[i].tipo_dato),
               tabla[i].ambito,
               tabla[i].aridad,
               tabla[i].usado ? "si" : "no");
    }
}
%}

%union {
    char *str;
    int num;
}

%token <str> ID
%token <str> STRING_LITERAL
%token <str> NUMBER

%token INCLUDE DEFINE
%token INT FUNC RETURN IF IGUAL
%token PLUS MINUS TIMES DIVIDE
%token PARIZQ PARDER LLAVEIZQ LLAVEDER PUNTOYCOMA COMA
%token MENOR MAYOR PUNTO

%define parse.error verbose

%type <num> parametros
%type <num> lista_param
%type <num> argumentos
%type <num> lista_args
%type <str> operando

%%

programa:
      preprocesador declaraciones
    ;

preprocesador:
      preprocesador directiva
    |
    ;

directiva:
      include
    | define
    ;

include:
      INCLUDE MENOR ID MAYOR
    | INCLUDE MENOR ID PUNTO ID MAYOR
    | INCLUDE STRING_LITERAL
    ;

define:
      DEFINE ID NUMBER
      {
          agregar_macro($2);
      }
    | DEFINE ID ID
      {
          agregar_macro($2);
      }
    | DEFINE ID STRING_LITERAL
      {
          agregar_macro($2);
      }
    | DEFINE ID
      {
          agregar_macro($2);
      }
    ;

declaraciones:
      declaracion
    | declaraciones declaracion
    ;

declaracion:
      INT ID PUNTOYCOMA
      {
          agregar_variable($2, TIPO_INT);
      }
    | FUNC ID PARIZQ
      {
          agregar_funcion($2, -1);
          entrar_ambito();
      }
      parametros PARDER bloque_funcion
      {
          int aridad = $5;

          for (int i = 0; i < ntabla; i++) {
              if (tabla[i].activo &&
                  tabla[i].clase == TIPO_FUNC &&
                  strcmp(tabla[i].nombre, $2) == 0) {
                  tabla[i].aridad = aridad;
                  break;
              }
          }

          salir_ambito();
      }
    ;

parametros:
      {
          $$ = 0;
      }
    | lista_param
      {
          $$ = $1;
      }
    ;

lista_param:
      ID
      {
          agregar_variable($1, TIPO_INT);
          $$ = 1;
      }
    | lista_param COMA ID
      {
          agregar_variable($3, TIPO_INT);
          $$ = $1 + 1;
      }
    ;

bloque_funcion:
      LLAVEIZQ instrucciones LLAVEDER
    ;

bloque:
      LLAVEIZQ
      {
          entrar_ambito();
      }
      instrucciones LLAVEDER
      {
          salir_ambito();
      }
    ;

instrucciones:
      instrucciones instruccion
    |
    ;

instruccion:
      INT ID PUNTOYCOMA
      {
          agregar_variable($2, TIPO_INT);
      }
        | ID IGUAL expresion PUNTOYCOMA
            {
                    verificar_destino_asignacion($1);
            }
    | ID PARIZQ argumentos PARDER PUNTOYCOMA
      {
          verificar_llamada_funcion($1, $3);
      }
        | RETURN expresion PUNTOYCOMA
      {
            }
        | IF PARIZQ condicion PARDER bloque
            {
      }
    | bloque
    ;

expresion:
            operando
            {
                    verificar_operando($1);
            }
        | operando PLUS operando
            {
                    verificar_operando($1);
                    verificar_operando($3);
            }
        | operando MINUS operando
            {
                    verificar_operando($1);
                    verificar_operando($3);
            }
        | operando TIMES operando
            {
                    verificar_operando($1);
                    verificar_operando($3);
            }
        | operando DIVIDE operando
            {
                    verificar_operando($1);
                    verificar_operando($3);
            }
        ;

operando:
            ID
            {
                    $$ = $1;
            }
        | NUMBER
            {
                    $$ = $1;
            }
        ;

condicion:
            ID
            {
                    verificar_condicion_if($1);
            }
        | NUMBER
            {
            }
        ;

argumentos:
      {
          $$ = 0;
      }
    | lista_args
      {
          $$ = $1;
      }
    ;

lista_args:
            operando
      {
                    verificar_operando($1);
          $$ = 1;
      }
        | lista_args COMA operando
      {
                    verificar_operando($3);
          $$ = $1 + 1;
      }
    ;

%%

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Uso: %s archivo_fuente\n", argv[0]);
        return EXIT_FAILURE;
    }

    yyin = fopen(argv[1], "r");

    if (!yyin) {
        printf("Error: no se pudo abrir el archivo '%s'\n", argv[1]);
        return EXIT_FAILURE;
    }

    int parse_status = yyparse();

    reportar_variables_no_usadas();
    imprimir_tabla_simbolos();

    if (parse_status == 0 && syntax_errors == 0 && semantic_errors == 0) {
        printf("Analisis completado sin errores.\n");
    } else {
        printf("Analisis completado con %d error(es) sintactico(s) y %d error(es) semantico(s).\n",
               syntax_errors, semantic_errors);
    }

    fclose(yyin);

    return (parse_status == 0 && syntax_errors == 0 && semantic_errors == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}

