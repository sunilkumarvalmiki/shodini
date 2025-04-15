import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:llm_app/data/models/chat_message.dart';
import 'package:llm_app/presentation/widgets/chat/file_detail_dialog.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/scheduler.dart';

// Custom cache manager with extended cache duration for file previews
class FilePreviewCacheManager extends CacheManager {
  static const key = 'filePreviewCache';

  static final FilePreviewCacheManager _instance = FilePreviewCacheManager._();
  factory FilePreviewCacheManager() => _instance;

  FilePreviewCacheManager._()
      : super(Config(
          key,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 200,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ));
}

class FilePreviewWidget extends StatefulWidget {
  final AttachedFile file;
  final VoidCallback? onRemove;
  final bool showRemoveButton;
  final bool isDetailView;
  final Function(AttachedFile)? onTap;

  const FilePreviewWidget({
    Key? key,
    required this.file,
    this.onRemove,
    this.showRemoveButton = true,
    this.isDetailView = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<FilePreviewWidget> createState() => _FilePreviewWidgetState();
}

class _FilePreviewWidgetState extends State<FilePreviewWidget>
    with AutomaticKeepAliveClientMixin {
  bool _isVisible = false;
  bool _hasLoadedData = false;
  final _cacheManager = FilePreviewCacheManager();

  // Memory optimization: Only keep images in memory when in detail view
  @override
  bool get wantKeepAlive => widget.isDetailView;

  @override
  void initState() {
    super.initState();
    // Defer visibility check to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  @override
  void dispose() {
    // Clean up resources when the widget is disposed
    if (widget.file.isImage && !widget.isDetailView) {
      widget.file.clearBytes();
    }
    super.dispose();
  }

  void _checkVisibility() {
    if (!mounted) return;

    // Start with visibility = true and let VisibilityDetector update it
    setState(() {
      _isVisible = true;
    });
  }

  // Only load file data when widget becomes visible
  Future<void> _loadFileDataIfNeeded() async {
    if (_isVisible && !_hasLoadedData && _isImageFile()) {
      _hasLoadedData = true;
      // Load file data in a way that minimizes memory usage
      if (widget.file.bytes == null) {
        // Use compute for heavy operations to avoid jank
        if (!kIsWeb && widget.file.size > 1024 * 1024) {
          // 1MB threshold
          await compute(_loadBytesIsolate, widget.file);
        } else {
          widget.file.loadBytes();
        }
      }
    }
  }

  // Static method for compute isolate
  static Future<void> _loadBytesIsolate(AttachedFile file) async {
    await file.loadBytes();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Load data if needed when visible
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_isVisible) {
        _loadFileDataIfNeeded();
      }
    });

    return VisibilityDetector(
      key: Key('file_preview_${widget.file.id}'),
      onVisibilityChanged: (info) {
        final wasVisible = _isVisible;
        final isNowVisible = info.visibleFraction > 0.1;

        if (wasVisible != isNowVisible) {
          setState(() {
            _isVisible = isNowVisible;
          });

          // Clear memory when widget scrolls out of view
          if (!isNowVisible && !widget.isDetailView && widget.file.isImage) {
            widget.file.clearBytes();
            _hasLoadedData = false;
          } else if (isNowVisible) {
            _loadFileDataIfNeeded();
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        child: GestureDetector(
          onTap: () {
            if (widget.onTap != null) {
              widget.onTap!(widget.file);
            } else {
              showDialog(
                context: context,
                builder: (context) => _buildFileDetailDialog(context),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.7),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
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

              // File preview - only render if the widget is in viewport and visible
              if (_isImageFile())
                _isVisible
                    ? _buildMemoryOptimizedImagePreview(context)
                    : _buildImagePlaceholder(context)
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
        ),
      ),
    );
  }

  // Simple placeholder when image is not in viewport - very lightweight
  Widget _buildImagePlaceholder(BuildContext context) {
    const double maxHeight = 150;
    return Container(
      height: maxHeight,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
      child: Center(
        child: Icon(
          Icons.image,
          size: 32,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
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

  // Memory-optimized image preview with aggressive caching and progressive loading
  Widget _buildMemoryOptimizedImagePreview(BuildContext context) {
    // If not in viewport, don't even try to load
    if (!_isVisible) {
      return _buildImagePlaceholder(context);
    }

    const double maxHeight = 200;

    try {
      if (kIsWeb) {
        // Web platform handling with improved memory management
        if (widget.file.bytes == null) {
          return const Center(
            heightFactor: 2.5,
            child: CircularProgressIndicator(),
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: maxHeight),
          child: Image.memory(
            widget.file.bytes!,
            cacheHeight: 600, // Constrain memory usage
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium, // Better performance
            gaplessPlayback: true, // Smoother transitions
            frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
              if (frame == null) {
                return const Center(
                  heightFactor: 2.5,
                  child: CircularProgressIndicator(),
                );
              }
              return child;
            },
            errorBuilder: (_, error, __) {
              debugPrint('Error loading image: $error');
              return Center(
                heightFactor: 2.5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, color: Colors.grey[500]),
                    const SizedBox(height: 8),
                    Text('Unable to load image',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              );
            },
          ),
        );
      } else {
        // Native platform implementation with enhanced caching
        if (widget.file.path.startsWith('http')) {
          // Network image with CachedNetworkImage for better caching
          return ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: maxHeight),
            child: CachedNetworkImage(
              imageUrl: widget.file.path,
              cacheManager: _cacheManager,
              memCacheWidth: 1200,
              memCacheHeight: 900,
              placeholder: (context, url) => const Center(
                heightFactor: 2.5,
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => Center(
                heightFactor: 2.5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, color: Colors.grey[500]),
                    const SizedBox(height: 8),
                    Text('Unable to load image',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              fadeInDuration: const Duration(milliseconds: 150),
              fadeOutDuration: const Duration(milliseconds: 150),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          );
        } else if (widget.file.path.isNotEmpty) {
          // Local file with caching for better performance
          return ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: maxHeight),
            child: FutureBuilder<File>(
              future: _cacheManager.getSingleFile(widget.file.path),
              builder: (context, snapshot) {
                // Show loading indicator while waiting
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    heightFactor: 2.5,
                    child: CircularProgressIndicator(),
                  );
                }

                // Handle errors loading the file
                if (snapshot.hasError) {
                  debugPrint('Error loading image: ${snapshot.error}');
                  return Center(
                    heightFactor: 2.5,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image, color: Colors.grey[500]),
                        const SizedBox(height: 8),
                        Text('Unable to load image',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                // If we have a valid file
                if (snapshot.hasData) {
                  return Image.file(
                    snapshot.data!,
                    cacheHeight: 600, // Constrain memory usage
                    cacheWidth: 800,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium, // Better performance
                    gaplessPlayback: true, // Smoother transitions
                    frameBuilder: (_, child, frame, __) {
                      if (frame == null) {
                        return const Center(
                          heightFactor: 2.5,
                          child: CircularProgressIndicator(),
                        );
                      }
                      return child;
                    },
                    errorBuilder: (_, __, ___) => Center(
                      heightFactor: 2.5,
                      child: Icon(Icons.broken_image, color: Colors.grey[500]),
                    ),
                  );
                }

                // Display bytes if file not available but bytes are
                if (widget.file.bytes != null) {
                  return Image.memory(
                    widget.file.bytes!,
                    cacheHeight: 600, // Constrain memory usage
                    cacheWidth: 800,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                    frameBuilder: (_, child, frame, __) {
                      if (frame == null) {
                        return const Center(
                          heightFactor: 2.5,
                          child: CircularProgressIndicator(),
                        );
                      }
                      return child;
                    },
                    errorBuilder: (_, __, ___) => Center(
                      heightFactor: 2.5,
                      child: Icon(Icons.broken_image, color: Colors.grey[500]),
                    ),
                  );
                }

                // Fallback if no data available
                return Center(
                  heightFactor: 2.5,
                  child: Text('Image not available',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                );
              },
            ),
          );
        } else if (widget.file.bytes != null) {
          // Use bytes directly with improved memory optimizations
          return ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: maxHeight),
            child: Image.memory(
              widget.file.bytes!,
              cacheHeight: 600, // Constrain memory usage
              cacheWidth: 800,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              frameBuilder: (_, child, frame, __) {
                if (frame == null) {
                  return const Center(
                    heightFactor: 2.5,
                    child: CircularProgressIndicator(),
                  );
                }
                return child;
              },
              errorBuilder: (_, __, ___) => Center(
                heightFactor: 2.5,
                child: Icon(Icons.broken_image, color: Colors.grey[500]),
              ),
            ),
          );
        } else {
          // No data available
          return Center(
            heightFactor: 2.5,
            child: Text('Image not available',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          );
        }
      }
    } catch (e) {
      debugPrint('Error rendering image preview: $e');
      return Center(
        heightFactor: 2.5,
        child: Text('Error loading image',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      );
    }
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

  // Placeholder for file detail dialog
  Widget _buildFileDetailDialog(BuildContext context) {
    return AlertDialog(
      title: Text(widget.file.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isImageFile() && widget.file.bytes != null)
              Image.memory(
                widget.file.bytes!,
                fit: BoxFit.contain,
              ),
            const SizedBox(height: 16),
            Text('Type: ${widget.file.type.toUpperCase()}'),
            Text('Size: ${_formatFileSize(widget.file.size)}'),
            Text('Path: ${widget.file.path}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// Widget to handle visibility detection and memory management for lazy loading
class VisibilityAwareFilePreview extends StatefulWidget {
  final AttachedFile file;
  final VoidCallback? onRemove;
  final bool showRemoveButton;
  final bool isDetailView;
  final Function(AttachedFile)? onTap;

  const VisibilityAwareFilePreview({
    Key? key,
    required this.file,
    this.onRemove,
    this.showRemoveButton = true,
    this.isDetailView = false,
    this.onTap,
  }) : super(key: key);

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
      key: Key('file_preview_${widget.file.id}'),
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
        isDetailView: widget.isDetailView,
        onTap: widget.onTap,
      ),
    );
  }
}

// Helper class for visibility tracking
class _VisibleItemsInfo {
  final int firstVisibleIndex;
  final int lastVisibleIndex;

  _VisibleItemsInfo({
    required this.firstVisibleIndex,
    required this.lastVisibleIndex,
  });
}
