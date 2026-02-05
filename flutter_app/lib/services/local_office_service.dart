import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;

/// Local Office Service - creates real PPTX and DOCX files
class LocalOfficeService {
  static const _uuid = Uuid();

  /// Get output directory for saving files
  Future<Directory> _getOutputDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = Directory(path.join(dir.path, 'docxpress_output'));
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    return outputDir;
  }

  /// Convert images to PPTX (PowerPoint) file
  Future<String> imagesToPptx({
    required List<String> imagePaths,
    String? title,
  }) async {
    debugPrint(
        '📄 [OFFICE SERVICE] Creating PPTX from ${imagePaths.length} images');

    // Read and process images
    final imageDataList = <_ImageData>[];
    for (int i = 0; i < imagePaths.length; i++) {
      final file = File(imagePaths[i]);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          // Convert to PNG for PPTX compatibility
          final pngBytes = img.encodePng(decoded);
          imageDataList.add(_ImageData(
            bytes: Uint8List.fromList(pngBytes),
            width: decoded.width,
            height: decoded.height,
            index: i + 1,
          ));
        }
      }
    }

    if (imageDataList.isEmpty) {
      throw Exception('No valid images found');
    }

    // Create PPTX in isolate
    final pptxBytes = await compute(
      _createPptxInIsolate,
      _PptxParams(images: imageDataList, title: title ?? 'Presentation'),
    );

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      '${title ?? 'presentation'}_${_uuid.v4()}.pptx',
    );

    await File(outputPath).writeAsBytes(pptxBytes);
    debugPrint('✅ [OFFICE SERVICE] PPTX created: $outputPath');
    return outputPath;
  }

  /// Convert images to DOCX (Word) file
  Future<String> imagesToDocx({
    required List<String> imagePaths,
    String? title,
  }) async {
    debugPrint(
        '📄 [OFFICE SERVICE] Creating DOCX from ${imagePaths.length} images');

    // Read and process images
    final imageDataList = <_ImageData>[];
    for (int i = 0; i < imagePaths.length; i++) {
      final file = File(imagePaths[i]);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          // Convert to PNG for DOCX compatibility
          final pngBytes = img.encodePng(decoded);
          imageDataList.add(_ImageData(
            bytes: Uint8List.fromList(pngBytes),
            width: decoded.width,
            height: decoded.height,
            index: i + 1,
          ));
        }
      }
    }

    if (imageDataList.isEmpty) {
      throw Exception('No valid images found');
    }

    // Create DOCX in isolate
    final docxBytes = await compute(
      _createDocxInIsolate,
      _DocxParams(images: imageDataList, title: title ?? 'Document'),
    );

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      '${title ?? 'document'}_${_uuid.v4()}.docx',
    );

    await File(outputPath).writeAsBytes(docxBytes);
    debugPrint('✅ [OFFICE SERVICE] DOCX created: $outputPath');
    return outputPath;
  }
}

/// Image data for document creation
class _ImageData {
  final Uint8List bytes;
  final int width;
  final int height;
  final int index;

  _ImageData({
    required this.bytes,
    required this.width,
    required this.height,
    required this.index,
  });
}

/// Parameters for PPTX creation
class _PptxParams {
  final List<_ImageData> images;
  final String title;

  _PptxParams({required this.images, required this.title});
}

/// Parameters for DOCX creation
class _DocxParams {
  final List<_ImageData> images;
  final String title;

  _DocxParams({required this.images, required this.title});
}

