//import 'dart:js';

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:riderapp/Assistants/requestAssistant.dart';
import 'package:riderapp/DataHandler/appData.dart';
import 'package:riderapp/Models/address.dart';
import 'package:riderapp/configMaps.dart';

class AssistantMethods {
  static Future<String> searchCoordinateAddress(
      Position position, context) async {
    String placeAddress = " ";
    String st1, st2, st3, st4;
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=AIzaSyC-dPEeTK3Kt1mxUiu3kgZOP2ZICbKqu1w";

    var response = await RequestAssistant.getRequest(url);

    if (response != "failed") {
      st1 = response["results"][0]["address_components"][3]["long_name"];
      st2 = response["results"][0]["address_components"][4]["long_name"];
      st3 = response["results"][0]["address_components"][5]["long_name"];
      st4 = response["results"][0]["address_components"][6]["long_name"];
      placeAddress = st1 + ", " + st2 + ", " + st3 + ", " + st4;
      log(position.latitude.toString() + position.longitude.toString());
      Address userPickUpAddress = new Address(
          placeFormattedAddress: "",
          placeName: "",
          placeId: "",
          latitude: position.latitude,
          longitude: position.longitude);
      userPickUpAddress.longitude = position.longitude;
      userPickUpAddress.latitude = position.latitude;
      userPickUpAddress.placeName = placeAddress;

      Provider.of<AppData>(context, listen: false)
          .updatePickUpLocationAddress(userPickUpAddress);
    }
    return placeAddress;
  }
}
