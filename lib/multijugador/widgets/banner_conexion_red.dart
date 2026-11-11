import 'package:flutter/material.dart';
import '../dominio/estados_jugador_sala.dart';

/// Banner reactivo que alerta sobre desconexiones, intentos de reconexión o eventos de red.
class BannerConexionRed extends StatelessWidget {
  final EstadoConexionCliente conexion;
  final String? avisoTemporal;
  final VoidCallback onReintentar;
  final VoidCallback? onSalirMenu;

  const BannerConexionRed({
    super.key,
    required this.conexion,
    this.avisoTemporal,
    required this.onReintentar,
    this.onSalirMenu,
  });

  @override
  Widget build(BuildContext context) {
    if (conexion.tipo == TipoEstadoConexionCliente.reconectando) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Container(
          key: const Key('banner_reconectando'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade400, width: 1.4),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.amber.shade800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Conexión inestable. Reconectando (${conexion.intentoActual}/${conexion.maxIntentos})...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
              TextButton(
                key: const Key('boton_reintentar_conexion'),
                onPressed: onReintentar,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Reintentar', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    }

    if (conexion.tipo == TipoEstadoConexionCliente.perdidaDefinitiva) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Container(
          key: const Key('banner_desconexion_definitiva'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade300, width: 1.4),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.red.shade700, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      conexion.detalle ?? 'Se perdió la conexión con el servidor.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    key: const Key('boton_reintentar_definitivo'),
                    onPressed: onReintentar,
                    child: const Text('Reconectar', style: TextStyle(fontSize: 12)),
                  ),
                  if (onSalirMenu != null)
                    TextButton(
                      onPressed: onSalirMenu,
                      child: const Text('Salir', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (avisoTemporal != null && avisoTemporal!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  avisoTemporal!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
