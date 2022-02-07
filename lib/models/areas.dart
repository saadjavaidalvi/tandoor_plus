class Areas {
  List<String> availableCities;
  List<String> unavailableCities;
  Map<String, List<String>> availableAreas;
  Map<String, List<String>> unavailableAreas;
  Map<String, Map<String, List<String>>> availableBlocks;
  Map<String, Map<String, List<String>>> unavailableBlocks;

  static Areas _instance;

  static Areas get instance {
    if (_instance == null) {
      _instance = Areas._defaults();
    }
    return _instance;
  }

  Areas._defaults() {
    availableCities = ["Lahore"];
    unavailableCities = ["Islamabad", "Karachi"];
    availableAreas = {
      "Lahore": ["Allama Iqbal Town"]
    };
    unavailableAreas = {
      "Lahore": ["Model Town", "Muslim Town"]
    };
    availableBlocks = {
      "Lahore": {
        "Allama Iqbal Town": [
          "Asif Block",
          "Badar Block",
          "Chenab Block",
          "College Block",
          "Gulshan Block",
          "Huma Block",
          "Itehaad Colony"
              "Jahanzeb Block",
          "Khyber Block",
          "Kamran Block",
          "Karim Block",
          "Kashmir Block",
          "Mehran Block",
          "Muslim Block",
          "Najaf Colony",
          "Nargis Block",
          "Neelam Block",
          "Nishtar Block",
          "Nizam Block",
          "Pak Block",
          "Rachna Block",
          "Raza Block",
          "Ravi Block",
          "Sikander Block",
          "Sutlej Block",
          "Umar Block",
          "Zeenat Block",
        ]
      }
    };
    unavailableBlocks = {};
  }
}
