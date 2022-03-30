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
      Book book = Book(jsonData['items'][0]['volumeInfo']['title'],jsonData['items'][0]['volumeInfo']['authors'][0],jsonData['items'][0]['volumeInfo']['industryIdentifiers'][1]['identifier'],jsonData['items'][0]['volumeInfo']['language']);
      books.add(book);
      if (kDebugMode) {
        print(book.title);
        print(books);
        print(result);
        print("booooooks");
      }
      return books;
    }else {
      if (kDebugMode) {
        print(books);
        print("buuuuuks");
      }
      return books;
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
      result += "\n\n";
    });

    // var response = await http.get(Uri.https('www.googleapis.com', '/books/v1/volumes', {
    //   'q' : 'isbn: '+result,'key': 'AIzaSyBKr4CegROMzEzkNTjtEXB_HnsNnhoXBr0'
    // }));
    // var jsonData = jsonDecode(response.body);
    //
    // book = Book(jsonData['title'], jsonData['authors'], jsonData['industryIdentifiers'], jsonData['language']);
    //
    // if (kDebugMode) {
    //   print(book);
    //   print("booooooks");
    // }
    // log("TEST: $book");

    // getAPI();
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
            child: FutureBuilder(
              future: getAPI(),
              builder: (context,AsyncSnapshot snapshot){
                if(books.isEmpty){
                  return Container(
                    height: 280,
                    child: const Center(
                      child: Text('Prend une photo'),
                    ),
                  );
                }else{
                  return ListView.builder(
                    itemCount: books.length,
                    itemBuilder: (context, i){
                      return Center(child: ListTile(title: Text(books[i].title,style: const TextStyle(fontSize: 48)),subtitle: Text(books[i].authors,style: const TextStyle(fontSize: 24)),));
                    });
                }
              },
            ),
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
  String title,authors,isbn,language;

  Book(this.title,this.authors,this.isbn,this.language);
}