/// Create PPTX file in isolate
Uint8List _createPptxInIsolate(_PptxParams params) {
  final archive = Archive();

  // [Content_Types].xml
  archive.addFile(ArchiveFile(
    '[Content_Types].xml',
    _getPptxContentTypes(params.images.length).length,
    _getPptxContentTypes(params.images.length).codeUnits,
  ));

  // _rels/.rels
  archive.addFile(ArchiveFile(
    '_rels/.rels',
    _pptxRels.length,
    _pptxRels.codeUnits,
  ));

  // ppt/presentation.xml
  archive.addFile(ArchiveFile(
    'ppt/presentation.xml',
    _getPptxPresentation(params.images.length).length,
    _getPptxPresentation(params.images.length).codeUnits,
  ));

  // ppt/_rels/presentation.xml.rels
  archive.addFile(ArchiveFile(
    'ppt/_rels/presentation.xml.rels',
    _getPptxPresentationRels(params.images.length).length,
    _getPptxPresentationRels(params.images.length).codeUnits,
  ));

  // Add slides and images
  for (int i = 0; i < params.images.length; i++) {
    final slideNum = i + 1;
    final imageData = params.images[i];

    // Slide XML
    final slideXml = _getPptxSlide(slideNum, imageData.width, imageData.height);
    archive.addFile(ArchiveFile(
      'ppt/slides/slide$slideNum.xml',
      slideXml.length,
      slideXml.codeUnits,
    ));

    // Slide rels
    final slideRels = _getPptxSlideRels(slideNum);
    archive.addFile(ArchiveFile(
      'ppt/slides/_rels/slide$slideNum.xml.rels',
      slideRels.length,
      slideRels.codeUnits,
    ));

    // Image file
    archive.addFile(ArchiveFile(
      'ppt/media/image$slideNum.png',
      imageData.bytes.length,
      imageData.bytes,
    ));
  }

  // Slide layouts and masters (minimal required)
  archive.addFile(ArchiveFile(
    'ppt/slideLayouts/slideLayout1.xml',
    _pptxSlideLayout.length,
    _pptxSlideLayout.codeUnits,
  ));

  archive.addFile(ArchiveFile(
    'ppt/slideLayouts/_rels/slideLayout1.xml.rels',
    _pptxSlideLayoutRels.length,
    _pptxSlideLayoutRels.codeUnits,
  ));

  archive.addFile(ArchiveFile(
    'ppt/slideMasters/slideMaster1.xml',
    _pptxSlideMaster.length,
    _pptxSlideMaster.codeUnits,
  ));

  archive.addFile(ArchiveFile(
    'ppt/slideMasters/_rels/slideMaster1.xml.rels',
    _getPptxSlideMasterRels(params.images.length).length,
    _getPptxSlideMasterRels(params.images.length).codeUnits,
  ));

  archive.addFile(ArchiveFile(
    'ppt/theme/theme1.xml',
    _pptxTheme.length,
    _pptxTheme.codeUnits,
  ));

  final zipData = ZipEncoder().encode(archive);
  return Uint8List.fromList(zipData!);
}

/// Create DOCX file in isolate
Uint8List _createDocxInIsolate(_DocxParams params) {
  final archive = Archive();

  // [Content_Types].xml
  archive.addFile(ArchiveFile(
    '[Content_Types].xml',
    _getDocxContentTypes(params.images.length).length,
    _getDocxContentTypes(params.images.length).codeUnits,
  ));

  // _rels/.rels
  archive.addFile(ArchiveFile(
    '_rels/.rels',
    _docxRels.length,
    _docxRels.codeUnits,
  ));

  // word/document.xml
  final documentXml = _getDocxDocument(params.images, params.title);
  archive.addFile(ArchiveFile(
    'word/document.xml',
    documentXml.length,
    documentXml.codeUnits,
  ));

  // word/_rels/document.xml.rels
  archive.addFile(ArchiveFile(
    'word/_rels/document.xml.rels',
    _getDocxDocumentRels(params.images.length).length,
    _getDocxDocumentRels(params.images.length).codeUnits,
  ));

  // Add images
  for (int i = 0; i < params.images.length; i++) {
    archive.addFile(ArchiveFile(
      'word/media/image${i + 1}.png',
      params.images[i].bytes.length,
      params.images[i].bytes,
    ));
  }

  // word/styles.xml
  archive.addFile(ArchiveFile(
    'word/styles.xml',
    _docxStyles.length,
    _docxStyles.codeUnits,
  ));

  final zipData = ZipEncoder().encode(archive);
  return Uint8List.fromList(zipData!);
}

