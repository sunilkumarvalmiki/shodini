import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:llm_app/data/models/chat_message.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FilePreviewWidget extends StatefulWidget {
  final AttachedFile file;
  final VoidCallback? onRemove;
  final bool showRemoveButton;

  const FilePreviewWidget({
    super.key,
    required this.file,
    this.onRemove,
    this.showRemoveButton = true,
  });

  @override
  State<FilePreviewWidget> createState() => _FilePreviewWidgetState();
}

class _FilePreviewWidgetState extends State<FilePreviewWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondaryContainer
                  .withOpacity(0.7),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildFileTypeIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.showRemoveButton) ...[
                  Text(
                    _formatFileSize(widget.file.size),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.onRemove != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      constraints: const BoxConstraints(
                        minHeight: 32,
                        minWidth: 32,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: widget.onRemove,
                      tooltip: 'Remove file',
                    ),
                ],
              ],
            ),
          ),

          // File preview
          if (_isImageFile())
            _buildImagePreview(context)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tap to view ${widget.file.type.toUpperCase()} file details',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileTypeIcon() {
    IconData iconData = Icons.insert_drive_file;
    Color iconColor = Colors.blueGrey;

    switch (widget.file.type.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red.shade300;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description;
        iconColor = Colors.blue.shade700;
        break;
      case 'txt':
      case 'md':
        iconData = Icons.text_snippet;
        iconColor = Colors.blueGrey.shade700;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        iconData = Icons.image;
        iconColor = Colors.green.shade700;
        break;
      case 'csv':
      case 'xlsx':
      case 'xls':
        iconData = Icons.table_chart;
        iconColor = Colors.green.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        size: 20,
        color: iconColor,
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    const double maxHeight = 200;

    try {
      if (kIsWeb) {
        if (widget.file.bytes != null) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: maxHeight),
            child: Image.memory(
              widget.file.bytes!,
              fit: BoxFit.contain,
              frameBuilder: (_, child, frame, __) {
                if (frame == null) {
                  return const Center(
                    heightFactor: 2.5,
                    child: CircularProgressIndicator(),
                  );
                }
                return child;
              },
              errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
            ),
          );
        }
      } else if (widget.file.path.isNotEmpty) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: maxHeight),
          child: Image.file(
            File(widget.file.path),
            fit: BoxFit.contain,
            frameBuilder: (_, child, frame, __) {
              if (frame == null) {
                return const Center(
                  heightFactor: 2.5,
                  child: CircularProgressIndicator(),
                );
              }
              return child;
            },
            errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
          ),
        );
      }

      // Fallback if no data
      return _buildErrorPlaceholder();
    } catch (e) {
      return _buildErrorPlaceholder();
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      height: 100,
      width: double.infinity,
      color: Colors.grey.withOpacity(0.1),
      child: const Center(
        child: Text('Image preview unavailable'),
      ),
    );
  }

  bool _isImageFile() {
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp']
        .contains(widget.file.type.toLowerCase());
  }

  String _formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    num size = bytes;

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }
}

// Widget to handle visibility detection and memory management for lazy loading
class VisibilityAwareFilePreview extends StatefulWidget {
  final AttachedFile file;
  final VoidCallback? onRemove;
  final bool showRemoveButton;

  const VisibilityAwareFilePreview({
    super.key,
    required this.file,
    this.onRemove,
    this.showRemoveButton = true,
  });

  @override
  State<VisibilityAwareFilePreview> createState() =>
      _VisibilityAwareFilePreviewState();
}

class _VisibilityAwareFilePreviewState
    extends State<VisibilityAwareFilePreview> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('file_preview_${widget.file.name}'),
      onVisibilityChanged: (VisibilityInfo info) {
        final visible = info.visibleFraction > 0;
        if (visible != _isVisible) {
          setState(() {
            _isVisible = visible;
          });
        }
      },
      child: FilePreviewWidget(
        file: widget.file,
        onRemove: widget.onRemove,
        showRemoveButton: widget.showRemoveButton,
      ),
    );
  }
}
