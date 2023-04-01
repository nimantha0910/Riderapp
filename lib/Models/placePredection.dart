class PlacePredictions {
  String secondary_text = "sctext";
  String main_text = "koba";
  String place_id = "plcid";

  PlacePredictions(
      {required this.secondary_text,
      required this.main_text,
      required this.place_id});

  PlacePredictions.fromJson(Map<String, dynamic> json) {
    place_id = json["place_id"];
    main_text = json["main_text"];
    secondary_text = json["secondary_text"];
  }
}