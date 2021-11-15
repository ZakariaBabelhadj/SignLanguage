import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_classification/main.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isWorking = false;
  String result = '';
  CameraController? cameraController;
  CameraImage? imgCamera;
  File? image;
  final picker = ImagePicker();
  bool _camera = false;

  initCamera() {
    _camera = true;
    imgCamera = null;
    cameraController = CameraController(cameras[0], ResolutionPreset.ultraHigh);
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraController!.startImageStream((imageFromStream) => {
              if (!isWorking)
                {isWorking = true, imgCamera = imageFromStream, runTimeApp()}
            });
      });
    });
  }

  Future pickImage() async {
    if (imgCamera != null) {
      cameraController!.stopImageStream();
    }
    image = null;
    _camera = false;
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        image = File(pickedFile.path);
      }
    });
    clasifyImage(image!);
  }

  clasifyImage(File img) async {
    var outputs = await Tflite.runModelOnImage(
        path: img.path,
        numResults: 1,
        threshold: 0.1,
        imageMean: 127.5,
        imageStd: 127.5);
    setState(() {
      result = '';
      result = outputs![0]['label'] +
          ' ' +
          (outputs[0]['confidence'] as double).toStringAsFixed(2);
    });
  }

  initFrontCamera() {
    _camera = true;
    imgCamera = null;
    cameraController = CameraController(cameras[1], ResolutionPreset.ultraHigh);
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraController!.startImageStream((imageFromStream) => {
              if (!isWorking)
                {isWorking = true, imgCamera = imageFromStream, runTimeApp()}
            });
      });
    });
  }

  runTimeApp() async {
    if (imgCamera != null) {
      var recognitions = await Tflite.runModelOnFrame(
          bytesList: imgCamera!.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          imageHeight: imgCamera!.height,
          imageWidth: imgCamera!.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 2,
          threshold: 0.1,
          asynch: true);

      result = '';

      recognitions!.forEach((element) {
        result += element['label'] +
            ' ' +
            (element['confidence'] as double).toStringAsFixed(2) +
            "\n\n";
      });

      setState(() {});

      isWorking = false;
    }
  }

  loadModel() async {
    await Tflite.loadModel(
        model: 'assets/model.tflite', labels: 'assets/labels.txt');
  }

  @override
  void initState() {
    loadModel();
    super.initState();
  }

  @override
  void dispose() async {
    await Tflite.close();
    super.dispose();
    cameraController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Testing '),
        ),
        body: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _camera
                  ? Container(
                      child: imgCamera == null
                          ? Text('')
                          : AspectRatio(
                              aspectRatio: cameraController!.value.aspectRatio,
                              child: CameraPreview(cameraController!),
                            ),
                    )
                  : Container(
                      width: double.infinity,
                      height: double.infinity,
                      margin: EdgeInsets.all(0.0),
                      child: image == null
                          ? Center(
                              child: Text(
                              'Pick A Photo From Your Gallery \n Or Go Live!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 30,
                              ),
                            ))
                          : Image.file(image!),
                    ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.black),
                    child: TextButton(
                        onPressed: () => initCamera(),
                        child: Icon(Icons.camera_alt_rounded,
                            size: 30, color: Colors.white)),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.black),
                    child: TextButton(
                        onPressed: () => pickImage(),
                        child:
                            Icon(Icons.image, size: 30, color: Colors.white)),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.black),
                    child: TextButton(
                      onPressed: () => initFrontCamera(),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 25,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
              Center(
                  child: Container(
                      margin: EdgeInsets.only(top: 55),
                      child: Text(
                        result,
                        style: TextStyle(
                            fontSize: 30.0,
                            color: Colors.white,
                            backgroundColor: Colors.black),
                      ))),
            ],
          ),
        ),
      ),
    );
  }
}
