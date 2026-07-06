import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/path_utils.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../domain/entities/app_settings.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _folderController;

  @override
  void initState() {
    super.initState();
    _folderController = TextEditingController();
  }

  @override
  void dispose() {
    _folderController.dispose();
    super.dispose();
  }

  Future<void> _addFolder() async {
    final folder = normalizeFolderPath(_folderController.text);
    if (folder.isEmpty) {
      return;
    }

    await ref
        .read(settingsControllerProvider.notifier)
        .addExcludedFolder(folder);
    await ref.read(libraryControllerProvider.notifier).refresh();
    _folderController.clear();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Carpeta excluida: $folder')));
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    final libraryState = ref.watch(libraryControllerProvider).asData?.value;
    final theme = Theme.of(context);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        return Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(settingsControllerProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        );
      },
      data: (settings) {
        final suggestedFolders = (libraryState?.suggestedFolders ?? const [])
            .where((folder) => !settings.excludedFolders.contains(folder))
            .toList(growable: false);

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
          children: [
            Text('Ajustes', style: theme.textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'Personaliza el tema, controla el filtrado de la biblioteca y deja lista la base para escalar reglas futuras.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _SettingsCard(
              title: 'Tema visual',
              subtitle:
                  'Puedes seguir el sistema o forzar un modo claro u oscuro.',
              child: SegmentedButton<AppThemePreference>(
                showSelectedIcon: false,
                selected: {settings.themePreference},
                onSelectionChanged: (selection) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .updateThemePreference(selection.first);
                },
                segments: AppThemePreference.values
                    .map(
                      (preference) => ButtonSegment<AppThemePreference>(
                        value: preference,
                        label: Text(preference.label),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              title: 'Lista negra de carpetas',
              subtitle:
                  'Las canciones ubicadas dentro de estas rutas no se mostrarán en la biblioteca.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _folderController,
                    decoration: const InputDecoration(
                      hintText: '/storage/emulated/0/Podcasts',
                      prefixIcon: Icon(Icons.folder_off_outlined),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addFolder(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _addFolder,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Excluir carpeta'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(settingsControllerProvider.notifier)
                              .clearExcludedFolders();
                          await ref
                              .read(libraryControllerProvider.notifier)
                              .refresh();
                        },
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('Limpiar'),
                      ),
                    ],
                  ),
                  if (settings.excludedFolders.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: settings.excludedFolders
                          .map(
                            (folder) => InputChip(
                              label: Text(folder),
                              onDeleted: () async {
                                await ref
                                    .read(settingsControllerProvider.notifier)
                                    .removeExcludedFolder(folder);
                                await ref
                                    .read(libraryControllerProvider.notifier)
                                    .refresh();
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                  if (suggestedFolders.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Carpetas detectadas',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: suggestedFolders
                          .map(
                            (folder) => ActionChip(
                              label: Text(folder),
                              avatar: const Icon(
                                Icons.folder_outlined,
                                size: 18,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(settingsControllerProvider.notifier)
                                    .addExcludedFolder(folder);
                                await ref
                                    .read(libraryControllerProvider.notifier)
                                    .refresh();
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              title: 'Estado de la biblioteca',
              subtitle:
                  'Puedes volver a escanear la colección cuando cambien archivos o reglas de exclusión.',
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      libraryState == null
                          ? 'La biblioteca todavía no se ha sincronizado.'
                          : '${libraryState.totalTracks} canciones detectadas, ${libraryState.hiddenTracks} ocultas por reglas.',
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        ref.read(libraryControllerProvider.notifier).refresh(),
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Reescanear'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}