// ==================== PPTX XML Templates ====================

String _getPptxContentTypes(int slideCount) {
  final slideTypes = List.generate(
          slideCount,
          (i) =>
              '<Override PartName="/ppt/slides/slide${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>')
      .join('\n');

  final imageTypes = List.generate(slideCount,
          (i) => '<Default Extension="png" ContentType="image/png"/>')
      .take(1)
      .join('\n');

  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
$imageTypes
<Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
<Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>
<Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>
<Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
$slideTypes
</Types>''';
}

const _pptxRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
</Relationships>''';

String _getPptxPresentation(int slideCount) {
  final slideIds = List.generate(
          slideCount, (i) => '<p:sldId id="${256 + i}" r:id="rId${i + 2}"/>')
      .join('\n');

  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
<p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>
<p:sldIdLst>
$slideIds
</p:sldIdLst>
<p:sldSz cx="9144000" cy="6858000" type="screen4x3"/>
<p:notesSz cx="6858000" cy="9144000"/>
</p:presentation>''';
}

String _getPptxPresentationRels(int slideCount) {
  final slideRels = List.generate(
          slideCount,
          (i) =>
              '<Relationship Id="rId${i + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide${i + 1}.xml"/>')
      .join('\n');

  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>
$slideRels
<Relationship Id="rId${slideCount + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>
</Relationships>''';
}

String _getPptxSlide(int slideNum, int imgWidth, int imgHeight) {
  // Convert pixels to EMUs (914400 EMUs = 1 inch, assume 96 DPI)
  final emuWidth = (imgWidth * 914400 / 96).round();
  final emuHeight = (imgHeight * 914400 / 96).round();

  // Scale to fit slide (9144000 x 6858000 EMUs)
  final maxWidth = 8000000;
  final maxHeight = 6000000;

  double scale = 1.0;
  if (emuWidth > maxWidth || emuHeight > maxHeight) {
    scale = [maxWidth / emuWidth, maxHeight / emuHeight]
        .reduce((a, b) => a < b ? a : b);
  }

  final finalWidth = (emuWidth * scale).round();
  final finalHeight = (emuHeight * scale).round();

  // Center position
  final offsetX = ((9144000 - finalWidth) / 2).round();
  final offsetY = ((6858000 - finalHeight) / 2).round();

  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
<p:cSld>
<p:spTree>
<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
<p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>
<p:pic>
<p:nvPicPr><p:cNvPr id="2" name="Image $slideNum"/><p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr><p:nvPr/></p:nvPicPr>
<p:blipFill><a:blip r:embed="rId1"/><a:stretch><a:fillRect/></a:stretch></p:blipFill>
<p:spPr><a:xfrm><a:off x="$offsetX" y="$offsetY"/><a:ext cx="$finalWidth" cy="$finalHeight"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>
</p:pic>
</p:spTree>
</p:cSld>
<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sld>''';
}

String _getPptxSlideRels(int slideNum) {
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/image$slideNum.png"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
</Relationships>''';
}

const _pptxSlideLayout =
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="blank">
<p:cSld name="Blank"><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr></p:spTree></p:cSld>
<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sldLayout>''';

const _pptxSlideLayoutRels =
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>
</Relationships>''';

const _pptxSlideMaster =
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
<p:cSld><p:bg><p:bgRef idx="1001"><a:schemeClr val="bg1"/></p:bgRef></p:bg><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr></p:spTree></p:cSld>
<p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>
<p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1"/></p:sldLayoutIdLst>
</p:sldMaster>''';

String _getPptxSlideMasterRels(int slideCount) {
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>
</Relationships>''';
}

