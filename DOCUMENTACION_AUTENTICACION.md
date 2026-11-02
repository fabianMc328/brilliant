# Documentación de Autenticación, Arquitectura y Guía de Ejecución

Este documento detalla la implementación del sistema de autenticación seguro cliente-servidor para el juego **Brilliant**, la arquitectura de software aplicada bajo principios SOLID, las pruebas automatizadas y el análisis de resolución del problema de ejecución en Edge.

---

## 1. Arquitectura General del Sistema

El sistema implementa una arquitectura desacoplada Cliente-Servidor:
- **Servidor (`servidor_auth/`):** Microservicio REST independiente desarrollado con Dart y Shelf. Maneja el registro, validación de credenciales, emisión/verificación de tokens JWT y persistencia.
- **Cliente (`lib/auth/`):** Módulo de autenticación dentro de la aplicación Flutter Brilliant, gestionado reactivamente mediante BLoC (`flutter_bloc`) y desacoplado mediante repositorios.

```
+---------------------------------------------------------------+
|                      Cliente Flutter                          |
|                                                               |
|  [Vistas: Login, Registro, Diálogo Borrar, Menú de Cuenta]   |
|                               |                               |
|                           [AuthBloc]                          |
|                               |                               |
|                     [AuthRepositorio (DIP)]                   |
|                               |                               |
|                     [HttpAuthRepositorio]                     |
+-------------------------------|-------------------------------+
                                |  HTTP REST (JSON + JWT Bearer)
+-------------------------------v-------------------------------+
|                  Servidor Auth (Shelf API)                    |
|                                                               |
|  [Rutas: /api/auth/registro, /login, /perfil, /cuenta]        |
|                               |                               |
|                         [AuthServicio]                        |
|                  /            |            \                  |
|                 v             v             v                 |
|       [UsuarioRepositorio] [HasherContraseña] [JwtServicio]   |
|          (JSON/Memoria)        (PBKDF2)         (HS256)       |
+---------------------------------------------------------------+
```

---

## 2. Principios SOLID y Buenas Prácticas Aplicadas

1. **Single Responsibility Principle (SRP):**
   - `HasherContrasena`: Únicamente responsable de la derivación criptográfica de contraseñas.
   - `JwtServicio`: Únicamente responsable de generar y verificar tokens HS256.
   - `AuthServicio`: Orquesta la lógica de negocio (no maneja HTTP ni IO directa).
   - `AuthControlador`: Convierte peticiones y respuestas HTTP.
   - `AuthBloc`: Controla exclusivamente los estados del ciclo de autenticación en la interfaz gráfica.

2. **Open/Closed Principle (OCP):**
   - El almacenamiento de usuarios está definido por la interfaz abstracta `UsuarioRepositorio`. Para cambiar de almacenamiento JSON a PostgreSQL o SQLite, sólo se crea una nueva implementación sin modificar `AuthServicio`.

3. **Liskov Substitution Principle (LSP):**
   - `UsuarioRepositorioMemoria` y `UsuarioRepositorioJson` son intercambiables en tiempo de ejecución o pruebas sin alterar el comportamiento del servicio.

4. **Interface Segregation Principle (ISP):**
   - `AuthRepositorio` en el cliente y `UsuarioRepositorio` en el servidor exponen métodos específicos y concisos.

5. **Dependency Inversion Principle (DIP):**
   - `AplicacionBrilliant` y `AuthBloc` dependen de la abstracción `AuthRepositorio`, permitiendo inyectar repositorios simulados (*mocks*) en las pruebas unitarias sin levantar conexiones de red reales.

---

## 3. Seguridad Criptográfica Implementada

