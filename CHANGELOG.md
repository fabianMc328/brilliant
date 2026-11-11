## 2.0.0 - 2026-11-09

- Agregado modo **Multijugador en tiempo real (2 a 6 jugadores)** con `PantallaInicioModo`, `LobbyBloc` y `PartidaMultijugadorBloc`.
- Implementado Lobby con código de invitación de 6 caracteres, mapa compartido entre todos los jugadores y botón obligatorio **"Estoy Listo"**.
- Añadido soporte para **conceder la partida** y tolerancia a desconexiones con reconexión automática en `ClienteWebsocketMultijugador`.
- Desacoplado el servidor autoritativo hacia el nuevo repositorio independiente `servidorBrilliant`.

## 1.0.0 - 2026-10-25

- Implementación completa del Modo Solitario con los 4 niveles oficiales de Brilliant, arquitectura BLoC + SOLID y diseño responsivo móvil.
