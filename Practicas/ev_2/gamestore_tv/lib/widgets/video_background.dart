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
      _disposeElement(_viewTypeFor(old.src));
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
    _disposeElement(_viewType);
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
      ..preload = 'auto'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.opacity = '0.9';
    _elementsByViewType[viewType] = video;
    video.addEventListener(
      'error',
      ((web.Event event) {
        for (final cb in _errorListeners[src] ?? <void Function()>[]) {
          cb();
        }
      }).toJS,
    );
    // play() explícito: en los platform views de Flutter web el atributo
    // `autoplay` no siempre dispara la reproducción. Se invoca al crear el
    // elemento (retardo corto para garantizar que ya esté en el DOM) y de
    // nuevo cuando hay metadatos/bytes reproducibles.
    void play() {
      video.play();
    }

    video.addEventListener(
      'loadedmetadata',
      ((web.Event event) => play()).toJS,
    );
    video.addEventListener(
      'canplay',
      ((web.Event event) => play()).toJS,
    );
    web.window.setTimeout(play.toJS, 100.toJS);
    return video;
  });
  return viewType;
}

/// Elementos `<video>` creados por las factories para poder liberarlos cuando
/// el widget desaparece. En Flutter web, si el platform view se desmonta sin
/// limpiar el elemento, el último frame queda "pegado" sobre el lienzo.
final Map<String, web.HTMLVideoElement> _elementsByViewType = {};

/// Detiene y limpia el `<video>` de una vista para soltar su último frame.
void _disposeElement(String viewType) {
  final video = _elementsByViewType.remove(viewType);
  if (video == null) return;
  video.pause();
  video.removeAttribute('src');
  video.load();
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
