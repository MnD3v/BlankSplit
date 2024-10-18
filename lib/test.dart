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
        setState(() {
          progress.value = i.toString() + '/' + doc.length.toString();
        });
        print(i);
        String content = "";
        try {
          content = await doc.pageAt(i).text;
        } catch (e) {}

        if (content.length <= 1) {
          String sep = initalPage.toString() + "-" + (i - 1).toString();
          separates.add(sep);
          initalPage = i + 1;
          print("😍👍🔥🫶🫡");
        }
      }

      if (initalPage <= doc.length) {
        separates.add(initalPage.toString() + "-" + doc.length.toString());
      }
    } else {
      int initalPage = 1;
      int first_blank = 0;
      for (int i = 1; i <= doc.length; i++) {
        setState(() {
          progress.value = i.toString() + '/' + doc.length.toString();
        });

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
            print("😍👍🔥🫶🫡");
          }
          first_blank = i;
        }
      }

      if (initalPage <= doc.length) {
        separates.add(initalPage.toString() + "-" + doc.length.toString());
      }
    }

    List<String>? splitPdfPaths = await PdfManipulator().splitPDF(
      params: PDFSplitterParams(pdfPath: file!.path, pageRanges: separates),
    );
    separates.clear();
    saveToPublicDocuments(splitPdfPaths!);
    Get.back();
  }
