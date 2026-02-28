import 'package:equatable/equatable.dart';

/// Result of a backup or restore operation.
sealed class BackupRestoreResult extends Equatable {
  const BackupRestoreResult();
}

/// Backup completed successfully. [path] is the backup filename shared.
class BackupSuccess extends BackupRestoreResult {
  const BackupSuccess({required this.path});
  final String path;

  @override
  List<Object?> get props => [path];
}

/// Restore completed successfully.
class RestoreSuccess extends BackupRestoreResult {
  const RestoreSuccess();

  @override
  List<Object?> get props => [];
}

/// User cancelled the operation (e.g. dismissed file picker).
class BackupRestoreCancelled extends BackupRestoreResult {
  const BackupRestoreCancelled();

  @override
  List<Object?> get props => [];
}

/// Operation failed with an error.
class BackupRestoreFailure extends BackupRestoreResult {
  const BackupRestoreFailure({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}
