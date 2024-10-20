import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:my_widgets/my_widgets.dart';
import 'package:my_widgets/widgets/column.dart';
import 'package:my_widgets/widgets/loading.dart';
import 'package:my_widgets/widgets/text.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewPdf extends StatefulWidget {
  final String path;
  final String dossier;
  final String nommage;

  ViewPdf(
      {Key? key,
      required this.path,
      required this.dossier,
      required this.nommage})
      : super(key: key);

  _ViewPdfState createState() => _ViewPdfState();
}

class _ViewPdfState extends State<ViewPdf> with WidgetsBindingObserver {
  final Completer<PDFViewController> _controller =
      Completer<PDFViewController>();
  int? pages = 0;
  int currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  String segment = "";

  @override
  Widget build(BuildContext context) {
    return EScaffold(
      appBar: PreferredSize(
        preferredSize: Size(Get.width, 120),
        child: EColumn(children: [
          Row(
            children: [
              Image(image: AssetImage("assets/icons/launcher_icon.png"), height: 40,),
              EText(
                "Traitement",
                weight: FontWeight.w700,
              ),
            ],
          ),
          ETextRich(textSpans: [
            ETextSpan(
              text: "Entrez le segment à decouper",
            ),
            ETextSpan(
              text: " (Exple: 3-5)",
              color: Colors.teal,
            ),
          ]),
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: Get.width - 100,
                  child: ETextField(
                    placeholder: '1-3',
                    initialValue: segment,
                      onChanged: (text) {
                        segment = text;
                      },
                      phoneScallerFactor: 1),
                ),
                SimpleButton(
                  width: 80,
                  radius: 6,
                  color: Colors.blue,
                  onTap: () async {
                    if (widget.dossier.isEmpty) {
            
                      Custom.showDialog(WarningWidget(
                          message: "Veuillez entrer le nom du dossier de stockage (Dans la page d'accueil)"));
                      return;
                    }
                    if (widget.nommage.isEmpty) {
                      Custom.showDialog(WarningWidget(
                          message: "Veuillez préciser le nommage (Dans la page d'accueil)"));
                      return;
                    }
                    if (segment.contains("-")) {
                      if (segment.split("-").length != 2) {
                        Fluttertoast.showToast(msg: "Entrez un segment valide");
                        return;
                      }
                      if (!segment.split("-")[0].isNum ||
                          !segment.split("-")[1].isNum) {
                        Fluttertoast.showToast(msg: "Entrez un segment valide");

                        return;
                      }
                      if (int.parse(segment.split("-")[0]) >
                          int.parse(segment.split("-")[1])) {
                        Fluttertoast.showToast(msg: "Entrez un segment valide");

                        return;
                      }
                      if (int.parse(segment.split("-")[1]) > pages!) {
                        Fluttertoast.showToast(
                            msg: "Excede le nombre de pages");
                        return;
                      }
                    } else {
                      if (segment.isNum && int.parse(segment)>0) {
                        if (int.parse(segment) > pages!) {
                          Fluttertoast.showToast(
                              msg: "Excede le nombre de pages");
                          return;
                        }
                        segment = segment + '-' + segment;
                      }
                      else{
                        Fluttertoast.showToast(msg: "Segment invalide");
                        return;
                      }
                    }

                    loading();
                    List<String>? splitPdfPaths =
                        await PdfManipulator().splitPDF(
                      params: PDFSplitterParams(
                          pdfPath: widget.path, pageRanges: [segment]),
                    );

                    print(splitPdfPaths);

                    await saveToPublicDocuments(
                        tempPath: splitPdfPaths![0], separate: segment);
                        setState(() {
                    segment = "";
                          
                        });
                  },
                  child: EText(
                    "Couper",
                    weight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              ],
            ),
          ),
          12.h,
        ]),
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.path,

            enableSwipe: true,
            // swipeHorizontal: true,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: currentPage!,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation:
                false, // if set to true the link is handled in flutter
            onRender: (_pages) {
              setState(() {
                pages = _pages;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
              print(error.toString());
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
              print('$page: ${error.toString()}');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _controller.complete(pdfViewController);
            },
            onLinkHandler: (String? uri) {
              print('goto uri: $uri');
            },
            onPageChanged: (int? page, int? total) {
              print('page change: $page/$total');
              setState(() {
                currentPage = page ?? 0;
              });
            },
          ),
          errorMessage.isEmpty
              ? !isReady
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Container()
              : Center(
                  child: Text(errorMessage),
                )
        ],
      ),
      floatingActionButton: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.black, borderRadius: BorderRadius.circular(3)),
        child: EText(
          (currentPage + 1).toString() + "/" + pages.toString(),
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> saveToPublicDocuments(
      {required String tempPath, required separate}) async {
    var status = await Permission.storage.request();

    if (status.isGranted) {
      String externalDocumentsDir =
          '/storage/emulated/0/Documents/Archivage_UGP-AK/${widget.dossier}';

      Directory newFolder = Directory(externalDocumentsDir);

      if (!await newFolder.exists()) {
        await newFolder.create(recursive: true);
        print('Dossier créé à : $externalDocumentsDir');
      } else {
        print('Le dossier existe déjà à : $externalDocumentsDir');
      }

      print("Save start");

      var temp_file = File(tempPath);

      String newFilePath = '$externalDocumentsDir/' +
          separate +
          '_${widget.nommage}' +
          '_${widget.path.split("/").last.split(".").first}' +
          '_' +
          '${DateTime.now().millisecondsSinceEpoch}.pdf';

      try {
        await temp_file.copy(newFilePath);
        print('Fichier copié à : $newFilePath');
      } catch (e) {
        print('Erreur lors de la copie du fichier : $e');
      }

      print("Save end");

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> doneFiles = prefs.getStringList('doneFiles') ?? [];
      doneFiles.add(widget.path +
          "***" +
          widget.dossier +
          "***" +
          DateTime.now().toString());
      await prefs.setStringList('doneFiles', doneFiles);
      Get.back();
      Custom.showDialog(WillPopScope(
        onWillPop: () async {
          Get.back();

          return false;
        },
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(9.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image(
                  image: AssetImage("assets/icons/documents.png"),
                  height: 88,
                ),
                12.h,
                EText(
                  "Document traité avec succès",
                  weight: FontWeight.bold,
                ),
                ETextRich(textSpans: [
                  ETextSpan(text: 'Traitement enregistré dans '),
                  ETextSpan(
                      text: "/Documents/Archivage_UGP-AK/${widget.dossier}/",
                      color: Colors.red)
                ]),
                12.h,
                SimpleButton(
                    onTap: () {
                      Get.back();
                    },
                    child: EText(
                      "Fermer",
                      color: Colors.white,
                    ))
              ],
            ),
          ),
        ),
      ));
    } else {
      print('Permission de stockage refusée');
    }
  }
}
