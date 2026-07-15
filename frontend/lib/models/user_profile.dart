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

  // Extended Profile Fields
  bool profileCompleted;
  String disability;
  bool veteran;
  String house;
  String street;
  String area;
  String village;
  String qualification;
  
  // Business fields (stored in startup_profiles mapping)
  bool existingBusiness;
  String businessStage; // Idea, Prototype, Registered, Operational, Expansion
  String businessIndustry;
  double fundingRequired;
  String registrationNumbers;

  // Metadata/OAuth fields autofilled from Google
  String googleUserId;
  bool emailVerified;
  String provider;
  DateTime? lastLoginTime;

  // Preferences
  String language;
  bool notificationsEnabled;
  String theme;

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
    
    // Default initializations for extended fields
    this.profileCompleted = false,
    this.disability = 'None',
    this.veteran = false,
    this.house = '',
    this.street = '',
    this.area = '',
    this.village = '',
    this.qualification = 'Undergraduate',
    this.existingBusiness = false,
    this.businessStage = 'Idea',
    this.businessIndustry = 'Technology',
    this.fundingRequired = 0.0,
    this.registrationNumbers = '',
    this.googleUserId = '',
    this.emailVerified = false,
    this.provider = 'google',
    this.lastLoginTime,
    this.language = 'en',
    this.notificationsEnabled = true,
    this.theme = 'light',
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
      'profileCompleted': profileCompleted,
      'disability': disability,
      'veteran': veteran,
      'house': house,
      'street': street,
      'area': area,
      'village': village,
      'qualification': qualification,
      'existingBusiness': existingBusiness,
      'businessStage': businessStage,
      'businessIndustry': businessIndustry,
      'fundingRequired': fundingRequired,
      'registrationNumbers': registrationNumbers,
      'googleUserId': googleUserId,
      'emailVerified': emailVerified,
      'provider': provider,
      'lastLoginTime': lastLoginTime?.toIso8601String(),
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'theme': theme,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
      gender: json['gender'] ?? 'Female',
      mobile: json['mobile'] ?? json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      state: json['state'] ?? 'Tamil Nadu',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      pinCode: json['pinCode'] ?? json['pin'] ?? '',
      community: json['community'] ?? 'General',
      religion: json['religion'] ?? '',
      educationLevel: json['educationLevel'] ?? 'Undergraduate',
      firstGenGraduate: json['firstGenGraduate'] ?? false,
      annualIncome: (json['annualIncome'] ?? json['annual_income'] ?? 0.0).toDouble(),
      employmentStatus: json['employmentStatus'] ?? json['employment'] ?? 'Student',
      profileCompleted: json['profileCompleted'] ?? json['profile_completed'] ?? false,
      disability: json['disability'] ?? 'None',
      veteran: json['veteran'] ?? false,
      house: json['house'] ?? '',
      street: json['street'] ?? '',
      area: json['area'] ?? '',
      village: json['village'] ?? '',
      qualification: json['qualification'] ?? 'Undergraduate',
      existingBusiness: json['existingBusiness'] ?? json['business_registered'] ?? false,
      businessStage: json['businessStage'] ?? json['business_stage'] ?? 'Idea',
      businessIndustry: json['businessIndustry'] ?? json['industry'] ?? 'Technology',
      fundingRequired: (json['fundingRequired'] ?? json['funding_required_amount'] ?? 0.0).toDouble(),
      registrationNumbers: json['registrationNumbers'] ?? json['registration_numbers'] ?? '',
      googleUserId: json['googleUserId'] ?? json['google_user_id'] ?? '',
      emailVerified: json['emailVerified'] ?? json['email_verified'] ?? false,
      provider: json['provider'] ?? 'google',
      lastLoginTime: json['lastLoginTime'] != null 
          ? DateTime.tryParse(json['lastLoginTime']) 
          : (json['last_login_time'] != null ? DateTime.tryParse(json['last_login_time']) : null),
      language: json['language'] ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] ?? json['notifications'] ?? true,
      theme: json['theme'] ?? 'light',
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
    bool? profileCompleted,
    String? disability,
    bool? veteran,
    String? house,
    String? street,
    String? area,
    String? village,
    String? qualification,
    bool? existingBusiness,
    String? businessStage,
    String? businessIndustry,
    double? fundingRequired,
    String? registrationNumbers,
    String? googleUserId,
    bool? emailVerified,
    String? provider,
    DateTime? lastLoginTime,
    String? language,
    bool? notificationsEnabled,
    String? theme,
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
      profileCompleted: profileCompleted ?? this.profileCompleted,
      disability: disability ?? this.disability,
      veteran: veteran ?? this.veteran,
      house: house ?? this.house,
      street: street ?? this.street,
      area: area ?? this.area,
      village: village ?? this.village,
      qualification: qualification ?? this.qualification,
      existingBusiness: existingBusiness ?? this.existingBusiness,
      businessStage: businessStage ?? this.businessStage,
      businessIndustry: businessIndustry ?? this.businessIndustry,
      fundingRequired: fundingRequired ?? this.fundingRequired,
      registrationNumbers: registrationNumbers ?? this.registrationNumbers,
      googleUserId: googleUserId ?? this.googleUserId,
      emailVerified: emailVerified ?? this.emailVerified,
      provider: provider ?? this.provider,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      theme: theme ?? this.theme,
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
