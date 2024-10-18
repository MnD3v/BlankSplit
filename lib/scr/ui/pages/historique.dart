import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_widgets/my_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Historique extends StatefulWidget {
  const Historique({super.key});

  @override
  State<Historique> createState() => _HistoriqueState();
}

class _HistoriqueState extends State<Historique> {
  List<String> doneFiles = [];
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((milliseconds) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        doneFiles = prefs.getStringList('doneFiles') ?? [];
      });
      print(prefs.getStringList('doneFiles'));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return EScaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: EText(
            "Historique",
            weight: FontWeight.bold,
            size: 24,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(9.0),
          child: doneFiles.isEmpty
              ? Align(
                alignment: Alignment.topCenter,
                child: Column(children: [
                    Image(
                      image: AssetImage("assets/icons/aucun.png"),
                      height: 96,
                    ),
                    6.h,
                    EText("Aucun fichier traité")
                  ]),
              )
              : EColumn(
                  children: doneFiles.map((element) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                EText(
                                  element.split("***")[1],
                                  weight: FontWeight.bold,
                                  size: 24,
                                ),
                                EText(element.split("***")[0]),
                                EText(element.split("***")[2], color: 
                                Colors.red,),
                              ],
                            )),
                      ],
                    ),
                  );
                }).toList()),
        ));
  }
}