- **Derivación de Contraseñas:** Algoritmo PBKDF2 con HMAC-SHA256, 10,000 iteraciones y una sal criptográfica pseudoaleatoria de 16 bytes generada con `Random.secure()`.
- **Mitigación de Timing Attacks:** Comparación en tiempo constante byte a byte en `verificarContrasena()` para evitar filtraciones por tiempo de respuesta.
- **Tokens de Sesión (JWT):** Estándar RFC 7519 codificado en Base64Url con firma HMAC-SHA256, conteniendo `sub` (ID de usuario), `email` y `exp` (expiración).
- **Acceso Protegido y Autorización:** Las rutas `/api/auth/perfil` y `/api/auth/cuenta` validan el encabezado `Authorization: Bearer <token>`.
- **Eliminación Segura de Cuenta:** El endpoint `DELETE /api/auth/cuenta` exige autenticación por token y confirmación explícita de la contraseña actual del usuario.
- **Credenciales Preconfiguradas en Español:**
  - **Usuario:** `admin`
  - **Contraseña:** `admin123`

---

## 4. Endpoints de la API REST

| Método | Endpoint | Cabeceras Requeridas | Descripción |
|---|---|---|---|
| `POST` | `/api/auth/registro` | `Content-Type: application/json` | Registra un nuevo usuario con email/usuario y contraseña |
| `POST` | `/api/auth/login` | `Content-Type: application/json` | Autentica y entrega el token JWT |
| `GET` | `/api/auth/perfil` | `Authorization: Bearer <jwt>` | Consulta la sesión activa |
| `DELETE` | `/api/auth/cuenta` | `Authorization: Bearer <jwt>` | Elimina la cuenta (requiere contraseña en body) |
| `GET` | `/health` | Ninguna | Chequeo de estado del servidor |

---

## 5. Análisis y Resolución del Problema: "Se queda cargando"

### Causa Raíz Identificada
Al ejecutar `flutter run -d edge`, Flutter arranca por defecto en **modo depuración** (*debug mode*). En este modo se inicia el servicio **DWDS** (*Dart Web Debug Service*) para conectar la consola de depuración con Microsoft Edge vía WebSocket. 

En entornos Windows con ciertas versiones del SDK de Dart, el protocolo de socket de depuración produce un crasheo interno en la máquina virtual:
```text
../../runtime/platform/allocation.cc: 22: error: Out of memory.
```
Cuando la máquina virtual de Dart crashea, Microsoft Edge queda abierto esperando datos que nunca llegarán, produciendo una pantalla en blanco o spinner infinito.

### Soluciones

#### 1. Correr en Edge en Modo Release (Sin el servicio DWDS que crashea)
```powershell
flutter run -d edge --release
```
Al correr con `--release`, Flutter no utiliza el canal de depuración inestable; compila el código y lo sirve directamente en Edge sin congelamientos.

#### 2. Correr como Aplicación Nativa de Windows (Recomendado)
El proyecto cuenta con compilación nativa directa para Windows:
```powershell
flutter run -d windows
```
O ejecutando el lanzador creado:
- `iniciar_juego_windows.bat`

#### 3. Lanzadores Automatizados Disponibles en el Repositorio
- [`servidor_auth/iniciar_servidor.bat`](file:///C:/Users/usuario/Desktop/brilliant/servidor_auth/iniciar_servidor.bat): Inicia el servidor de autenticación en el puerto 8080.
- [`iniciar_juego.bat`](file:///C:/Users/usuario/Desktop/brilliant/iniciar_juego.bat): Inicia el servidor, espera a que esté escuchando y abre el cliente en el navegador.
- [`iniciar_juego_windows.bat`](file:///C:/Users/usuario/Desktop/brilliant/iniciar_juego_windows.bat): Inicia el servidor y la versión de escritorio nativa de Windows.

---

## 6. Cobertura de Pruebas Automatizadas

El proyecto cuenta con **188 pruebas automatizadas** que pasan al 100%:
- **Servidor Auth (`servidor_auth/test/servidor_auth_test.dart`):** 11 pruebas de PBKDF2, JWT y ciclo completo de endpoints HTTP.
- **Cliente Flutter (`test/auth/`):** 19 pruebas de integración y widgets (validación de campos, transiciones de BLoC, vistas de login, registro, confirmación de borrado de cuenta y guarda reactiva).
- **Juego Brilliant (`test/`):** 158 pruebas del motor de juego, dados, tableros, puntuación y diseño responsivo.
