
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  var _recognition =[];
  File? _image;
  String _filename = '';

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadModel();
  }

  closerModel()async{
    await Tflite.close();
  }

  @override
  void dispose(){
    super.dispose();
    closerModel();
  }

  Future _pickImage(ImageSource source) async {
    try {
      final take = await ImagePicker()
          .pickImage(source: source, maxHeight: 720, maxWidth: 480);
      if (take == null) return;
      File? image = File(take.path);
      // setState(() {
      //   Navigator.of(context).pop();
      //   // _isLoading = true;
      // });
      
      // await Future.delayed(const Duration(seconds: 1));
      var prediction =  await _classifyImage(image);
      // setState(() {
        // _confirmed = true;
        // _section = 3;
      // });
      // await Future.delayed(const Duration(seconds: 1));
      setState(() {
        // _isLoading = false;
        // _confirmed = false;
        _recognition = prediction;
        _image = image;
  
      });
    } on PlatformException catch (e) {
      print(e);
      Navigator.of(context).pop();
    }
  }

  Future loadModel() async{
     await Tflite.loadModel(
        model: "assets/model/model.tflite",
        labels: "assets/model/label.txt",
        numThreads: 1, // defaults to 1
        isAsset: true, // defaults to true, set to false to load resources outside assets
        useGpuDelegate: false // defaults to false, set to true to use GPU delegate
      );
  }

  Future<File?> _cropImage({required File imageFile}) async {
    CroppedFile? croppedImage =
        await ImageCropper().cropImage(sourcePath: imageFile.path);
    if (croppedImage == null) return null;
    return File(croppedImage.path);
  }

  Future _classifyImage(File file) async{
    List<int> IMAGE_SIZE = [224, 224];
    var image = img.decodeImage(file.readAsBytesSync());
    // image = img.copyRotate(image!, -90);
    image = img.flipVertical(image!);
    // resize image
    var reduced = img.copyResize(image,
        width: IMAGE_SIZE[0],
        height: IMAGE_SIZE[1],
        interpolation: img.Interpolation.nearest); // resiize]

      final jpg = img.encodeJpg(reduced);
      File preprocessed = file.copySync("${file.path}(labeld).jpg");
      preprocessed.writeAsBytesSync(jpg);
      // final preprocessed = File('out/thumbnail-test.png')
            //       ..writeAsBytesSync(img.encodePng(reduced));
      var recognitions = await Tflite.runModelOnImage(
      path: preprocessed.path,   // required
      //imageMean: 0.0,   // defaults to 117.0
      //imageStd: 255.0,  // defaults to 1.0
      numResults: 1,    // defaults to 5
      threshold: 0.2,   // defaults to 0.1
      asynch: true      // defaults to true
    );
    print(recognitions);
    return recognitions;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            (_recognition.isEmpty)? const Text('Select an image of abaca') :  SizedBox(
              width: 300,
              height: 300,
              child:(_image==null)?const  SizedBox() : Image.file(_image!, fit: BoxFit.cover,),
            ),
             
             (_recognition.isEmpty)? const SizedBox() :Text(
              '$_recognition[0].',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ()=>{
          _pickImage(ImageSource.gallery)
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
