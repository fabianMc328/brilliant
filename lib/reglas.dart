// Reglas puras de colocación de números por región para el juego Brilliant.

/// Regla Azul: Todos los números en la región deben ser IGUALES.
bool todosIgualesAlInsertar(List<int> lista, int numeroAInsertar) {
  if (lista.isEmpty) {
    return true;
  }
  return lista.every((elemento) => elemento == numeroAInsertar);
}

/// Regla Amarillo / Rojo: Todos los números en la región deben ser DISTINTOS.
bool todosDiferentesAlInsertar(List<int> lista, int numeroAInsertar) {
  if (lista.contains(numeroAInsertar)) {
    return false;
  }
  final elementosUnicos = lista.toSet();
  return elementosUnicos.length == lista.length;
}

/// Regla Morado: Puede haber como máximo 2 valores distintos en la región.
bool areaMorada(List<int> lista, int numeroAInsertar) {
  final elementosUnicos = {...lista, numeroAInsertar};
  return elementosUnicos.length <= 2;
}

/// Compatibilidad hacia atrás con identificador en mayúscula.
// ignore: non_constant_identifier_names
bool AreaMorada(List<int> lista, int numeroAInsertar) =>
    areaMorada(lista, numeroAInsertar);

/// Regla Verde: Puede ser cualquier número.
bool cualquierNumeroAlInsertar(List<int> lista, int numeroAInsertar) {
  return true;
}

// Checa que el número caiga entre el mínimo y el máximo.
bool numeroEnRangoAlInsertar(List<int> lista, int numeroAInsertar, int min, int max) {
  return numeroAInsertar >= min && numeroAInsertar <= max;
}
