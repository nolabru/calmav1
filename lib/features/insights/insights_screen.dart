import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String formattedDate = '';
  bool isLocaleInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('pt_BR', null);
    final dateFormat = DateFormat('d \'de\' MMMM', 'pt_BR');
    setState(() {
      formattedDate = dateFormat.format(DateTime.now()).toLowerCase();
      isLocaleInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      body: SafeArea(
        child: Stack(
          children: [
            // Fundo pontilhado
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Botão de voltar com texto
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => context.pop(),
                        child: Row(
                          children: const [
                            Icon(Icons.arrow_back, color: Colors.black54),
                            SizedBox(width: 4),
                            Text(
                              'Voltar',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // CONTAINER BRANCO COM BORDER RADIUS
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Container com ícone de adicionar, data e foguinho
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {},
                                child: const Icon(
                                  Icons.person_add_alt_1,
                                  color: Color(0xFF9D82FF),
                                  size: 22,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                isLocaleInitialized ? formattedDate : '...',
                                style: const TextStyle(
                                  color: Color(0xFF22223B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.local_fire_department,
                                color: Colors.orange,
                                size: 22,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                "3",
                                style: TextStyle(
                                  color: Color(0xFF22223B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Barra horizontal
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: Divider(
                            height: 28,
                            thickness: 1.2,
                            color: Color(0xFFE7DFFF),
                          ),
                        ),
                        // Conteúdo normal
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Insights para sua jornada',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF22223B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Reflexões baseadas em suas conversas com a AIA\npara apoiar sua saúde mental',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildInsightCard(
                                    icon: Icons.favorite,
                                    iconColor: Colors.pink,
                                    title: 'Reconheça suas emoções',
                                    description:
                                        'Dar nome ao que você sente é o primeiro passo para o controle emocional. Tente identificar suas emoções sem julgá-las.',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInsightCard(
                                    icon: Icons.info_outline,
                                    iconColor: Colors.blue,
                                    title: 'Pratique atenção plena',
                                    description:
                                        'Apenas 5 minutos diários de respiração consciente podem reduzir significativamente os níveis de estresse e ansiedade.',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInsightCard(
                                    icon: Icons.star,
                                    iconColor: Colors.amber,
                                    title: 'Celebre pequenas vitórias',
                                    description:
                                        'Reconhecer e celebrar suas pequenas conquistas diárias ajuda a construir confiança e motivação contínua.',
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Barra de navegação inferior
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildNavButton(
                                icon: Icons.lightbulb_outline,
                                text: 'Insights',
                                isActive: true,
                                onTap: () {},
                              ),
                              _buildNavButton(
                                imagePath:
                                    'assets/images/1813edc8-2cfd-4f21-928d-16663b4fe844.png',
                                text: 'AIA',
                                isActive: false,
                                onTap: () {
                                  context.goNamed('home');
                                },
                              ),
                              _buildNavButton(
                                icon: Icons.person_outline,
                                text: 'Você',
                                isActive: false,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF22223B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    IconData? icon,
    String? imagePath,
    required String text,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          imagePath != null
              ? Image.asset(imagePath, width: 24)
              : Icon(
                icon,
                color: isActive ? const Color(0xFF9D82FF) : Colors.grey,
                size: 24,
              ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? const Color(0xFF9D82FF) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
