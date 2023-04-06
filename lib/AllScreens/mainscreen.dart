import 'dart:async';
import 'dart:developer';
//import 'dart:html';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:riderapp/AllScreens/searchScreen.dart';
import 'package:riderapp/AllWidgets/progressDialog.dart';
import 'package:riderapp/Assistants/assistantMethods.dart';
import 'package:riderapp/DataHandler/appData.dart';
import 'package:riderapp/Models/directionDetails.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen = "mainScreen";
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controllerGoogleMap =
      Completer<GoogleMapController>();
  late GoogleMapController newGoogleMapController;

  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  //DirectionDetails tripDirectionDetails;

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};

  late Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingOfMap = 0;

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;
  double requestRideContainerHeight = 0;
  double searchContainerHeight = 300.0;

  bool drawerOpen = true;

  resetApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 230.0;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
    });

    locatePosition();
  }

  void displayRequestRideConatiner() {
    requestRideContainerHeight = 250.0;
    rideDetailsContainerHeight = 0;
    bottomPaddingOfMap = 230.0;
    drawerOpen = true;
  }

  void displayRideDetailsContainer() async {
    await getPlaceDirecton();

    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 240.0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = false;
    });
  }

  void locatePosition() async {
    log('satarted calling the function');
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      currentPosition = position;
      LatLng latLatPosition = LatLng(position.latitude, position.longitude);
      CameraPosition cameraPosition =
          new CameraPosition(target: latLatPosition, zoom: 14);
      newGoogleMapController
          .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
      log('running ');

      String address =
          await AssistantMethods.searchCoordinateAddress(position, context);
      print("This is your address : " + address);
      log('address');
      log(address);
    } catch (e) {
      return Future.error(e);
    }
    // LocationPermission permission = await Geolocator.checkPermission();
    // if (permission == LocationPermission.denied) {
    //   permission = await Geolocator.requestPermission();
    //   if (permission == LocationPermission.denied) {
    //     return Future.error("Location permission are denied");
    //   }
    // }
    // if (permission == LocationPermission.deniedForever) {
    //   return Future.error(
    //       "Location permission are permanently denied, we cant request");
    // }
    // return await Geolocator.getCurrentPosition();
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.0,
  );

  @override
  Widget build(BuildContext context) {
    // CameraPosition _kGooglePlex = const CameraPosition(
    //   target: LatLng(37.42796133580664, -122.085749655962),
    //   zoom: 14.0,
    // );
    return Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: Text("Main Screen"),
        ),
        drawer: Container(
          color: Colors.white,
          width: 255.0,
          child: Drawer(
            child: ListView(
              children: [
                Container(
                  height: 165.0,
                  child: DrawerHeader(
                    decoration: BoxDecoration(color: Colors.white),
                    child: Row(children: [
                      Image.asset(
                        "assets/images/user_icon.png",
                        height: 65.0,
                        width: 65.0,
                      ),
                      SizedBox(
                        width: 16.0,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Profile Name",
                            style: TextStyle(
                                fontSize: 16.0, fontFamily: "Brand Bold"),
                          ),
                          SizedBox(
                            height: 6.0,
                          ),
                          Text("Visit Profile"),
                        ],
                      )
                    ]),
                  ),
                ),

                SizedBox(
                  height: 12.0,
                ),
                //Drawer body  controllers
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text(
                    "History",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text(
                    "Visit Profile",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.info),
                  title: Text(
                    "About",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Container(
          child: Stack(
            children: [
              GoogleMap(
                padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
                mapType: MapType.normal,
                myLocationButtonEnabled: true,
                initialCameraPosition: _kGooglePlex,
                myLocationEnabled: true,
                zoomGesturesEnabled: true,
                zoomControlsEnabled: true,
                polylines: polylineSet,
                markers: markersSet,
                circles: circlesSet,
                onMapCreated: (GoogleMapController controller) {
                  _controllerGoogleMap.complete(controller);

                  setState(() {
                    bottomPaddingOfMap = 300.0;
                    newGoogleMapController = controller;
                  });

                  locatePosition();
                },
              ),

              //Hambergun Button for drawer
              Positioned(
                top: 38.0,
                left: 22.0,
                child: GestureDetector(
                  onTap: () {
                    if (drawerOpen) {
                      scaffoldKey.currentState?.openDrawer();
                    } else {
                      resetApp();
                    }
                  },
                  // child: GestureDetector(
                  //   onTap: () {
                  //     Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //             builder: (context) => SearchScreen()));
                  //   },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 6.0,
                          spreadRadius: 0.5,
                          offset: Offset(
                            0.7,
                            0.7,
                          ),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        (drawerOpen) ? Icons.menu : Icons.close,
                        color: Colors.black,
                      ),
                      radius: 20.0,
                    ),
                  ),
                ),
              ),

              Positioned(
                  left: 0.0,
                  right: 0.0,
                  bottom: 0.0,
                  child: AnimatedSize(
                    vsync: this,
                    curve: Curves.bounceIn,
                    duration: new Duration(milliseconds: 160),
                    child: Container(
                      height: searchContainerHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18.0),
                            topRight: Radius.circular(18.0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: 16.0,
                            spreadRadius: 0.5,
                            offset: Offset(0.7, 0.7),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 6.0,
                            ),
                            Text(
                              "Hi there",
                              style: TextStyle(fontSize: 12.0),
                            ),
                            Text(
                              "Where to?",
                              style: TextStyle(
                                  fontSize: 20.0, fontFamily: "Brand Bold"),
                            ),
                            SizedBox(
                              height: 20.0,
                            ),
                            GestureDetector(
                              onTap: () async {
                                var res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SearchScreen()));

                                if (res == "obtainDirection") {
                                  displayRideDetailsContainer();
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(5.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 16.0,
                                      spreadRadius: 0.5,
                                      offset: Offset(0.7, 0.7),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.search,
                                        color: Colors.blueAccent,
                                      ),
                                      SizedBox(
                                        width: 10.0,
                                      ),
                                      Text("Search Drop Off"),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 24.0,
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.home,
                                  color: Colors.grey,
                                ),
                                SizedBox(
                                  width: 12.0,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Text(Provider.of<AppData>(context)
                                    //             .pickUpLocation !=
                                    //         null
                                    //     ? Provider.of<AppData>(context)
                                    //         .pickUpLocation
                                    //         .placeName
                                    //     : "Add Home"),
                                    Text(Provider.of<AppData>(context)
                                        .pickUpLocation
                                        .placeName),
                                    // Text(
                                    //   Provider.of<AppData>(context)
                                    //       .pickUpLocation
                                    //       .placeName,
                                    //   style: TextStyle(color: Colors.red),
                                    // ),
                                    SizedBox(
                                      height: 4.0,
                                    ),
                                    Text(
                                      "Your Living Home Address",
                                      style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12.0),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            SizedBox(
                              height: 16.0,
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.work,
                                  color: Colors.grey,
                                ),
                                SizedBox(
                                  width: 12.0,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Add Work"),
                                    SizedBox(
                                      height: 4.0,
                                    ),
                                    Text(
                                      "Your Office Home Address",
                                      style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12.0),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),

              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: AnimatedSize(
                  vsync: this,
                  curve: Curves.bounceIn,
                  duration: new Duration(milliseconds: 160),
                  child: Container(
                    height: rideDetailsContainerHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 16.0,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 17.0),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            color: Colors.tealAccent[100],
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                children: [
                                  Image.asset(
                                    "assets/images/taxi.png",
                                    height: 70.0,
                                    width: 80.0,
                                  ),
                                  SizedBox(
                                    width: 16.0,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Car",
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontFamily: "Brand Bold",
                                        ),
                                      ),
                                      Text(
                                        "distance",
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              children: [
                                Icon(
                                  FontAwesomeIcons.moneyCheckAlt,
                                  size: 18.0,
                                  color: Colors.black54,
                                ),
                                SizedBox(
                                  width: 16.0,
                                ),
                                Text("Cash"),
                                SizedBox(
                                  width: 16.0,
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.black54,
                                  size: 16.0,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 24.0,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.blue,
                                  minimumSize: const Size(88, 36),
                                  padding: const EdgeInsets.all(17.0),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(50)),
                                  ),
                                ),
                                onPressed: () {
                                  displayRequestRideConatiner();
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Request",
                                      style: TextStyle(
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    Icon(
                                      FontAwesomeIcons.taxi,
                                      color: Colors.white,
                                      size: 26.0,
                                    ),
                                  ],
                                )),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        spreadRadius: 0.5,
                        blurRadius: 16.0,
                        color: Colors.black54,
                        offset: Offset(0.7, 0.7),
                      ),
                    ],
                  ),
                  height: requestRideContainerHeight,
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 12.0,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ColorizeAnimatedTextKit(
                            onTap: () {
                              print("Tap Event");
                            },

                            text: [
                              "Requesting a Car Park...",
                              "Please Wait...",
                              "Finding a Car Park...",
                            ],
                            textStyle: TextStyle(
                                fontSize: 40.0, fontFamily: "Signatra"),
                            colors: [
                              Colors.green,
                              Colors.purple,
                              Colors.pink,
                              Colors.blue,
                              Colors.yellow,
                              Colors.red,
                            ],
                            textAlign: TextAlign.center,
                            //alignment: AlignmentDirectional.topStart
                          ),
                        ),
                        SizedBox(
                          height: 22.0,
                        ),
                        Container(
                          height: 60.0,
                          width: 60.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26.0),
                            border: Border.all(width: 2.0, color: Colors.grey),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 26.0,
                          ),
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        Container(
                          width: double.infinity,
                          child: Text(
                            "Cancel Search",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ));
  }

  Future<void> getPlaceDirecton() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;

    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickUpLatLng = LatLng(initialPos.latitude, initialPos.longitude);
    var dropOffLatLng = LatLng(finalPos.latitude, finalPos.longitude);

    showDialog(
        context: context,
        builder: (BuildContext context) => progressDialog(
              message: "Please wait...",
            ));
    Navigator.pop(context);
    log('details');
    var details = await AssistantMethods.obtainPlaceDirectionDetails(
        pickUpLatLng, dropOffLatLng);
    //setState(() {
    //tripDirectionDetails = details!;
    //});
    log('details');
    log(details.toString());

    print("This is encoded points ::");
    print(details?.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodePolyLinePointsResults =
        polylinePoints.decodePolyline(details!.encodedPoints);

    pLineCoordinates.clear();

    if (decodePolyLinePointsResults.isNotEmpty) {
      decodePolyLinePointsResults.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.black,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow:
          InfoWindow(title: initialPos.placeName, snippet: "my location"),
      position: pickUpLatLng,
      markerId: MarkerId("pickUpId"),
    );

    Marker dropOffLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow:
          InfoWindow(title: finalPos.placeName, snippet: "DropOff location"),
      position: dropOffLatLng,
      markerId: MarkerId("dropOffId"),
    );

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpLocCircle = Circle(
      fillColor: Colors.blueAccent,
      center: pickUpLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.blueAccent,
      circleId: CircleId("pickUpId"),
    );

    Circle dropOffLocCircle = Circle(
      fillColor: Colors.deepPurple,
      center: dropOffLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.deepPurple,
      circleId: CircleId("dropOffId"),
    );

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }
}
