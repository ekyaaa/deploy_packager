import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/build_config.dart';
import '../providers/app_providers.dart';

class StepBuildConfig extends ConsumerStatefulWidget {
  const StepBuildConfig({super.key});

  @override
  ConsumerState<StepBuildConfig> createState() => _StepBuildConfigState();
}

class _StepBuildConfigState extends ConsumerState<StepBuildConfig> {
  late TextEditingController _frontendDirCtrl;
  late TextEditingController _frontendCmdCtrl;
  late TextEditingController _distFolderCtrl;
  late TextEditingController _backendDirCtrl;
  late TextEditingController _collectstaticCmdCtrl;

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(buildConfigProvider);
    _frontendDirCtrl = TextEditingController(text: cfg.frontendDir);
    _frontendCmdCtrl = TextEditingController(text: cfg.frontendCommand);
    _distFolderCtrl = TextEditingController(text: cfg.distFolder);
    _backendDirCtrl = TextEditingController(text: cfg.backendDir);
    _collectstaticCmdCtrl = TextEditingController(text: cfg.collectstaticCommand);
  }

  @override
  void dispose() {
    _frontendDirCtrl.dispose();
    _frontendCmdCtrl.dispose();
    _distFolderCtrl.dispose();
    _backendDirCtrl.dispose();
    _collectstaticCmdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final config = ref.watch(buildConfigProvider);

    return Column(
      children: [
        _buildHeader(colors, config),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildToggleCard(colors, config),
                  if (config.enabled) ...[
                    const SizedBox(height: 16),
                    _buildFrontendSection(colors, config),
                    const SizedBox(height: 16),
                    _buildDjangoSection(colors, config),
                  ],
                  const SizedBox(height: 16),
                  _buildInfoCard(colors),
                ],
              ),
            ),
          ),
        ),
        _buildBottom(colors, config),
      ],
    );
  }

  Widget _buildHeader(ColorScheme colors, BuildConfig config) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 8),
      child: Row(
        children: [
          Icon(Icons.construction_rounded, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Text(
            'Build Configuration',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          if (config.enabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'active',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleCard(ColorScheme colors, BuildConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: config.enabled
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.power_settings_new_rounded,
                color: config.enabled ? colors.primary : colors.onSurface.withValues(alpha: 0.3),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Run Build Before Export',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    config.enabled
                        ? 'Build will run before files are copied'
                        : 'Only changed files will be exported',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: config.enabled,
              onChanged: (_) {
                ref.read(buildConfigProvider.notifier).toggleEnabled();
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontendSection(ColorScheme colors, BuildConfig config) {
    return _SectionCard(
      icon: Icons.web_rounded,
      title: 'Frontend Build',
      subtitle: 'e.g. cd frontend && pnpm run build',
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(colors, 'Working Directory (relative)'),
          const SizedBox(height: 8),
          TextField(
            controller: _frontendDirCtrl,
            decoration: _inputDecoration(colors).copyWith(
              hintText: '(project root)',
            ),
            style: GoogleFonts.jetBrainsMono(fontSize: 13, color: colors.onSurface),
            onChanged: (v) => ref.read(buildConfigProvider.notifier).setFrontendDir(v),
          ),
          const SizedBox(height: 16),
          _label(colors, 'Build Command'),
          const SizedBox(height: 8),
          TextField(
            controller: _frontendCmdCtrl,
            decoration: _inputDecoration(colors).copyWith(
              hintText: 'npm run build',
            ),
            style: GoogleFonts.jetBrainsMono(fontSize: 13, color: colors.onSurface),
            onChanged: (v) => ref.read(buildConfigProvider.notifier).setFrontendCommand(v),
          ),
          const SizedBox(height: 16),
          _label(colors, 'Dist Folder Name'),
          const SizedBox(height: 8),
          TextField(
            controller: _distFolderCtrl,
            decoration: _inputDecoration(colors).copyWith(
              hintText: 'dist',
            ),
            style: GoogleFonts.jetBrainsMono(fontSize: 13, color: colors.onSurface),
            onChanged: (v) => ref.read(buildConfigProvider.notifier).setDistFolder(v),
          ),
          const SizedBox(height: 8),
          Text(
            '→ static/${config.distFolder}/',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: colors.primary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDjangoSection(ColorScheme colors, BuildConfig config) {
    return _SectionCard(
      icon: Icons.code_rounded,
      title: 'Django Collectstatic',
      subtitle: 'e.g. cd backend && source ../env/bin/activate && python manage.py collectstatic --noinput',
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Run collectstatic',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Switch(
                value: config.runCollectstatic,
                onChanged: (_) {
                  ref.read(buildConfigProvider.notifier).toggleCollectstatic();
                  setState(() {});
                },
              ),
            ],
          ),
          if (config.runCollectstatic) ...[
            const SizedBox(height: 16),
            _label(colors, 'Working Directory (relative)'),
            const SizedBox(height: 8),
            TextField(
              controller: _backendDirCtrl,
              decoration: _inputDecoration(colors).copyWith(
                hintText: '(project root)',
              ),
              style: GoogleFonts.jetBrainsMono(fontSize: 13, color: colors.onSurface),
              onChanged: (v) => ref.read(buildConfigProvider.notifier).setBackendDir(v),
            ),
            const SizedBox(height: 16),
            _label(colors, 'Collectstatic Command'),
            const SizedBox(height: 8),
            TextField(
              controller: _collectstaticCmdCtrl,
              decoration: _inputDecoration(colors).copyWith(
                hintText: 'python3 manage.py collectstatic --noinput',
              ),
              style: GoogleFonts.jetBrainsMono(fontSize: 13, color: colors.onSurface),
              onChanged: (v) => ref.read(buildConfigProvider.notifier).setCollectstaticCommand(v),
            ),
            const SizedBox(height: 8),
            Text(
              '→ static/collected/',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: colors.primary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.primary.withValues(alpha: 0.05),
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: colors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Commands run via bash. Use && to chain steps, e.g. '
              'source ../env/bin/activate && python manage.py collectstatic --noinput',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colors.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom(ColorScheme colors, BuildConfig config) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.onSurface.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => ref.read(currentStepProvider.notifier).state = 2,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back'),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => ref.read(currentStepProvider.notifier).state = 4,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Proceed to Export'),
          ),
        ],
      ),
    );
  }

  Widget _label(ColorScheme colors, String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors.onSurface.withValues(alpha: 0.6),
      ),
    );
  }

  InputDecoration _inputDecoration(ColorScheme colors) {
    return InputDecoration(
      filled: true,
      fillColor: colors.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.onSurface.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme colors;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: colors.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
