/// Retorna true si al insertar [numeroAInsertar] en [lista] todos los elementos son diferentes.
bool todosDiferentesAlInsertar(List<int> lista, int numeroAInsertar) {
  if (lista.contains(numeroAInsertar)) {
    return false;
  }
  final elementosUnicos = lista.toSet();
  return elementosUnicos.length == lista.length;
}
