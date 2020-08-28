import 'package:flutter/material.dart';
import 'package:flutter_app_zoom/plugin/face_manager.dart';

class FacetecTest extends StatefulWidget {
  @override
  _FacetecTestState createState() => _FacetecTestState();
}

class _FacetecTestState extends State<FacetecTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlatButton(
                onPressed: () {
                  FaceManager.livenessCheck();
                },
                child: Text("Liveness Check")),
            FlatButton(
                onPressed: () {
                  FaceManager.enrollUser();
                },
                child: Text("Enroll User")),
            FlatButton(
                onPressed: () {
                  FaceManager.authenticateUser();
                },
                child: Text("Authenticate User")),
            FlatButton(
                onPressed: () {
                  FaceManager.photoIDMatch();
                },
                child: Text("Photo ID Match"))
          ],
        ),
      ),
    );
  }
}
