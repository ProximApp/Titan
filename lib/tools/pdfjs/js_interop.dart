import 'dart:js_interop';

@JS('loadPdfJs')
external JSPromise<JSAny?> _loadPdfJs();

/// Downloads pdf.js, unless a previous call already did.
///
/// `pdfx` reads `pdfjsLib` and `pdfRenderOptions` off the global scope when it
/// opens a document and throws if they are missing, so this has to be awaited
/// before building a `PdfView`. Loading it here rather than from a `<script>`
/// tag keeps ~92 KB and a third-party connection off every cold start, since
/// only the PH module ever displays a PDF.
Future<void> ensurePdfJs() async {
  await _loadPdfJs().toDart;
}
