// Cross-platform file download helper.
// On web: triggers browser download via dart:html Blob/AnchorElement.
// On other platforms: no-op (file downloads are web-only in this admin app).
export 'web_download_helper_stub.dart'
    if (dart.library.html) 'web_download_helper_web.dart';
