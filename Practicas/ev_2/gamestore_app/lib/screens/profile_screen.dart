import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gamestore_app/theme/app_theme.dart';
import 'package:gamestore_app/services/api_service.dart';
import 'package:gamestore_app/models/user.dart';
import 'package:gamestore_app/providers/wishlist_provider.dart';
import 'package:gamestore_app/providers/wearable_provider.dart';
import 'package:gamestore_app/screens/login_screen.dart';
import 'package:gamestore_app/screens/edit_profile_screen.dart';
import 'package:gamestore_app/screens/game_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    await ApiService.fetchUser();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    final wishlist = context.watch<WishlistProvider>();
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ApiService.fetchUser();
            await wishlist.loadWishlist();
            if (mounted) setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildProfileCard(context, user),
                const SizedBox(height: 24),
                _buildStatsSection(context, user),
                const SizedBox(height: 24),
                _buildWearableSection(context),
                const SizedBox(height: 24),
                _buildWishlistSection(context, wishlist),
                const SizedBox(height: 24),
                _buildSettingsSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "PERFIL",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.neonGreen,
            letterSpacing: 3,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.neonGreen),
              onPressed: () async {
                final edited = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
                if (edited == true && mounted) _loadUser();
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.error),
              onPressed: () {
                ApiService.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, UserModel? user) {
    final gamertag = user?.gamertag ?? "OPERADOR";
    final username = user?.username ?? "operador";
    final email = user?.email ?? "correo@gameforce.com";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.card, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonGreen, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonGreen.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.neonGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gamertag.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "@$username",
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      email,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, UserModel? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("ESTADÍSTICAS DE GUERRA"),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard("NIVEL", "${user?.level ?? 7}", AppColors.neonGreen),
            const SizedBox(width: 12),
            _buildStatCard("JUEGOS", "${user?.gamesOwned ?? 12}", AppColors.gold),
            const SizedBox(width: 12),
            _buildStatCard("LOGROS", "${user?.xp ?? 34}", AppColors.blueAccent),
          ],
        ),
        const SizedBox(height: 12),
        _buildXpBar(user),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXpBar(UserModel? user) {
    final xp = user?.xp ?? 450;
    final next = user?.nextLevelXp ?? 1000;
    final progress = next > 0 ? xp / next : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "XP",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              Text(
                "$xp / $next",
                style: const TextStyle(
                  color: AppColors.neonGreen,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation(AppColors.neonGreen),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWearableSection(BuildContext context) {
    final wearable = context.watch<WearableProvider>();
    final connected = wearable.status == WearableConnectionStatus.connected;
    final (statusText, statusColor) = switch (wearable.status) {
      WearableConnectionStatus.searching => ("BUSCANDO...", AppColors.gold),
      WearableConnectionStatus.connected =>
        wearable.paired
            ? ("VINCULADO", AppColors.neonGreen)
            : ("CONECTADO, SIN VINCULAR", AppColors.blueAccent),
      WearableConnectionStatus.error => ("ERROR DE CONEXIÓN", AppColors.error),
      WearableConnectionStatus.disconnected => ("DESCONECTADO", AppColors.error),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("WEARABLE"),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.neonGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.watch_rounded,
                      color: AppColors.neonGreen, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "CONEXIÓN BLE",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.circle, color: statusColor, size: 12),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: connected && wearable.paired
                      ? null
                      : () => _pairWearable(context),
                  icon: const Icon(Icons.bluetooth_connected, size: 18),
                  label: Text(
                    connected && wearable.paired
                        ? "WEARABLE VINCULADO"
                        : "VINCULAR WEARABLE",
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Pulsa el botón y luego toca \"ESTABLECER CONEXIÓN\" en tu wearable para desbloquearlo.",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pairWearable(BuildContext context) async {
    final wearable = context.read<WearableProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (!wearable.isConnected) {
      await wearable.connect();
      for (var i = 0; i < 15 && !wearable.isConnected; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    if (!mounted) return;
    if (wearable.isConnected) {
      await wearable.sendPair(
        games: ApiService.currentUser?.gamesOwned ?? 0,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text("Wearable vinculado y desbloqueado")),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("No se encontró el wearable. Verifica que esté cerca y activo."),
        ),
      );
    }
  }

  Widget _buildWishlistSection(BuildContext context, WishlistProvider wishlist) {
    final games = wishlist.items.values.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("LISTA DE DESEADOS (${wishlist.count})"),
        const SizedBox(height: 12),
        if (games.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.favorite_border, color: AppColors.textSecondary, size: 40),
                SizedBox(height: 8),
                Text("Sin juegos en lista de deseados",
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: games.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final g = games[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GameDetailScreen(game: g)),
                  ),
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            ApiService.imageUrl(g.imageUrl),
                            height: 80, width: 100, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 80, color: AppColors.surface,
                              child: const Icon(Icons.videogame_asset, color: AppColors.neonGreen),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(g.title,
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.textPrimary, fontSize: 10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("CONFIGURACIÓN"),
        const SizedBox(height: 12),
        _buildSettingItem(Icons.notifications_outlined, "NOTIFICACIONES", "ACTIVADAS"),
        _buildDivider(),
        _buildSettingItem(Icons.security, "SEGURIDAD", "PROTOCOLO ACTIVO"),
        _buildDivider(),
        _buildSettingItem(Icons.info_outline, "VERSIÓN", "1.0.0"),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          color: AppColors.neonGreen,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: AppColors.neonGreen),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1);
  }
}
