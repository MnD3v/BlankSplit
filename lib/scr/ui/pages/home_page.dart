import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:immobilier_apk/scr/ui/pages/historique.dart';
import 'package:immobilier_apk/scr/ui/pages/view_pdf.dart';
import 'package:my_widgets/my_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var progress = "Initialisation...".obs;
  String nommage = "";

  String dossier = "";

  List<String> separates = <String>[];

  File? file;

  bool simple = true;

  @override
  Widget build(BuildContext context) {
    final scallerFactor = MediaQuery.of(context).textScaleFactor;
    return EScaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Image(
          image: AssetImage("assets/icons/launcher_icon.png"),
          height: 55,
        ),
        actions: [
          IconButton(
              onPressed: () {
                Get.to(Historique());
              },
              icon: Icon(Icons.history))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: EColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            12.h,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      simple = true;
                    });
                  },
                  child: AnimatedOpacity(
                    duration: 333.milliseconds,
                    opacity: simple ? 1 : 0.3,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      width: Get.width / 2 - 20,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          color: Colors.blue.withOpacity(.1),
                          border: Border.all(color: Colors.blue)),
                      child: Column(
                        children: [
                          Image(
                            image: AssetImage("assets/icons/simple.png"),
                            height: 60,
                          ),
                          Text("Pages Simples"),
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      simple = false;
                    });
                  },
                  child: AnimatedOpacity(
                    duration: 333.milliseconds,
                    opacity: !simple ? 1 : 0.3,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      width: Get.width / 2 - 20,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          color: Colors.red.withOpacity(.1),
                          border: Border.all(color: Colors.red)),
                      child: Column(
                        children: [
                          Image(
                            image: AssetImage("assets/icons/recto-verso.png"),
                            height: 60,
                          ),
                          Text("Recto-Verso"),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
            12.h,
            EText("Nom du dossier"),
            ETextField(
              placeholder: "Arrivee Kara 2020",
              initialValue: dossier,
              phoneScallerFactor: scallerFactor,
              onChanged: (text) {
                dossier = text;
              },
            ),
            12.h,
            EText("Nommage"),
            ETextField(
              placeholder: "Arr_kara_2020",
              phoneScallerFactor: scallerFactor,
              initialValue: nommage,
              onChanged: (text) {
                nommage = text;
              },
            ),
            24.h,
            Center(
              child: GestureDetector(
                onTap: () async {
                  await requestStoragePermission();
                  await pickFile();
                },
                child: Container(
                  width: Get.width / 2,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(.1),
                      border: Border.all(color: Colors.teal),
                      borderRadius: BorderRadius.circular(9)),
                  child: Column(
                    children: [
                      Image(
                        image: AssetImage("assets/icons/upload.png"),
                        height: 44,
                        color: Colors.teal,
                      ),
                      EText(
                        "Importer",
                        color: Colors.teal,
                        weight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            24.h,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EText(
                  "Document",
                  size: 24,
                  weight: FontWeight.bold,
                ),
                AnimatedSwitcher(
                  duration: 666.milliseconds,
                  child: file == null
                      ? Center(
                          child: Column(
                            children: [
                              Image(
                                image: AssetImage("assets/icons/aucun.png"),
                                height: 96,
                              ),
                              6.h,
                              EText(
                                "Aucun document selectionné",
                                color: Colors.grey,
                              )
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            GestureDetector(
                              onTap: (){
                                Get.to(ViewPdf(path: file!.path, dossier: dossier, nommage: nommage,));
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 9),
                                decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.red)),
                                child: Row(
                                  children: [
                                    Image(
                                      image: AssetImage("assets/icons/pdf.png"),
                                      height: 40,
                                    ),
                                    6.w,
                                    SizedBox(
                                        width: Get.width - 90,
                                        child: EText(file!.path)),
                                  ],
                                ),
                              ),
                            ),
                            12.h,
                            GestureDetector(
                              onTap: () async {
                                loading(
                                    progress: Obx(() => EText(progress.value)));

                                splitPdf();
                              },
                              child: Container(
                                width: Get.width,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.teal,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: EText(
                                  "Traiter Automatiquement",
                                  color: Colors.white,
                                  weight: FontWeight.bold,
                                ),
                              ),
                            ),
                            9.h,
                            SimpleButton(
                              radius: 6,
                              color: Colors.blue,
                              onTap: () {
                                                                Get.to(ViewPdf(path: file!.path, dossier: dossier, nommage: nommage,));

                           
                              },
                              child: EText(
                                "Traiter Manuellement",
                                color: Colors.white,
                                weight: FontWeight.w800,
                              ),
                            )
                          ],
                        ),
                )
              ],
            ),
            48.h,
          ],
        ),
      ),
    );
  }

  pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        file = File(result.files.single.path!);
      });
    }
    if (!file!.path.endsWith('.pdf')) {
      file = null;
      Custom.showDialog(
          WarningWidget(message: "Veuillez selectionner un fichier pdf"));
      return;
    }
    print(file);
  }

  splitPdf() async {
    if (dossier.isEmpty) {
      Get.back();
      Custom.showDialog(
          WarningWidget(message: "Le nom du dossier ne peut pas etre vide"));
      return;
    }
    if (nommage.isEmpty) {
      Get.back();
      Custom.showDialog(WarningWidget(message: "Veuillez preciser le nommage"));
      return;
    }
    PDFDoc doc = await PDFDoc.fromPath(file!.path);

    progress.value = "0/" + doc.length.toString();

    print(doc.length);

    if (simple) {
      int initalPage = 1;
      for (int i = 1; i <= doc.length; i++) {
        progress.value = i.toString() + '/' + doc.length.toString();

        print(i);
        String content = "";
        try {
          content = await doc.pageAt(i).text;
        } catch (e) {}

        if (content.length <= 1) {
          String sep = initalPage.toString() + "-" + (i - 1).toString();
          separates.add(sep);
          initalPage = i + 1;
        }
      }

      if (initalPage <= doc.length) {
        print("initial depasse");
        separates.add(initalPage.toString() + "-" + doc.length.toString());
      }
      print("end");
    } else {
      int initalPage = 1;
      int first_blank = 0;
      for (int i = 1; i <= doc.length; i++) {
        progress.value = i.toString() + '/' + doc.length.toString();

        print(i);
        String content = "";
        try {
          content = await doc.pageAt(i).text;
        } catch (e) {}

        if (content.length <= 1) {
          if (i == first_blank + 1) {
            String sep = initalPage.toString() + "-" + (i - 2).toString();
            separates.add(sep);
            initalPage = i + 1;
          }
          first_blank = i;
        }
      }

      if (initalPage <= doc.length) {
        separates.add(initalPage.toString() + "-" + doc.length.toString());
      }
    }

    progress.value = "Splitting...";

    List<String>? splitPdfPaths = await PdfManipulator().splitPDF(
      params: PDFSplitterParams(pdfPath: file!.path, pageRanges: separates),
    );
    progress.value = "Saving...";

    await saveToPublicDocuments(splitPdfPaths!);
    separates.clear();
  }

  Future<void> requestStoragePermission() async {
    var status = await Permission.storage.status;

    if (status.isGranted) {
    } else {
      var result = await Permission.storage.request();
    }
  }

  Future<void> saveToPublicDocuments(List<String> tempsPaths) async {
    var status = await Permission.storage.request();

    if (status.isGranted) {
      String externalDocumentsDir =
          '/storage/emulated/0/Documents/Archivage_UGP-AK/$dossier';

      Directory newFolder = Directory(externalDocumentsDir);

      if (!await newFolder.exists()) {
        await newFolder.create(recursive: true);
        print('Dossier créé à : $externalDocumentsDir');
      } else {
        print('Le dossier existe déjà à : $externalDocumentsDir');
      }

      print("Save start");

      for (var i = 0; i < tempsPaths.length; i++) {
        var temp_file = File(tempsPaths[i]);

        String newFilePath = '$externalDocumentsDir/' +
            separates[i] +
            '_$nommage' +
            '_${file!.uri.pathSegments.last.split(".").first}' +
            '_' +
            '${DateTime.now().millisecondsSinceEpoch}.pdf';

        try {
          await temp_file.copy(newFilePath);
          print('Fichier copié à : $newFilePath');
        } catch (e) {
          print('Erreur lors de la copie du fichier : $e');
        }
      }
      print("Save end");

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> doneFiles = prefs.getStringList('doneFiles') ?? [];
      doneFiles.add(
          file!.path + "***" + dossier + "***" + DateTime.now().toString());
      await prefs.setStringList('doneFiles', doneFiles);
      Get.back();
      Custom.showDialog(WillPopScope(
        onWillPop: () async {
          Get.back();
          setState(() {
            file = null;
          });
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
                      text: "/Documents/Archivage_UGP-AK/$dossier/",
                      color: Colors.red)
                ]),
                12.h,
                SimpleButton(
                    onTap: () {
                      Get.back();
                      setState(() {
                        file = null;
                        dossier = "";
                        nommage = "";
                      });
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
