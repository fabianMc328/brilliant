# Brilliant — Cliente Flutter (Solitario y Multijugador 2–6 Jugadores)

Implementación digital en Flutter del juego de lógica y dados **Brilliant** (Ravensburger), con soporte completo para **Modo Solitario** y **Modo Multijugador en tiempo real (2 a 6 jugadores)** conectado al servidor autoritativo independiente `servidorBrilliant`.

## ✨ Características Principales
- **4 Tableros Oficiales (7x7):** Niveles 1 a 4 (*Fácil*, *Intermedio*, *Avanzado*, *Experto*) con todas las reglas de color y rango (`Azul`, `Gris`, `Morado`, `Verde`, `Amarillo`, `Rojo`, `Naranja 1-3` y `Naranja 4-6`).
- **Multijugador de 2 a 6 Jugadores:**
  - Lobby con **código de invitación de 6 caracteres**, selección de **mismo mapa compartido** para toda la sala y botón obligatorio **"Estoy Listo"** para todos los participantes antes de iniciar.
  - Rondas simultáneas con los mismos dados, reloj por ronda, carrera competitiva oficial por región (`1.º`, `2.º`, `3.º+`) y metas de puntos dinámicas (`26`, `24`, `22` y `20` puntos).
  - Opción para **conceder la partida** y manejo resiliente de **desconexiones** con reconexión automática (*exponential backoff*).
- **Diseño Responsivo Móvil:** Verificado sin desbordamientos desde `320x480` hasta `412x915`.

## 🚀 Ejecución

1. Para jugar en **Multijugador**, levanta primero el proyecto hermano `servidorBrilliant`:
   ```powershell
   cd ..\servidorBrilliant
   dart run bin/servidor_brilliant.dart
   ```
2. Inicia la aplicación Flutter:
   ```powershell
   flutter pub get
   flutter run
   ```

## 🧪 Calidad y Pruebas

```powershell
flutter analyze
flutter test
```
