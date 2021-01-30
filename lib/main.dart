import 'dart:convert';
import 'package:image/image.dart' as Im;
import 'dart:io';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mongo_dart/mongo_dart.dart' show Db, GridFS;
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geeks Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: MyHomePage(title: 'Image picker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);


  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin{

  final url = [
    "mongo mongodb://cluster0203-shard-00-00.mglrb.mongodb.net:27017,cluster0203-shard-00-01.mglrb.mongodb.net:27017,cluster0203-shard-00-02.mglrb.mongodb.net:27017/mydb1?replicaSet=atlas-uk5pq7-shard-0 --ssl --authenticationDatabase admin --username dbKetki --password ketki2132",
  ];

  final picker = ImagePicker();
  File _image;
  GridFS bucket;
  AnimationController _animationController;
  Animation<Color> _colorTween;
  ImageProvider provider;
  var flag = false;

  @override
  void initState() {

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1800),
      vsync: this,
    );
    _colorTween = _animationController.drive(ColorTween(begin: Colors.green, end: Colors.deepOrange));
    _animationController.repeat();
    super.initState();
    connection();
  }

  Future getImage() async{

    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    _image = File(pickedFile.path);
    if(pickedFile!=null){
      var compressedImage;
      var _cmpressed_image;
      try {
        final tempDir = await getTemporaryDirectory();
        final path = tempDir.path;
        int rand = new Math.Random().nextInt(10000);
        Im.Image image = Im.decodeImage(_image.readAsBytesSync());
        Im.Image smallerImage = Im.copyResize(image,width:500);
        compressedImage = new File('$path/img_$rand.jpg')..writeAsBytesSync(Im.encodeJpg(image, quality: 85));

      } catch (e) {

        _cmpressed_image = await FlutterImageCompress.compressWithFile(
            _image.path,
            format: CompressFormat.jpeg,
            quality: 70
        );
      }
      setState(() {
        flag = true;
      });

      Map<String,dynamic> image = {
        "_id" : _image.path.split("/").last,
        "data": base64Encode(compressedImage)
      };
      var res = await bucket.chunks.insert(image);
      var img = await bucket.chunks.findOne({
        "_id": _image.path.split("/").last
      });
      setState(() {
        provider = MemoryImage(base64Decode(img["data"]));
        flag = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.blue,
        ),
        body: SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  provider == null ? Text('No image selected.') : Image(image: provider,),
                  SizedBox(height: 10,),
                  if(flag==true)
                    CircularProgressIndicator(valueColor: _colorTween),
                  SizedBox(height: 20,),
                  RaisedButton(
                    onPressed: getImage,
                    textColor: Colors.white,
                    padding: const EdgeInsets.all(0.0),
                    child: Container(
                      color:Colors.blue,

                      padding: const EdgeInsets.all(10.0),
                      child: const Text(
                          'Select Image',
                          style: TextStyle(fontSize: 20)
                      ),
                    ),

                  ),
                ],
              ),
            )
        )

    );
  }

  Future connection () async{
    Db _db = new Db.pool(url);
    await _db.open(secure: true);
    bucket = GridFS(_db,"image");
  }
}
