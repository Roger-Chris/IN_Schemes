class UserProfile {
  String name;
  DateTime? dob;
  String gender;
  String mobile;
  String email;
  String address;
  String state;
  String district;
  String city;
  String pinCode;
  String community; // General, OBC, EWS, SC, ST, Others
  String religion;
  String educationLevel; // School, Diploma, Undergraduate, Postgraduate, Ph.D.
  bool firstGenGraduate;
  double annualIncome;
  String employmentStatus; // Student, Farmer, Salaried, Self-employed, Business Owner, Homemaker, Unemployed, Retired, Other

  UserProfile({
    this.name = '',
    this.dob,
    this.gender = 'Female',
    this.mobile = '',
    this.email = '',
    this.address = '',
    this.state = 'Tamil Nadu',
    this.district = '',
    this.city = '',
    this.pinCode = '',
    this.community = 'General',
    this.religion = '',
    this.educationLevel = 'Undergraduate',
    this.firstGenGraduate = false,
    this.annualIncome = 0.0,
    this.employmentStatus = 'Student',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'mobile': mobile,
      'email': email,
      'address': address,
      'state': state,
      'district': district,
      'city': city,
      'pinCode': pinCode,
      'community': community,
      'religion': religion,
      'educationLevel': educationLevel,
      'firstGenGraduate': firstGenGraduate,
      'annualIncome': annualIncome,
      'employmentStatus': employmentStatus,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
      gender: json['gender'] ?? 'Female',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      state: json['state'] ?? 'Tamil Nadu',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      pinCode: json['pinCode'] ?? '',
      community: json['community'] ?? 'General',
      religion: json['religion'] ?? '',
      educationLevel: json['educationLevel'] ?? 'Undergraduate',
      firstGenGraduate: json['firstGenGraduate'] ?? false,
      annualIncome: (json['annualIncome'] ?? 0.0).toDouble(),
      employmentStatus: json['employmentStatus'] ?? 'Student',
    );
  }

  UserProfile copyWith({
    String? name,
    DateTime? dob,
    String? gender,
    String? mobile,
    String? email,
    String? address,
    String? state,
    String? district,
    String? city,
    String? pinCode,
    String? community,
    String? religion,
    String? educationLevel,
    bool? firstGenGraduate,
    double? annualIncome,
    String? employmentStatus,
  }) {
    return UserProfile(
      name: name ?? this.name,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      address: address ?? this.address,
      state: state ?? this.state,
      district: district ?? this.district,
      city: city ?? this.city,
      pinCode: pinCode ?? this.pinCode,
      community: community ?? this.community,
      religion: religion ?? this.religion,
      educationLevel: educationLevel ?? this.educationLevel,
      firstGenGraduate: firstGenGraduate ?? this.firstGenGraduate,
      annualIncome: annualIncome ?? this.annualIncome,
      employmentStatus: employmentStatus ?? this.employmentStatus,
    );
  }

  int get age {
    if (dob == null) return 25; // Default fallback age
    final now = DateTime.now();
    int age = now.year - dob!.year;
    if (now.month < dob!.month || (now.month == dob!.month && now.day < dob!.day)) {
      age--;
    }
    return age;
  }
}
