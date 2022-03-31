import 'dart:convert';
import 'dart:io';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String result = '';
  int index = 567;
  String response = '';
  File? image;
  ImagePicker? imagePicker;
  List<Book> books = [];

  Future<List<Book>> getAPI() async {
    result = result.replaceAll("-","");
    final response = await http.get(Uri.https('www.googleapis.com', '/books/v1/volumes', {
      'q' : 'isbn:$result','key': 'AIzaSyBKr4CegROMzEzkNTjtEXB_HnsNnhoXBr0'
    }));
    var jsonData = jsonDecode(response.body);

    if(response.statusCode == 200 && jsonData['items'][0]['id'] != 'i1lrYuczMUMC'){
      if (kDebugMode) {
        print(jsonData['items'][0]['volumeInfo']['imageLinks'] == null ? jsonData['items'][0]['volumeInfo']['imageLinks']: '');
        print("buuuuuks");
      }

      //jsonData['items'][0]['volumeInfo']['imageLinks']['thumbnail']==null?'':jsonData['items'][0]['volumeInfo']['imageLinks']['thumbnail']
      Book book = Book(jsonData['items'][0]['volumeInfo']['title'],jsonData['items'][0]['volumeInfo']['authors'][0],jsonData['items'][0]['volumeInfo']['industryIdentifiers'][1]['identifier'],jsonData['items'][0]['volumeInfo']['language'],jsonData['items'][0]['volumeInfo']['imageLinks'] == null ? 'https://images-na.ssl-images-amazon.com/images/I/31HvSAclBrL._SY291_BO1,204,203,200_QL40_ML2_.jpg': jsonData['items'][0]['volumeInfo']['imageLinks']['thumbnail']);

      setState(() {
        books.clear();
        books.add(book);
      });

      if (kDebugMode) {
        print(book.title);
        print(result);
        print("booooooks");
      }

      putNotion();

      return books;
    }else {
      if (kDebugMode) {
        print(jsonData['items'][0]['id']);
        print(response.statusCode);
        print(result);
        print("buuuuuks");
      }
      return books;
    }
  }

  putNotion() async {

    var req2 = {
      "query": books[0].title.toString(),
      "sort": {
        "direction": "ascending",
        "timestamp": "last_edited_time"
      },
      "filter": {
        "value": "page",
        "property": "object"
      },
    };

    final exist = await http.post(Uri.https('api.notion.com', '/v1/search'),
        headers: <String, String>{
          'Authorization':'Bearer secret_AVBIoN8FPhZPWrbg6wnGfypUPCVk1GkIaeT6h8aQtKg',
          'Content-Type': 'application/json; charset=utf-8',
          'Notion-Version':'2022-02-22'
        },body:jsonEncode(req2));

    var reqRResp = jsonDecode(exist.body);
    var pres = false;

    for( var r in reqRResp['results']){
      if(r["properties"]["Titre"]["title"][0]["text"]["content"]==books[0].title.toString()){
        if (kDebugMode) {
          print(r["properties"]["Titre"]["title"][0]["text"]["content"]);
          print("tttttt");
        }
        pres = true;
      }
    }

    if(books.isNotEmpty && pres == false){;
      var req = {"parent": {"database_id": "8ddf8cbb7052475c85a8650ca258de64"},"icon": {"emoji": "📕"},"cover": {"external": {"url": books[0].cover.toString()}},"properties": {"Titre":{"title": [{"text": {"content": books[0].title.toString()}}]},"Auteur":{"rich_text": [{"text": {"content": books[0].authors.toString()}}]},"ISBN":{"rich_text": [{"text": {"content": books[0].isbn.toString()}}]},"Langue":{"multi_select": [{"name": books[0].language.toString()}]}}};

      final response = await http.post(Uri.https('api.notion.com', '/v1/pages/'),
          headers: <String, String>{
            'Authorization':'Bearer secret_AVBIoN8FPhZPWrbg6wnGfypUPCVk1GkIaeT6h8aQtKg',
            'Content-Type': 'application/json; charset=utf-8',
            'Notion-Version':'2022-02-22'
          },body:jsonEncode(req));

      if(response.statusCode == 200){
        if (kDebugMode) {
          print(jsonDecode(response.body));
          print("resultat");
        }
        return true;
      }else {
        if (kDebugMode) {
          print(jsonDecode(response.body));
          print("resultat");
        }
        return false;
      }
    }
  }

  pickImageFromGallery() async {
    PickedFile pickedFile =
        await imagePicker!.getImage(source: ImageSource.gallery);
    image = File(pickedFile.path);
    setState(() {
      image;
      performImageLabeling();
    });
  }

  pickImageFromCamera() async {
    PickedFile pickedFile =
        await imagePicker!.getImage(source: ImageSource.camera);
    image = File(pickedFile.path);
    setState(() {
      image;
      performImageLabeling();
    });
  }

  performImageLabeling() async {
    final FirebaseVisionImage firebaseVisionImage =
        FirebaseVisionImage.fromFile(image);
    final TextRecognizer recognizer = FirebaseVision.instance.textRecognizer();
    VisionText visionText = await recognizer.processImage(firebaseVisionImage);

    result = '';
    index = 567;

    setState(() {
      for (TextBlock block in visionText.blocks)
      {
        index = visionText.text.indexOf("ISBN");
        result = visionText.text.substring(index+5,index+22);
      }
    });

    getAPI();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    imagePicker =  ImagePicker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, i){
                  if(books.isEmpty){
                    return const Center(child: Text("Prendre une photo"),);
                  }else {
                    return Center(child: ListTile(title: Text(
                        books[0].title, style: const TextStyle(fontSize: 48)),
                      subtitle: Text(books[0].authors,
                          style: const TextStyle(fontSize: 24)),));
                  }})
            // FutureBuilder(
            //   future: getAPI(),
            //   builder: (context,AsyncSnapshot snapshot){
            //     if(books.isEmpty){
            //       return Container(
            //         height: 280,
            //         child: const Center(
            //           child: Text('Prend une photo'),
            //         ),
            //       );
            //     }else{
            //       return ListView.builder(
            //         itemCount: books.length,
            //         itemBuilder: (context, i){
            //           return Center(child: ListTile(title: Text(books[i].title,style: const TextStyle(fontSize: 48)),subtitle: Text(books[i].authors,style: const TextStyle(fontSize: 24)),));
            //         });
            //     }
            //   },
            // ),
          ),
          Container(
            height: 100,
            child: Stack(
              children: [
                // Stack(
                //   children: [
                //
                //     Center(
                //       child: Image.asset('assets/pin.png', height: 240, width: 240),
                //     )
                //   ],
                // ),

                Center(
                  child: TextButton(
                    onPressed: (){
                      pickImageFromCamera();
                    },
                    onLongPress: (){
                      pickImageFromGallery();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 25),
                      child: const SizedBox(
                        height: 100,
                        child: Icon(Icons.camera_enhance_sharp,size: 100,color: Colors.grey,),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class Book{
  String title,authors,isbn,language,cover;

  Book(this.title,this.authors,this.isbn,this.language,this.cover);
}