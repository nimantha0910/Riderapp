import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:riderapp/Models/address.dart';

class AppData extends ChangeNotifier {
  Address pickUpLocation = new Address(
      placeFormattedAddress: "",
      placeName: "",
      placeId: "",
      latitude: 0.0,
      longitude: 0.0);

  Address dropOffLocation = new Address(
      placeFormattedAddress: "",
      placeName: "",
      placeId: "",
      latitude: 0.0,
      longitude: 0.0);

  void updatePickUpLocationAddress(Address pickUpAddress) {
    pickUpLocation = pickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Address dropOffAddress) {
    dropOffLocation = dropOffAddress;
    notifyListeners();
  }
}
