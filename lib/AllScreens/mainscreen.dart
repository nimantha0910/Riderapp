import 'dart:async';
import 'dart:convert';
import 'dart:developer';
//import 'dart:html';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:riderapp/AllScreens/loginScreen.dart';
import 'package:riderapp/AllScreens/searchScreen.dart';
import 'package:riderapp/AllWidgets/progressDialog.dart';
import 'package:riderapp/Assistants/assistantMethods.dart';
import 'package:riderapp/Assistants/geoFireAssistant.dart';
import 'package:riderapp/DataHandler/appData.dart';
import 'package:riderapp/Models/directionDetails.dart';
import 'package:riderapp/Models/nearbyAvailableDrivers.dart';
import 'package:riderapp/configMaps.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

class MainScreen extends StatefulWidget {
  static const String idScreen = "mainScreen";
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controllerGoogleMap =
      Completer<GoogleMapController>();
  late GoogleMapController newGoogleMapController;
  var drivers = [];
  bool isAccepted = false;

  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  DirectionDetails? tripDirectionDetails;

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
  bool nearByAvailableDriversKeyLoaded = false;

  late DatabaseReference rideRequestRef;

  //late BitmapDescriptor nearByIcon; //reminder

  void initState() {
    getAllDriverDetails();
    super.initState();
    AssistantMethods.getCurrentOnlineUserInfo();
  }

  void saveRideRequest() async {
    rideRequestRef =
        FirebaseDatabase.instance.reference().child("Ride Request").push();
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

    var pickUp = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;
    late http.Response response;
    var user = [];
    var myCurrentUserData = [];
    const url = 'https://rider-app-29f66-default-rtdb.firebaseio.com/user.json';
    response = await http.get(Uri.parse(url));
    Map body = json.decode(response.body);
    body.forEach((key, value) {
      user.add(value);
    });
    for (var item in user) {
      if (_firebaseAuth.currentUser!.email == item['email']) {
        myCurrentUserData.add(item);
      }
    }
    log(myCurrentUserData.toString());
    Map pickUpLocMap = {
      "latitude": pickUp.latitude.toString(),
      "longitude": pickUp.longitude.toString(),
    };

    Map dropOffLocMap = {
      "latitude": dropOff.latitude.toString(),
      "longitude": dropOff.longitude.toString(),
    };

    Map rideinfoMap = {
      "driver_id": "waiting",
      "userDetails": myCurrentUserData,
      "payment_method": "cash",
      "pickup": pickUpLocMap,
      "dropoff": dropOffLocMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo?.name,
      "rider_phone": userCurrentInfo?.phone,
      "pickup_address": pickUp.placeName,
      "dropoff_address": dropOff.placeName,
    };

    rideRequestRef.set(rideinfoMap);
  }

  void cancelRideRequest() {
    rideRequestRef.remove();
  }

  resetApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300.0;
      rideDetailsContainerHeight = 0;
      requestRideContainerHeight = 0;
      bottomPaddingOfMap = 230.0;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
    });

    locatePosition();
  }

  void displayRequestRideConatiner() {
    setState(() {
      requestRideContainerHeight = 250.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = true;

      saveRideRequest();
    });
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

    initGeoFireListner();
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.0,
  );

  @override
  Widget build(BuildContext context) {
    //createIconMarker();
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
                GestureDetector(
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushNamedAndRemoveUntil(
                        context, loginScreen.idScreen, (route) => false);
                  },
                  child: ListTile(
                    leading: Icon(Icons.info),
                    title: Text(
                      "Sign Out",
                      style: TextStyle(fontSize: 15.0),
                    ),
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
                                        ((tripDirectionDetails != null)
                                            ? tripDirectionDetails!.distanceText
                                            : ""),
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
              isAccepted == true
                  ? Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        width: double.infinity,
                        height: 50.0,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Center(
                          child: Text(
                            'Accepted',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Positioned(
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
                              GestureDetector(
                                onTap: () {
                                  cancelRideRequest();
                                  resetApp();
                                },
                                child: Container(
                                  height: 60.0,
                                  width: 60.0,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(26.0),
                                    border: Border.all(
                                        width: 2.0, color: Colors.grey),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 26.0,
                                  ),
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

  Future getAllDriverDetails() async {
    log('message');
    try {
// Print the data of the snapshot

      late http.Response response;
      const url =
          'https://rider-app-29f66-default-rtdb.firebaseio.com/Ride Request.json';
      response = await http.get(Uri.parse(url));
      Map body = json.decode(response.body);
      body.forEach((key, value) {
        log(key.toString());
        value['key'] = key;
        drivers.add(value);
      });
      for (var item in drivers) {
        if (item['driver_id'] == 'accepting') {
          setState(() {
            isAccepted = true;
          });
        }
      }
    } catch (e) {
      log(e.toString());
    }
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
    setState(() {
      tripDirectionDetails = details!;
    });
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

  void initGeoFireListner() {
    Geofire.initialize("availableDrivers");
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 15)
        ?.listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers(key: "", latitude: 0.0, longitude: 0.0);
            nearbyAvailableDrivers.key = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeoFireAssistant.nearByAvailableDriversList
                .add(nearbyAvailableDrivers);
            if (nearByAvailableDriversKeyLoaded == true) {
              updateAvailableDriversOnMap();
            }
            break;

          case Geofire.onKeyExited:
            GeoFireAssistant.removeDriverFromList(map['key']);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers(key: "", latitude: 0.0, longitude: 0.0);
            nearbyAvailableDrivers.key = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeoFireAssistant.updateDriverNearByLocation(nearbyAvailableDrivers);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();
            break;
        }
      }

      setState(() {});
    });
  }

  void updateAvailableDriversOnMap() async {
    setState(() {
      markersSet.clear();
    });

    final Uint8List pMarkerIcon =
        await getBytesFromAsset('assets/images/car_android.png', 100);

    Set<Marker> tMakers = Set<Marker>();
    for (NearbyAvailableDrivers driver
        in GeoFireAssistant.nearByAvailableDriversList) {
      LatLng driverAvailablePosition =
          LatLng(driver.latitude, driver.longitude);

      Marker marker = Marker(
        markerId: MarkerId('driver${driver.key}'),
        position: driverAvailablePosition,
        icon: BitmapDescriptor.fromBytes(pMarkerIcon),
        rotation: AssistantMethods.createRandomNumber(360),
      );
      tMakers.add(marker);
    }
    setState(() {
      markersSet = tMakers;
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  // void createIconMarker() {
  //   if (nearByIcon == null) {
  //     ImageConfiguration imageConfiguration =
  //         createLocalImageConfiguration(context, size: Size(2, 2));
  //     BitmapDescriptor.fromAssetImage(
  //             imageConfiguration, "assets/images/car_android.png")
  //         .then((value) {
  //       nearByIcon = value;
  //     });
  //   }
  // }
}
