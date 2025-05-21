import 'package:flutter/material.dart';

class AiaScreen extends StatelessWidget {
  const AiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Imagem central (mesma da home)
              Image.asset(
                'assets/images/1813edc8-2cfd-4f21-928d-16663b4fe844.png',
                width: 220,
                height: 220,
              ),
              const SizedBox(height: 40),
              // Botões de microfone e áudio
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircleIcon(icon: Icons.mic_none),
                  const SizedBox(width: 16),
                  _CircleIcon(icon: Icons.volume_up),
                ],
              ),
              const SizedBox(height: 24),
              // Texto "Conectando..."
              const Text(
                'Conectando...',
                style: TextStyle(
                  color: Color(0xFF9D82FF),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              // Indicador de progresso (três bolinhas)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Dot(active: true),
                  const SizedBox(width: 6),
                  _Dot(active: false),
                  const SizedBox(width: 6),
                  _Dot(active: false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  const _CircleIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black38, size: 24),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF9D82FF) : const Color(0xFFD1BFFF),
        shape: BoxShape.circle,
      ),
    );
  }
}
