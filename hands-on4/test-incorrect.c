#include <stdio.h>
// Prueba con errores semánticos y advertencias.

#define MAX 100
#define MAX 200

int global;
int global;

func suma(a,b) {
    int resultado;
    resultado = c + a;
    return resultado;
}

func main() {
    int x;
    int y;
    int unused;

    x = w;
    suma(x);
    noExiste(x);

    if (condicion) {
        int z;
        z = x;
    }

    z = x;
    return noDeclarada;
}