const _pptxTheme = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme">
<a:themeElements>
<a:clrScheme name="Office">
<a:dk1><a:sysClr val="windowText" lastClr="000000"/></a:dk1>
<a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1>
<a:dk2><a:srgbClr val="44546A"/></a:dk2>
<a:lt2><a:srgbClr val="E7E6E6"/></a:lt2>
<a:accent1><a:srgbClr val="5B9BD5"/></a:accent1>
<a:accent2><a:srgbClr val="ED7D31"/></a:accent2>
<a:accent3><a:srgbClr val="A5A5A5"/></a:accent3>
<a:accent4><a:srgbClr val="FFC000"/></a:accent4>
<a:accent5><a:srgbClr val="4472C4"/></a:accent5>
<a:accent6><a:srgbClr val="70AD47"/></a:accent6>
<a:hlink><a:srgbClr val="0563C1"/></a:hlink>
<a:folHlink><a:srgbClr val="954F72"/></a:folHlink>
</a:clrScheme>
<a:fontScheme name="Office"><a:majorFont><a:latin typeface="Calibri Light"/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont><a:minorFont><a:latin typeface="Calibri"/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont></a:fontScheme>
<a:fmtScheme name="Office"><a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:fillStyleLst><a:lnStyleLst><a:ln w="6350"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln><a:ln w="12700"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln><a:ln w="19050"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln></a:lnStyleLst><a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst><a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:bgFillStyleLst></a:fmtScheme>
</a:themeElements>
</a:theme>''';

// ==================== DOCX XML Templates ====================

String _getDocxContentTypes(int imageCount) {
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Default Extension="png" ContentType="image/png"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';
}

const _docxRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

String _getDocxDocument(List<_ImageData> images, String title) {
  final imageParagraphs = <String>[];

  for (int i = 0; i < images.length; i++) {
    final img = images[i];
    // Convert to EMUs (max width ~6 inches = 5486400 EMUs)
    final maxWidth = 5486400;
    final maxHeight = 7000000;

    var emuWidth = (img.width * 914400 / 96).round();
    var emuHeight = (img.height * 914400 / 96).round();

    if (emuWidth > maxWidth || emuHeight > maxHeight) {
      final scale = [maxWidth / emuWidth, maxHeight / emuHeight]
          .reduce((a, b) => a < b ? a : b);
      emuWidth = (emuWidth * scale).round();
      emuHeight = (emuHeight * scale).round();
    }

    imageParagraphs.add('''
<w:p>
  <w:pPr><w:jc w:val="center"/></w:pPr>
  <w:r>
    <w:drawing>
      <wp:inline xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">
        <wp:extent cx="$emuWidth" cy="$emuHeight"/>
        <wp:docPr id="${i + 1}" name="Image ${i + 1}"/>
        <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
          <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
            <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
              <pic:nvPicPr><pic:cNvPr id="${i + 1}" name="Image ${i + 1}"/><pic:cNvPicPr/></pic:nvPicPr>
              <pic:blipFill><a:blip r:embed="rId${i + 2}"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>
              <pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$emuWidth" cy="$emuHeight"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>
            </pic:pic>
          </a:graphicData>
        </a:graphic>
      </wp:inline>
    </w:drawing>
  </w:r>
</w:p>
<w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:t>Image ${i + 1}</w:t></w:r></w:p>
<w:p/>''');
  }

  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<w:body>
<w:p><w:pPr><w:pStyle w:val="Title"/><w:jc w:val="center"/></w:pPr><w:r><w:t>$title</w:t></w:r></w:p>
<w:p/>
${imageParagraphs.join('\n')}
</w:body>
</w:document>''';
}

String _getDocxDocumentRels(int imageCount) {
  final imageRels = List.generate(
          imageCount,
          (i) =>
              '<Relationship Id="rId${i + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image${i + 1}.png"/>')
      .join('\n');

  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
$imageRels
</Relationships>''';
}

const _docxStyles = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:style w:type="paragraph" w:styleId="Title">
<w:name w:val="Title"/>
<w:rPr><w:b/><w:sz w:val="56"/></w:rPr>
</w:style>
<w:style w:type="paragraph" w:styleId="Normal" w:default="1">
<w:name w:val="Normal"/>
<w:rPr><w:sz w:val="24"/></w:rPr>
</w:style>
</w:styles>''';
