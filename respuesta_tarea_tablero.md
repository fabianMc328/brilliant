# Respuesta a la Tarea del Tablero

### 1. El código del tablero donde se guardan los datos
Los datos y el estado central del juego se guardan en la clase **`Tablero`** (ubicada en `lib/tablero.dart`). Específicamente, los datos se almacenan en memoria mediante un Diccionario (Map):

```dart
final Map<Coordenada, Celda> celdas = {};
```
Este diccionario es el componente principal que guarda los datos, ya que permite buscar rápidamente qué hay en cualquier coordenada. A través de su método `colocarNumero(Coordenada, numero)`, el tablero valida las reglas de la zona y guarda el número únicamente si la jugada es válida.

### 2. La clase que une el tablero con las zonas
Esta clase se llama **`Celda`** (también declarada dentro de `tablero.dart`). 

Es el puente estructural del juego. Une una posición física (`Coordenada`) con la zona a la que pertenece (`Region`) y guarda el `valor` numérico que colocó el usuario. Su estructura es la siguiente:

```dart
class Celda {
  final Coordenada coordenada;
  final Region region;
  int? valor;
  // ...
}
```

### 3. Las Pruebas Automatizadas
Todo el comportamiento de estas clases está respaldado por el archivo de pruebas **`test/tablero_test.dart`**. 
En este archivo se garantiza que el `Tablero`:
* Asigna correctamente cada `Celda` a su respectiva `Region`.
* Valida de manera estricta las reglas de inserción (por ejemplo, comprueba que el comportamiento de los colores como Azul y Amarillo sea correcto).
* Bloquea jugadas ilegales y no permite sobrescribir una casilla que ya tiene un número.
