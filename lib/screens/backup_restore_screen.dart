import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db_flutter/bootstrap.dart';
import '../themes/app_theme.dart';
import '../widgets/app_notification.dart';
import '../widgets/restart_widget.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  List<File> _backups = [];
  bool _isCreatingBackup = false;
  bool _isRestoring = false;
  static const _maxBackups = 20;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  // ── Backup directory ────────────────────────────────────────────────────────

  Future<Directory> _getBackupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'OpticaSana_Backups'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _loadBackups() async {
    final dir = await _getBackupDir();
    final entities = await dir.list().toList();
    final files = entities
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // newest first
    if (mounted) setState(() => _backups = files);
  }

  // ── Create backup ───────────────────────────────────────────────────────────

  Future<void> _createBackup() async {
    setState(() => _isCreatingBackup = true);
    try {
      // Flush WAL so the file is self-contained
      final db = await DatabaseHelper.instance.database;
      await db.execute('PRAGMA wal_checkpoint(FULL)');

      final dbPath = await DatabaseHelper.instance.databasePath;
      final dir = await _getBackupDir();
      final ts = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final backupPath = p.join(dir.path, 'OpticaSana_$ts.db');

      await File(dbPath).copy(backupPath);
      await _trimOldBackups(dir);
      await _loadBackups();

      if (mounted) {
        AppNotification.show(
          context,
          'backup_success'.tr(),
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          'backup_error'.tr(namedArgs: {'error': e.toString()}),
          type: NotificationType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _trimOldBackups(Directory dir) async {
    final entities = await dir.list().toList();
    final files = entities
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    if (files.length > _maxBackups) {
      for (final file in files.sublist(_maxBackups)) {
        await file.delete();
      }
    }
  }

  // ── Restore ─────────────────────────────────────────────────────────────────

  Future<void> _confirmRestore(File backupFile) async {
    final dateStr = _parseDateFromFilename(p.basename(backupFile.path));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('restore_confirm_title'.tr()),
        content: Text(
          'restore_confirm_body'.tr(namedArgs: {'date': dateStr}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('btn_cancel'.tr()),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('btn_restore'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _doRestore(backupFile);
  }

  Future<void> _doRestore(File backupFile) async {
    setState(() => _isRestoring = true);
    try {
      // 1. Flush WAL and release file lock
      final db = await DatabaseHelper.instance.database;
      await db.execute('PRAGMA wal_checkpoint(FULL)');
      await DatabaseHelper.instance.closeDatabase();

      final dbPath = await DatabaseHelper.instance.databasePath;
      final dbFile = File(dbPath);
      final bakFile = File('$dbPath.bak');

      // 2. Atomic swap: rename current → .bak
      await dbFile.rename(bakFile.path);
      try {
        // 2a. Remove stale WAL/SHM files (invalidated by the rename)
        final walFile = File('$dbPath-wal');
        final shmFile = File('$dbPath-shm');
        if (await walFile.exists()) await walFile.delete();
        if (await shmFile.exists()) await shmFile.delete();

        // 2b. Copy chosen backup → active DB path
        await backupFile.copy(dbPath);

        // 2c. All good — drop the safety copy
        await bakFile.delete();
      } catch (e) {
        // Rollback: put the original DB back
        if (await bakFile.exists()) await bakFile.rename(dbPath);
        rethrow;
      }

      // 3. Brief success message, then soft-restart the app
      if (mounted) {
        AppNotification.show(
          context,
          'restore_success'.tr(),
          type: NotificationType.success,
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) RestartWidget.restartApp(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRestoring = false);
        AppNotification.show(
          context,
          'restore_error'.tr(namedArgs: {'error': e.toString()}),
          type: NotificationType.error,
        );
      }
    }
  }

  // ── Delete backup ───────────────────────────────────────────────────────────

  Future<void> _confirmDeleteBackup(File backupFile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('confirm_delete_title'.tr()),
        content: Text('backup_delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('btn_cancel'.tr()),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('btn_delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await backupFile.delete();
    await _loadBackups();
    if (mounted) {
      AppNotification.show(
        context,
        'backup_deleted'.tr(),
        type: NotificationType.success,
      );
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Converts `OpticaSana_2026-04-14_15-30-00.db` → `14/04/2026  15:30:00`
  String _parseDateFromFilename(String filename) {
    final m = RegExp(
      r'(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})-(\d{2})',
    ).firstMatch(filename);
    if (m == null) return filename.replaceAll('.db', '');
    return '${m.group(3)}/${m.group(2)}/${m.group(1)}'
        '  ${m.group(4)}:${m.group(5)}:${m.group(6)}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('backup_screen_title'.tr())),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: _isRestoring
            ? _buildRestoringOverlay()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCreateCard(),
                  _buildListHeader(),
                  Expanded(child: _buildBackupList()),
                ],
              ),
      ),
    );
  }

  Widget _buildRestoringOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'restore_success'.tr(),
            style: const TextStyle(color: AppColors.displayValue, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDefault),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'backup_section_title'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'backup_section_subtitle'.tr(),
              style: TextStyle(
                color: AppColors.label.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isCreatingBackup
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.bgDark,
                        ),
                      )
                    : const Icon(Icons.backup_outlined),
                label: Text(
                  _isCreatingBackup
                      ? 'backup_creating'.tr()
                      : 'backup_create_btn'.tr(),
                ),
                onPressed: _isCreatingBackup ? null : _createBackup,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.success, width: 3),
          ),
        ),
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          'backup_list_title'.tr(
            namedArgs: {'count': _backups.length.toString()},
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  Widget _buildBackupList() {
    if (_backups.isEmpty) {
      return Center(
        child: Text(
          'backup_no_backups'.tr(),
          style: TextStyle(color: AppColors.label.withValues(alpha: 0.7)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _backups.length,
      itemBuilder: (context, index) => _buildBackupItem(_backups[index]),
    );
  }

  Widget _buildBackupItem(File file) {
    final dateStr = _parseDateFromFilename(p.basename(file.path));
    final sizeBytes = file.lengthSync();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDefault),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.storage_outlined,
              color: AppColors.label,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: AppColors.displayValue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatSize(sizeBytes),
                    style: TextStyle(
                      color: AppColors.label.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              onPressed: () => _confirmRestore(file),
              child: Text('btn_restore'.tr()),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 20,
              ),
              tooltip: 'menu_delete'.tr(),
              onPressed: () => _confirmDeleteBackup(file),
            ),
          ],
        ),
      ),
    );
  }
}
