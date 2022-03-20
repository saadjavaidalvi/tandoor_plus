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
      "Lahore": ["Allama Iqbal Town","Muslim Town","Sabzazar Scheme","Awan Town","Mustafa Town","Samanabad Town","Johar Town","Model Town"]
    };
    unavailableAreas = {
      // "Lahore": ["Model Town", "Muslim Town"]
    };
    availableBlocks = {
      "Lahore": {
        "Allama Iqbal Town": [
          "Asif Block",
          "Badar Block",
          "Badar Pura",
          "Chinab Block",
          "College Block",
          "Gulshan Block",
          "Huma Block",
          "Hunza Block",
          "Ittehad Colony",
          "Jahanzeb Block",
          "Kamran Block",
          "Karim Block",
          "Kashmir Block",
          "Khyber Block",
          "Mehran Block",
          "Muslim Block",
          "Najaf Colony",
          "Nargis Block",
          "Neelam Block",
          "Nishtar Block",
          "Nizam Block",
          "Pak Block",
          "Rachna Block",
          "Ravi Block",
          "Raza Bloc",
          "Satluj Block",
          "Sikandar Block",
          "Umar Block",
          "Wahdat Colony",
          "Zeenat Block"
        ],
        "Muslim Town":[
          "A Block"	,
          "B Block"	,
          "C Block"	,
          "D Block",
          "Site Postal Colony"
        ],
        "Sabzazar Scheme":[
          "A Block",
          "B Block",
          "C Block",
          "D Block",
          "E Block",
          "F Block",
          "G Block",
          "H Block",
          "I Block",
          "J Block",
          "Jamil Town",
          "K Block",
          "L Block",
          "M Block",
          "N Block",
          "P Block",
          "Q Block",
          "Saeed Pur",
          "Shah Farid"
        ],
        "Awan Town":[
          "Ahmad Block",
          "Ali Block",
          "Jinnah Block",
          "Kausar Block",
          "Madina Block",
          "Qutab Block",
          "Rizwan Block",
          "Usman Block"
        ],
        "Mustafa Town":[
          "Abbas Block",
          "Ahmed Yar Block",
          "Education Town",
          "Hydit Ullah Block",
          "Mamdoot Block",
          "Qayyum Block",
          "Shahbaz Block"
        ],
        "Samanabad Town":[
          "Chaudary Colony",
          "Gulam Nabi Colony",
          "Moon Colony",
          "New Samanabad",
          "Rustam Park",
          "Samanabad"
        ],
        "Johar Town":[
          "Block A",
          "Block A1",
          "Block A2",
          "Block A3",
          "Block B",
          "Block B1",
          "Block B2",
          "Block B3",
          "Block C",
          "Block C1",
          "Block C2",
          "Block D",
          "Block D1",
          "Block D2",
          "Block E",
          "Block E1",
          "Block E2",
          "Block F",
          "Block F1",
          "Block F2",
          "Block G",
          "Block G1",
          "Block G2",
          "Block G3",
          "Block G4",
          "Block H",
          "Block H1",
          "Block H2",
          "Block H3",
          "Block J",
          "Block J1",
          "Block J2",
          "Block J3",
          "Block K",
          "Block L",
          "Block M",
          "Block N",
          "Block P",
          "Block Q",
          "Block R",
          "Block R1",
          "Block R2",
          "Block R3"
        ],
        "Model Town":[
          "Block A",
          "Block B",
          "Block C",
          "Block D",
          "Block E",
          "Block F",
          "Block G",
          "Block H",
          "Block K",
          "L Block",
          "M Block",
          "N Block",
          "P Block",
          "Q Block",
          "R Block",
          "S Block"
        ]
      }
    };
    unavailableBlocks = {};
  }
}
