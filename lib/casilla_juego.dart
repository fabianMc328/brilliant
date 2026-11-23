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
    this.tieneEstrella = false,
  })  : assert(
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
  final bool tieneEstrella;

  Color _obtenerColorFondo() {
    if (esLugarValido) {
      // Iluminación vibrante y clara para señalar lugares disponibles sin tapar el color base
      return Color.lerp(colorBase, Colors.white, 0.35) ?? colorBase;
    }

    final hsl = HSLColor.fromColor(colorBase);
    final saturacionFuerte = (hsl.saturation + 0.14).clamp(0.0, 1.0);
    switch (estado) {
      case EstadoCasilla.sinUsar:
        return hsl
            .withSaturation(saturacionFuerte)
            .withLightness((hsl.lightness + 0.04).clamp(0.32, 0.62))
            .toColor();
      case EstadoCasilla.usado:
        return hsl
            .withSaturation((hsl.saturation + 0.16).clamp(0.0, 1.0))
            .withLightness((hsl.lightness - 0.07).clamp(0.24, 0.52))
            .toColor();
      case EstadoCasilla.puntuado:
        return hsl
            .withSaturation((hsl.saturation + 0.18).clamp(0.0, 1.0))
            .withLightness((hsl.lightness - 0.18).clamp(0.16, 0.40))
            .toColor();
    }
  }

  Color _obtenerColorTexto(Color colorFondo) {
    return colorFondo.computeLuminance() > 0.45 ? Colors.black87 : Colors.white;
  }

  Color _obtenerColorBorde() {
    if (esAnclaSeleccionada) {
      return Colors.amber.shade500;
    }
    if (esLugarValido) {
      return const Color(0xFF10B981);
    }
    if (colorBorde != null) {
      return colorBorde!;
    }
    final hsl = HSLColor.fromColor(colorBase);
    return hsl
        .withLightness((hsl.lightness - 0.28).clamp(0.08, 0.45))
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
          color: const Color(0xFF34D399).withValues(alpha: 0.9),
          blurRadius: 12.0,
          spreadRadius: 2.5,
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
            : (esLugarValido
                ? Container(
                    margin: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.92),
                        width: 2.0,
                      ),
                    ),
                  )
                : (tieneEstrella
                    ? const Icon(
                        Icons.star_rounded,
                        size: 24,
                        color: Colors.amber,
                      )
                    : const SizedBox.shrink())),
      ),
    );
  }
}
