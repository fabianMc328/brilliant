import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_evento.dart';

class DialogoEliminarCuenta extends StatefulWidget {
  const DialogoEliminarCuenta({super.key});

  static Future<void> mostrar(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: const DialogoEliminarCuenta(),
      ),
    );
  }

  @override
  State<DialogoEliminarCuenta> createState() => _DialogoEliminarCuentaState();
}

class _DialogoEliminarCuentaState extends State<DialogoEliminarCuenta> {
  final _passwordController = TextEditingController();
  bool _ocultarPassword = true;
  String? _errorTexto;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _confirmarEliminacion() {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _errorTexto = 'Ingresa tu contraseña para confirmar.';
      });
      return;
    }

    Navigator.of(context).pop();
    context.read<AuthBloc>().add(
      EliminarCuentaSolicitada(passwordConfirmacion: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Eliminar Cuenta',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 19,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta acción es irreversible. Se eliminará tu cuenta y todo tu historial de juego permanentemente.',
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF475569),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Confirma tu contraseña para continuar:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('input_password_eliminar'),
              controller: _passwordController,
              obscureText: _ocultarPassword,
              decoration: InputDecoration(
                hintText: 'Tu contraseña actual',
                errorText: _errorTexto,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _ocultarPassword ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _ocultarPassword = !_ocultarPassword;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('btn_cancelar_eliminar'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          key: const Key('btn_confirmar_eliminar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: _confirmarEliminacion,
          child: const Text(
            'Eliminar Definitivamente',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
