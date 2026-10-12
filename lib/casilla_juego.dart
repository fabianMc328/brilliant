import 'package:flutter/material.dart';

/// Tres intensidades de color según el estado de la casilla.
enum EstadoCasilla {
  sinUsar, // Tono ligero
  usado, // Tono medio
  puntuado, // Tono fuerte
}

/// Widget inmutable que mantiene proporción cuadrada (1:1).
class CasillaJuego extends StatelessWidget {
  const CasillaJuego({
    super.key,
    required this.colorBase,
    this.estado = EstadoCasilla.sinUsar,
    this.valor,
    this.anchoBorde = 3.0,
    this.colorBorde,
    this.esAnclaSeleccionada = false,
    this.esAnclaElegible = false,
    this.esLugarValido = false,
    this.valorPreview,
  }) : assert(
          valor == null || (valor >= 0 && valor <= 9),
          'El valor debe ser de un solo dígito (0 al 9) o null.',
        ),
        assert(anchoBorde >= 0.0, 'El ancho del borde no puede ser negativo.');

  final Color colorBase;
  final EstadoCasilla estado;
  final int? valor;
  final double anchoBorde;
  final Color? colorBorde;
  final bool esAnclaSeleccionada;
  final bool esAnclaElegible;
  final bool esLugarValido;
  final int? valorPreview;

  Color _obtenerColorFondo() {
    if (esLugarValido) {
      // Tono ligeramente más brillante y saturado para destacar
      final hsl = HSLColor.fromColor(colorBase);
      return hsl.withLightness(0.85).toColor();
    }

    final hsl = HSLColor.fromColor(colorBase);
    switch (estado) {
      case EstadoCasilla.sinUsar:
        return hsl
            .withLightness((hsl.lightness + 0.32).clamp(0.0, 0.94))
            .toColor();
      case EstadoCasilla.usado:
        return hsl
            .withLightness((hsl.lightness + 0.06).clamp(0.0, 0.78))
            .toColor();
      case EstadoCasilla.puntuado:
        return hsl
            .withLightness((hsl.lightness - 0.18).clamp(0.12, 0.50))
            .toColor();
    }
  }

  Color _obtenerColorTexto(Color colorFondo) {
    return colorFondo.computeLuminance() > 0.45 ? Colors.black87 : Colors.white;
  }

  Color _obtenerColorBorde() {
    if (esAnclaSeleccionada) {
      return Colors.amber.shade600;
    }
    if (esLugarValido) {
      return const Color(0xFF059669);
    }
    if (colorBorde != null) {
      return colorBorde!;
    }
    final hsl = HSLColor.fromColor(colorBase);
    return hsl
        .withLightness((hsl.lightness - 0.25).clamp(0.08, 0.55))
        .toColor();
  }

  double _obtenerAnchoBorde() {
    if (esAnclaSeleccionada || esLugarValido) {
      return 3.5;
    }
    return anchoBorde;
  }

  List<BoxShadow> _obtenerSombras() {
    if (esAnclaSeleccionada) {
      return [
        BoxShadow(
          color: Colors.amber.withValues(alpha: 0.85),
          blurRadius: 10.0,
          spreadRadius: 2.0,
        ),
      ];
    }
    if (esLugarValido) {
      return [
        BoxShadow(
          color: const Color(0xFF10B981).withValues(alpha: 0.75),
          blurRadius: 10.0,
          spreadRadius: 2.0,
        ),
      ];
    }
    return const [
      BoxShadow(
        color: Color(0x1A000000),
        blurRadius: 4.0,
        offset: Offset(0, 2),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final fondo = _obtenerColorFondo();
    final bordeEfectivo = _obtenerColorBorde();
    final bordeAncho = _obtenerAnchoBorde();
    final colorTexto = _obtenerColorTexto(fondo);

    return AspectRatio(
      aspectRatio: 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: bordeEfectivo, width: bordeAncho),
          boxShadow: _obtenerSombras(),
        ),
        alignment: Alignment.center,
        child: valor != null
            ? FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.all(bordeAncho + 2.0),
                  child: Text(
                    '$valor',
                    style: TextStyle(
                      color: colorTexto,
                      fontWeight: FontWeight.w800,
                      fontSize: 32.0,
                    ),
                  ),
                ),
              )
            : (esLugarValido && valorPreview != null
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: EdgeInsets.all(bordeAncho + 2.0),
                      child: Text(
                        '$valorPreview',
                        style: TextStyle(
                          color: const Color(0xFF047857).withValues(alpha: 0.8),
                          fontWeight: FontWeight.w900,
                          fontSize: 28.0,
                        ),
                      ),
                    ),
                  )
                : (esAnclaElegible
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null)),
      ),
    );
  }
}
