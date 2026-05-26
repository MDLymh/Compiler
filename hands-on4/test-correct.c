#include <stdio.h>
// Comentario de una sola línea para validar el escáner.

#define MAX 100

int global;

func suma(a,b) {
    int resultado;
    resultado = a + b;
    return resultado;
}

func main() {
    int x;
    int y;
    int z;

    x = 10;
    y = 20;
    z = x + y;
    global = z;

    if (global) {
        int local;
        local = global;
        global = local;
    }

    suma(x, y);
    return z;
}