// import 'dart:async';
// import 'dart:io';
// import 'dart:developer' as dev;

// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pvm_col/data.dart';

// class Choosefilescreen extends StatefulWidget {
//   const Choosefilescreen({super.key});

//   @override
//   ChoosefilescreenState createState() => ChoosefilescreenState();
// }

// class ChoosefilescreenState extends State<Choosefilescreen> {
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();

//     getExternalStorageDirectoryPath().then((directoryPath) {
//       getFilesFromDirectory(tmpDirPath).then((Files) {
//         setState(() {
//           filePathList = ["None : record only"]; // 맨 처음은 무조건 None이 들어가야 하므로
//           filePathList.addAll(Files);
//           selectedFilePath = filePathList.first;
//         });
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           flex: 2,
//           child: Text(
//             "TX File",
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: baseSize * 2),
//           ),
//         ),
//         Expanded(
//           flex: 3,
//           child: DropdownButton<String>(
//             onTap: () {
//               getExternalStorageDirectoryPath().then((directoryPath) {
//                 getFilesFromDirectory(tmpDirPath).then((Files) {
//                   filePathList = [
//                     "None : record only"
//                   ]; // 맨 처음은 무조건 None이 들어가야 하므로
//                   filePathList.addAll(Files);
//                   selectedFilePath = filePathList.first;
//                   dev.log("file count : ${filePathList.length - 1}");

//                   // setState(() {});
//                 });
//               });
//               setState(() {});
//             },
//             padding: EdgeInsets.only(right: baseSize * 1),
//             alignment: Alignment.center,
//             value: selectedFilePath,
//             onChanged: onFileSelected,
//             items: filePathList.map<DropdownMenuItem<String>>((String value) {
//               return DropdownMenuItem<String>(
//                 value: value,
//                 child: Text(value),
//               );
//             }).toList(),
//           ),
//         ),
//       ],
//     );
//   }

//   // 파일 선택시 실행되는 콜백 함수
//   void onFileSelected(String? filePath) async {
//     if (filePath == "None : record only") {
//       dev.log("isRecOnly is false");
//       setState(() {
//         isRecOnly = false;
//         selectedFilePath = filePath;
//       });
//     } else {
//       dev.log("isRecOnly is true");
//       setState(() {
//         isRecOnly = true;
//         selectedFilePath = filePath;
//       });
//       TXfile = File(selectedFilePath!).readAsStringSync();
//       dev.log(TXfile);
//       // call back
//     }
//     dev.log("selected file path : '${filePath.toString()}'");
//     dev.log("isRecOnly : $isRecOnly");
//   }
// }

// Future<List<String>> getFilesFromDirectory(String directoryPath) async {
//   try {
//     final directory = Directory(directoryPath);
//     final files = await directory.list().toList();
//     return files.whereType<File>().map((file) => file.path).toList();
//   } catch (e) {
//     dev.log('Error fetching files: $e');
//     return [];
//   }
// }

// Future<String> getExternalStorageDirectoryPath() async {
//   final directory = await getExternalStorageDirectory();
//   return directory!.path;
// }
