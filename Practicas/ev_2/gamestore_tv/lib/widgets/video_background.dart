import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:web/web.dart' as web;

/// Fondo de video vía HTML `<video>` (Flutter web).
///
/// Cumple SA.2.C / DE.1:
/// - Lazy load: el elemento `<video>` solo se crea cuando la condición activa
///   (juego seleccionado) lo solicita.
/// - Autoplay + muted + loop, pensado para backdrop.
/// - Si el video no existe, no carga o falla, se muestra [fallback].
class VideoBackground extends StatefulWidget {
  final String src;
  final Widget fallback;
  final VoidCallback? onError;

  const VideoBackground({
    super.key,
    required this.src,
    required this.fallback,
    this.onError,
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  late final String _viewType;
  bool _failed = false;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _viewType = _registerFactory(widget.src);
    _addErrorListener(widget.src, _onVideoError);
    // Si el video no empieza a cargar en 12s, se asume fallo -> fallback.
    _timeout = Timer(const Duration(seconds: 12), _onVideoError);
  }

  @override
  void didUpdateWidget(VideoBackground old) {
    super.didUpdateWidget(old);
    if (old.src != widget.src) {
      _removeErrorListener(old.src, _onVideoError);
      _viewType = _registerFactory(widget.src);
      _addErrorListener(widget.src, _onVideoError);
      _failed = false;
      _timeout?.cancel();
      _timeout = Timer(const Duration(seconds: 12), _onVideoError);
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _removeErrorListener(widget.src, _onVideoError);
    super.dispose();
  }

  void _onVideoError() {
    if (!mounted || _failed) return;
    setState(() => _failed = true);
    widget.onError?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback;
    return HtmlElementView(
      viewType: _viewType,
      hitTestBehavior: PlatformViewHitTestBehavior.transparent,
    );
  }
}

/// ---- Registro único de factories (nunca llamar dentro de build) ----
final Set<String> _registeredViewTypes = {};

String _viewTypeFor(String src) => 'gs-video-${src.hashCode}';

String _registerFactory(String src) {
  final viewType = _viewTypeFor(src);
  if (_registeredViewTypes.contains(viewType)) return viewType;

  _registeredViewTypes.add(viewType);
  ui_web.platformViewRegistry.registerViewFactory(viewType, (
    int viewId, {
    Object? params,
  }) {
    final video = web.HTMLVideoElement()
      ..src = src
      ..autoplay = true
      ..muted = true
      ..loop = true
      ..playsInline = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';
    video.addEventListener(
      'error',
      ((web.Event event) {
        for (final cb in _errorListeners[src] ?? <void Function()>[]) {
          cb();
        }
      }).toJS,
    );
    return video;
  });
  return viewType;
}

/// Estado de error por src: avisa a las vistas activas cuando falla la carga.
final Map<String, List<void Function()>> _errorListeners = {};

void _addErrorListener(String src, void Function() cb) {
  _errorListeners.putIfAbsent(src, () => <void Function()>[]).add(cb);
}

void _removeErrorListener(String src, void Function() cb) {
  final list = _errorListeners[src];
  if (list == null) return;
  list.remove(cb);
  if (list.isEmpty) _errorListeners.remove(src);
}
