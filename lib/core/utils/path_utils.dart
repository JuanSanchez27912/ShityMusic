String normalizeFolderPath(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final normalized = trimmed
      .replaceAll('\\', '/')
      .replaceAll(RegExp('/+'), '/');
  if (normalized.length > 1 && normalized.endsWith('/')) {
    return normalized.substring(0, normalized.length - 1);
  }

  return normalized;
}

String extractFolderPath(String filePath) {
  final normalized = normalizeFolderPath(filePath);
  final lastSlash = normalized.lastIndexOf('/');

  if (lastSlash <= 0) {
    return '';
  }

  return normalized.substring(0, lastSlash);
}

bool pathMatchesExcludedFolder(
  String filePath,
  Iterable<String> excludedFolders,
) {
  final normalizedFilePath = normalizeFolderPath(filePath).toLowerCase();

  for (final folder in excludedFolders) {
    final normalizedFolder = normalizeFolderPath(folder).toLowerCase();
    if (normalizedFolder.isEmpty) {
      continue;
    }

    if (normalizedFilePath == normalizedFolder ||
        normalizedFilePath.startsWith('$normalizedFolder/')) {
      return true;
    }
  }

  return false;
}

List<String> collectFolderSuggestions(
  Iterable<String> filePaths, {
  int limit = 10,
}) {
  final counts = <String, int>{};

  for (final filePath in filePaths) {
    final folder = extractFolderPath(filePath);
    if (folder.isEmpty) {
      continue;
    }

    counts.update(folder, (value) => value + 1, ifAbsent: () => 1);
  }

  final rankedFolders = counts.entries.toList()
    ..sort((a, b) {
      final countOrder = b.value.compareTo(a.value);
      if (countOrder != 0) {
        return countOrder;
      }
      return a.key.compareTo(b.key);
    });

  return rankedFolders
      .take(limit)
      .map((entry) => entry.key)
      .toList(growable: false);
}
