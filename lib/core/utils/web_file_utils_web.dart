// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:typed_data';
import 'dart:html' as html;

String? createObjectUrlFromBytes(Uint8List bytes, String mimeType) {
  final blob = html.Blob([bytes], mimeType);
  return html.Url.createObjectUrlFromBlob(blob);
}

bool openUrlInNewTab(String url) {
  html.window.open(url, '_blank');
  return true;
}

Future<bool> downloadUrlInBrowser(String url, String fileName) async {
  try {
    final request = await html.HttpRequest.request(
      url,
      method: 'GET',
      responseType: 'blob',
    );
    final blob = request.response as html.Blob?;
    if (blob == null) {
      return false;
    }

    final objectUrl = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: objectUrl)
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(objectUrl);
    return true;
  } catch (_) {
    return false;
  }
}
