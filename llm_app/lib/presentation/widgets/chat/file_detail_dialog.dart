import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:llm_app/data/models/chat_message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;

class FileDetailDialog extends StatelessWidget {
  final AttachedFile file;

  const FileDetailDialog({
    Key? key,
    required this.file,
  }) : super(key: key);

  String _formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    num size = bytes;

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(i == 0 ? 0 : 2)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Row(
                children: [
                  _buildFileTypeIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${file.type.toUpperCase()} · ${_formatFileSize(file.size)}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // File metadata
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline),
                    title: const Text('File Info'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name: ${file.name}'),
                        Text('Type: ${file.type.toUpperCase()}'),
                        Text('Size: ${_formatFileSize(file.size)}'),
                        if (file.path.isNotEmpty) Text('Path: ${file.path}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // File preview
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: _buildPreviewContent(),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    onPressed: () {
                      // Handle file download
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'File download functionality will be implemented'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTypeIcon() {
    IconData iconData = Icons.insert_drive_file;
    Color iconColor = Colors.blueGrey;

    switch (file.type.toLowerCase()) {
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
        iconData = Icons.image;
        iconColor = Colors.green.shade700;
        break;
      case 'csv':
      case 'xlsx':
      case 'xls':
        iconData = Icons.table_chart;
        iconColor = Colors.green.shade700;
        break;
      case 'mp4':
      case 'mov':
      case 'avi':
        iconData = Icons.movie;
        iconColor = Colors.red.shade400;
        break;
      case 'mp3':
      case 'wav':
      case 'm4a':
        iconData = Icons.audio_file;
        iconColor = Colors.purple.shade400;
        break;
      case 'zip':
      case 'rar':
      case '7z':
        iconData = Icons.folder_zip;
        iconColor = Colors.amber.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        size: 28,
        color: iconColor,
      ),
    );
  }

  Widget _buildPreviewContent() {
    final fileType = file.type.toLowerCase();

    // Image preview
    if (['jpg', 'jpeg', 'png', 'gif'].contains(fileType)) {
      return _buildImagePreview();
    }

    // Text preview
    if (['txt', 'md', 'json', 'csv'].contains(fileType)) {
      return _buildTextPreview();
    }

    // PDF preview
    if (fileType == 'pdf') {
      return _buildPdfPreview();
    }

    // Video preview
    if (['mp4', 'mov', 'avi'].contains(fileType)) {
      return _buildVideoPreview();
    }

    // Audio preview
    if (['mp3', 'wav', 'm4a'].contains(fileType)) {
      return _buildAudioPreview();
    }

    // Generic preview for other file types
    return _buildGenericPreview();
  }

  Widget _buildImagePreview() {
    if (kIsWeb) {
      if (file.bytes != null) {
        return Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.memory(
              Uint8List.fromList(file.bytes!),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPreview();
              },
            ),
          ),
        );
      }
    } else {
      if (file.path.isNotEmpty) {
        return Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.file(
              File(file.path),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPreview();
              },
            ),
          ),
        );
      }
    }

    return _buildErrorPreview();
  }

  Widget _buildTextPreview() {
    String? content;

    try {
      if (kIsWeb) {
        if (file.bytes != null) {
          content = String.fromCharCodes(file.bytes!);
        }
      } else {
        if (file.path.isNotEmpty) {
          content = File(file.path).readAsStringSync();
        }
      }
    } catch (e) {
      return _buildErrorPreview(message: 'Error loading text content: $e');
    }

    if (content == null) {
      return _buildErrorPreview();
    }

    // If it's a markdown file, use markdown renderer
    if (file.type.toLowerCase() == 'md') {
      return Markdown(
        data: content,
        selectable: true,
        padding: EdgeInsets.zero,
      );
    }

    // For other text files
    return SingleChildScrollView(
      child: SelectableText(
        content,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPdfPreview() {
    // This is just a placeholder. In a real app, you would use
    // a PDF viewer package like flutter_pdfview or syncfusion_flutter_pdfviewer
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'PDF Preview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'PDF preview requires additional packages.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    // This is just a placeholder. In a real app, you would use
    // video_player or better_player package
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Video Preview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Video preview requires additional packages.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview() {
    // This is just a placeholder. In a real app, you would use
    // audioplayers or just_audio package
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.audio_file,
            size: 64,
            color: Colors.purple.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Audio Preview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Audio preview requires additional packages.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGenericPreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFileTypeIcon(),
          const SizedBox(height: 16),
          Text(
            file.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'No preview available for ${file.type.toUpperCase()} files',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPreview({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Preview Error',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message ?? 'Unable to preview this file',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
