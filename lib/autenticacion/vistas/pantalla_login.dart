import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_estado.dart';
import '../bloc/auth_evento.dart';

/// Pantalla visual de Login tradicional (Iniciar Sesión / Registro) 100% funcional.
class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controladores de Login
  final _ctrlLoginIdentificador = TextEditingController(text: 'fabian@brilliant.com');
  final _ctrlLoginPassword = TextEditingController(text: 'password123');
  bool _ocultarLoginPassword = true;

  // Controladores de Registro
  final _ctrlRegApodo = TextEditingController();
  final _ctrlRegEmail = TextEditingController();
  final _ctrlRegPassword = TextEditingController();
  final _ctrlRegConfirmPassword = TextEditingController();
  bool _ocultarRegPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ctrlLoginIdentificador.dispose();
    _ctrlLoginPassword.dispose();
    _ctrlRegApodo.dispose();
    _ctrlRegEmail.dispose();
    _ctrlRegPassword.dispose();
    _ctrlRegConfirmPassword.dispose();
    super.dispose();
  }

  void _enviarLogin() {
    context.read<AuthBloc>().add(
          IniciarSesionSolicitado(
            identificador: _ctrlLoginIdentificador.text,
            contrasena: _ctrlLoginPassword.text,
          ),
        );
  }

  void _enviarRegistro() {
    context.read<AuthBloc>().add(
          RegistrarUsuarioSolicitado(
            apodo: _ctrlRegApodo.text,
            email: _ctrlRegEmail.text,
            contrasena: _ctrlRegPassword.text,
            confirmacionContrasena: _ctrlRegConfirmPassword.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthEstado>(
          listener: (context, state) {
            if (state is AuthNoAutenticado && state.mensajeError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.mensajeError!),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is AuthNoAutenticado && state.mensajeExito != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.mensajeExito!),
                  backgroundColor: const Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            final estaCargando = state is AuthCargando;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header con logo y título
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.casino,
                          color: Colors.amber,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Brilliant',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Juego oficial de tablero y lógica de dados',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tarjeta de Auth con Tabs
                      Card(
                        elevation: 3,
                        shadowColor: Colors.black.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(color: Colors.blueGrey.shade100),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Tab Bar
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: TabBar(
                                  controller: _tabController,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  dividerColor: Colors.transparent,
                                  indicator: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.blueGrey.shade600,
                                  labelStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  tabs: const [
                                    Tab(text: 'Iniciar Sesión'),
                                    Tab(text: 'Registrarse'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Formulario dinámico según tab
                              SizedBox(
                                height: 320,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _construirFormularioLogin(estaCargando),
                                    _construirFormularioRegistro(estaCargando),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _construirFormularioLogin(bool cargando) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('input_login_usuario'),
          controller: _ctrlLoginIdentificador,
          enabled: !cargando,
          decoration: InputDecoration(
            labelText: 'Usuario o Correo',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('input_login_password'),
          controller: _ctrlLoginPassword,
          enabled: !cargando,
          obscureText: _ocultarLoginPassword,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _ocultarLoginPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() => _ocultarLoginPassword = !_ocultarLoginPassword);
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          key: const Key('boton_iniciar_sesion'),
          onPressed: cargando ? null : _enviarLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          child: cargando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Entrar a Jugar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 10),
        Text(
          '💡 Cuenta demo: fabian@brilliant.com / password123',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500),
        ),
      ],
    );
  }

  Widget _construirFormularioRegistro(bool cargando) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('input_registro_apodo'),
            controller: _ctrlRegApodo,
            enabled: !cargando,
            decoration: InputDecoration(
              labelText: 'Apodo / Nombre de Jugador',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: Colors.grey.shade50,
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('input_registro_email'),
            controller: _ctrlRegEmail,
            enabled: !cargando,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo Electrónico',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: Colors.grey.shade50,
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('input_registro_password'),
            controller: _ctrlRegPassword,
            enabled: !cargando,
            obscureText: _ocultarRegPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña (mín. 6 caracteres)',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _ocultarRegPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _ocultarRegPassword = !_ocultarRegPassword);
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: Colors.grey.shade50,
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('input_registro_confirm_password'),
            controller: _ctrlRegConfirmPassword,
            enabled: !cargando,
            obscureText: _ocultarRegPassword,
            decoration: InputDecoration(
              labelText: 'Confirmar Contraseña',
              prefixIcon: const Icon(Icons.lock_reset),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: Colors.grey.shade50,
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('boton_crear_cuenta'),
            onPressed: cargando ? null : _enviarRegistro,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: cargando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Registrar y Continuar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
