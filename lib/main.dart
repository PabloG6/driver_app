import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driverapp/login.page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() {
  runApp(MyApp());
}

final API_KEY = "AIzaSyAVCsEMXBEp0Ah73H8blBgm_1dSrP3Fd5I";

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.indigo,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final DocumentSnapshot driver;
  final DocumentSnapshot courier;

  MyHomePage({Key key, this.driver, this.courier}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String TRIP_STATE = "IDLE";
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  final CollectionReference driverRef = Firestore.instance.collection("rides");
  List<Marker> _markers = [];
  List<LatLng> _destinationPoints = [];
  Set<Marker> _markerSet = Set();
  Set<Polyline> _polylineSet = Set();
  GoogleMapController _mapController;
  Completer _googleMapsCompleter = new Completer();
  CollectionReference driverCollection;
  Future<Position> position;
  @override
  void initState() {
    super.initState();
    TRIP_STATE = "AT_PICKUP";

    driverCollection = Firestore.instance
        .collection("couriers")
        .document(widget.courier.documentID)
        .collection("drivers");
    _googleMapsCompleter.future.then((value) {
      _mapController = value;
    });

    Location().onLocationChanged.listen((LocationData locationData) {
      driverCollection.document(widget.driver.documentID).updateData({
        "currentLocation":
            GeoPoint(locationData.latitude, locationData.longitude)
      });
    });

    getCurrentPosition(widget.driver);
  }

  @override
  Widget build(BuildContext context) {
    GeoPoint geoPoint = widget.driver.data["currentLocation"];

    if (geoPoint == null) {
      return FutureBuilder(
          future: position,
          builder: (BuildContext context, AsyncSnapshot<Position> snapshot) {
            //Kingston Jamaica

            CameraPosition initialCameraPosition = new CameraPosition(
                target: LatLng(18.007625, -76.779333), zoom: 12, tilt: 45.0);
            if (snapshot.connectionState == ConnectionState.done) {
              print("inside connection state done");
              final Marker currentLocation = Marker(
                  markerId: MarkerId("currentLocation"),
                  position: LatLng(
                      geoPoint?.latitude ?? 0, geoPoint?.longitude ?? 0));
              _markers.add(currentLocation);

              int index = _markers.indexWhere((Marker marker) =>
                  marker.markerId.value == "currentLocation");
              LatLng currentPosition =
                  LatLng(snapshot.data.latitude, snapshot.data.longitude);
              if (index != -1) {
                _markers[index] = Marker(
                    markerId: MarkerId("currentLocation"),
                    position: currentPosition);
                _markerSet = Set<Marker>.from(_markers);
              }

              _mapController?.moveCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(target: currentPosition, zoom: 15)));
            }
            return Stack(
              children: <Widget>[
                GoogleMap(
                  markers: _markerSet,
                  polylines: _polylineSet,
                  initialCameraPosition: initialCameraPosition,
                  myLocationEnabled: true,
                  onMapCreated: (GoogleMapController mapController) {
                    int index = _markers.indexWhere((Marker marker) =>
                        marker.markerId.value == "currentLocation");
                    LatLng currentPosition =
                        LatLng(snapshot.data.latitude, snapshot.data.longitude);
                    if (index != -1) {
                      _markers[index] = Marker(
                          markerId: MarkerId("currentLocation"),
                          position: currentPosition);
                      _markerSet = Set<Marker>.from(_markers);

                    }

                    _googleMapsCompleter.complete(mapController);

                    mapController.animateCamera(CameraUpdate.newCameraPosition(
                        CameraPosition(target: currentPosition, zoom: 15)));
                  },
                ),
                Align(
                    alignment: Alignment.bottomCenter,
                    child: ButtonTheme(
                        minWidth: double.infinity,
                        child: RaisedButton(
                          child: Text("Start your Ride"),
                          onPressed: () {},
                        ))),
              ],
            );
          });
    }
    final Marker currentLocation = Marker(
        markerId: MarkerId("currentLocation"),
        position: LatLng(geoPoint?.latitude ?? 0, geoPoint?.longitude ?? 0));
    _markers.add(currentLocation);

    _markerSet = Set<Marker>.from(_markers);
    Position lastKnownLocation =
        Position(latitude: geoPoint.latitude, longitude: geoPoint.longitude);
    print("$lastKnownLocation");
    CameraPosition initialCameraPosition = CameraPosition(
        target: LatLng(geoPoint.latitude, geoPoint.longitude), zoom: 15);
    return FutureBuilder(
        future: position,
        initialData: lastKnownLocation,
        builder: (BuildContext context, AsyncSnapshot<Position> snapshot) {
          print(
              "snapshot connection state ======> ${snapshot.connectionState}");
          if (snapshot.connectionState == ConnectionState.done) {
            int index = _markers.indexWhere(
                (Marker marker) => marker.markerId.value == "currentLocation");
            LatLng currentPosition =
                LatLng(snapshot.data.latitude, snapshot.data.longitude);
            if (index != -1) {
              _markers[index] = Marker(
                  markerId: MarkerId("currentLocation"),
                  position: currentPosition);
              _markerSet = Set<Marker>.from(_markers);
            }

            _mapController.moveCamera(CameraUpdate.newCameraPosition(
                CameraPosition(target: currentPosition, zoom: 15)));
          }
          return Scaffold(
              key: scaffoldKey,
              body: Stack(
                children: <Widget>[
                  GoogleMap(
                    markers: _markerSet,
                    polylines: _polylineSet,
                    initialCameraPosition: initialCameraPosition,
                    myLocationEnabled: true,
                    mapToolbarEnabled: false,
                    onMapCreated: (GoogleMapController mapController) {
                      int index = _markers.indexWhere((Marker marker) =>
                          marker.markerId.value == "currentLocation");
                      LatLng currentPosition = LatLng(
                          snapshot.data.latitude, snapshot.data.longitude);
                      if (index != -1) {
                        _markers[index] = Marker(
                            markerId: MarkerId("currentLocation"),
                            position: currentPosition);
                        _markerSet = Set<Marker>.from(_markers);
                      }

                      _googleMapsCompleter.complete(mapController);

                      mapController.animateCamera(
                          CameraUpdate.newCameraPosition(CameraPosition(
                              target: currentPosition, zoom: 15)));
                    },
                  ),
                  Align(
                      alignment: Alignment.bottomCenter,
                      child: ButtonTheme(
                          minWidth: double.infinity,
                          child: RaisedButton(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
                                "Arrived at Destination",
                                style:
                                    Theme.of(context).textTheme.button.copyWith(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                              ),
                            ),
                            onPressed: () async {
                              switch (TRIP_STATE) {
                                case "IDLE":
                                  break;
                                case "AT_PICKUP":
                                  {
                                    await driverCollection
                                        .document(widget.driver.documentID)
                                        .updateData({"status": "at_pickup"});
                                    _polylineSet.clear();
                                    _destinationPoints.clear();

                                    GeoPoint geoPoint =
                                        widget.driver.data["startLocation"];

                                    final origin = PointLatLng(
                                        geoPoint.latitude, geoPoint.longitude);
                                    print(
                                        "[${geoPoint.latitude}, ${geoPoint.longitude}]");
                                    GeoPoint destGeoPoint =
                                        widget.driver.data["endLocation"];
                                    final destination = PointLatLng(
                                        destGeoPoint.latitude,
                                        destGeoPoint.longitude);
                                    final polylinesResult =
                                        await PolylinePoints()
                                            .getRouteBetweenCoordinates(
                                                API_KEY, origin, destination,
                                                travelMode: TravelMode.driving);
                                    polylinesResult.points
                                        .forEach((PointLatLng points) {
                                      _destinationPoints.add(LatLng(
                                          points.latitude, points.longitude));
                                    });

                                    Polyline _polyline = Polyline(
                                        polylineId: PolylineId("pickUpRoute"),
                                        color: Colors.indigo,
                                        points: _destinationPoints,
                                        width: 3);
                                    final minLatitude = destGeoPoint.latitude >
                                            geoPoint.latitude
                                        ? geoPoint.latitude
                                        : destGeoPoint.latitude;

                                    final minLongitude =
                                        destGeoPoint.longitude >
                                                geoPoint.longitude
                                            ? geoPoint.longitude
                                            : destGeoPoint.longitude;

                                    final maxLatitude = destGeoPoint.latitude >
                                            geoPoint.latitude
                                        ? destGeoPoint.latitude
                                        : geoPoint.latitude;

                                    final maxLongitude =
                                        destGeoPoint.longitude >
                                                geoPoint.longitude
                                            ? destGeoPoint.longitude
                                            : geoPoint.longitude;
                                    LatLng southwest =
                                        LatLng(minLatitude, minLongitude);
                                    LatLng northeast =
                                        LatLng(maxLatitude, maxLongitude);
                                    _mapController?.moveCamera(
                                        CameraUpdate.newLatLngBounds(
                                            LatLngBounds(
                                                southwest: southwest,
                                                northeast: northeast),
                                            120));
                                    _polylineSet.add(_polyline);
                                    TRIP_STATE = "AT_DESTINATION";
                                    setState(() {

                                    });
                                    break;
                                  }

                                case "AT_DESTINATION":
                                  {
                                    await driverCollection
                                        .document(widget.driver.documentID)
                                        .updateData(
                                            {"status": "at_destination"});
                                    _polylineSet.clear();

                                    _destinationPoints.clear();
                                    setState(() {});
                                    scaffoldKey.currentState
                                        .showSnackBar(SnackBar(
                                      content:
                                          Text("You've completed your trip!"),
                                      action: SnackBarAction(label: "OK", onPressed: () {}),
                                    ));
                                  }
                              }
                            },
                          )))
                ],
              ));
        });
  }

  Future<Position> getCurrentPosition(DocumentSnapshot driver) async {
    final currentPosition = await Geolocator().getCurrentPosition();
    _polylineSet.clear();
    _destinationPoints.clear();

    final origin =
        PointLatLng(currentPosition.latitude, currentPosition.longitude);
    GeoPoint geoPoint = driver.data["startLocation"];
    print("[${geoPoint.latitude}, ${geoPoint.longitude}]");
    final destination = PointLatLng(geoPoint.latitude, geoPoint.longitude);
    final polylinesResult = await PolylinePoints().getRouteBetweenCoordinates(
        API_KEY, origin, destination,
        travelMode: TravelMode.driving);
    polylinesResult.points.forEach((PointLatLng points) {
      _destinationPoints.add(LatLng(points.latitude, points.longitude));
    });

    Polyline _polyline = Polyline(
        polylineId: PolylineId("pickUpRoute"),
        color: Colors.indigo,
        points: _destinationPoints,
        width: 3);

    _polylineSet.add(_polyline);
    setState(() {

    });
    return currentPosition;
  }
}
