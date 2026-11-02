# Brilliant 🎲

Juego de colocación de dados, cálculo estratégico de puntos y autenticación segura cliente-servidor desarrollado con Flutter y Dart.

---

## 🚀 Inicio Rápido

### Opción 1: Lanzador Completo (Web)
Ejecuta el archivo:
- `iniciar_juego.bat`

Inicia automáticamente el servidor de autenticación en el puerto `8080`, espera a que el servicio esté listo y abre la aplicación en Microsoft Edge.

### Opción 2: Aplicación Nativa de Escritorio (Windows)
Ejecuta el archivo:
- `iniciar_juego_windows.bat`

Inicia el servidor y la versión de escritorio nativa compilada en Windows (`dart_application_1.exe`).

### Opción 3: Ejecución Manual con Flutter
1. **Iniciar el servidor de autenticación:**
   ```powershell
   cd servidor_auth
   dart run bin/server.dart
   ```
2. **Iniciar el cliente Flutter:**
   - **En Edge (Release sin caídas de socket):**
     ```powershell
     flutter run -d edge --release
     ```
   - **En Windows Nativo:**
     ```powershell
     flutter run -d windows
     ```

---

## 🔑 Credenciales de Prueba Preconfiguradas

- **Usuario:** `admin`
- **Contraseña:** `admin123`

*(También puedes crear usuarios nuevos o borrar tu cuenta directamente desde la interfaz del juego).*

---

## 📚 Documentación Técnica Detallada

Para consultar el diseño de arquitectura bajo principios SOLID, seguridad criptográfica (PBKDF2 + JWT), endpoints de la API y el análisis técnico del problema de carga en Edge:
👉 Consulta [`DOCUMENTACION_AUTENTICACION.md`](DOCUMENTACION_AUTENTICACION.md).

---

## 🧪 Pruebas Automatizadas (188 pruebas)

- **Pruebas del Servidor de Autenticación (11 pruebas):**
  ```powershell
  cd servidor_auth
  dart test
  ```
- **Pruebas del Cliente y Juego Flutter (177 pruebas):**
  ```powershell
  flutter test
  ```
