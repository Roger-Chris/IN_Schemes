import '../models/user_profile.dart';
import '../models/scheme_model.dart';

class RecommendationResult {
  final double score; // 0.0 to 1.0
  final List<String> matchingReasons;
  final List<String> missingRequirements;
  final List<String> missingDocuments;

  RecommendationResult({
    required this.score,
    required this.matchingReasons,
    required this.missingRequirements,
    required this.missingDocuments,
  });

  int get percentage => (score * 100).round();
}

class RecommendationEngine {
  static List<MapEntry<Scheme, RecommendationResult>> getRecommendations(
    UserProfile profile,
    List<Scheme> schemes,
  ) {
    final results = <MapEntry<Scheme, RecommendationResult>>[];
    for (var scheme in schemes) {
      final res = evaluate(profile, scheme);
      results.add(MapEntry(scheme, res));
    }
    // Sort by score descending
    results.sort((a, b) => b.value.score.compareTo(a.value.score));
    return results;
  }

  static RecommendationResult evaluate(UserProfile profile, Scheme scheme) {
    double score = 1.0;
    final matchingReasons = <String>[];
    final missingRequirements = <String>[];
    final missingDocuments = <String>[];

    // Get basic stats
    final age = profile.age;
    final isTN = profile.state.toLowerCase() == 'tamil nadu';
    final isFemale = profile.gender.toLowerCase() == 'female' || profile.gender.toLowerCase() == 'transgender';
    final isSCST = profile.community.toLowerCase() == 'sc' || profile.community.toLowerCase() == 'st';
    final isSpecialCommunity = isSCST || 
        profile.community.toLowerCase() == 'obc' || 
        profile.community.toLowerCase() == 'minority' ||
        profile.community.toLowerCase() == 'ews';

    // Document checks helper: We check what documents they might miss based on profile inputs.
    // By default, we assume they have Aadhaar and PAN (or they are easy to obtain, but we flag if not filled in profile)
    // We will flag missing documents if the scheme requires them.
    for (var doc in scheme.requiredDocuments) {
      if (doc == 'Nativity Certificate (TN)' && !isTN) {
        missingDocuments.add(doc);
      } else if (doc == 'Community Certificate' && profile.community.toLowerCase() == 'general') {
        // General category usually doesn't have a community certificate, but if the scheme requires it, it's flagged
        missingDocuments.add(doc);
      } else if (doc == 'Degree/Diploma Certificate' && profile.educationLevel == 'School') {
        missingDocuments.add(doc);
      } else if (doc == 'Artisan Identity Card (DC Handicrafts)') {
        // Unless they specifically have it, flag as missing (simulate for demonstration)
        missingDocuments.add(doc);
      } else if (doc == 'DPIIT Certificate of Recognition' || doc == 'Certificate of Incorporation (Pvt Ltd / LLP / Registered Partnership)') {
        missingDocuments.add(doc);
      } else if (doc == 'Project Report / Business Plan' || doc == 'Project Report / DPR' || doc == 'Project Report') {
        // Project report is always missing initially for new entrepreneurs
        missingDocuments.add(doc);
      } else if (doc == 'Quotations for machinery/equipment' || doc == 'Price Quotation of machinery/equipment or items to be purchased') {
        missingDocuments.add(doc);
      }
    }

    switch (scheme.id) {
      case 'NEEDS':
        // State Match
        if (!isTN) {
          score = 0.0;
          missingRequirements.add('Residency: This scheme is strictly for residents of Tamil Nadu.');
        } else {
          matchingReasons.add('Location: You reside in Tamil Nadu.');
        }

        // Education Match
        if (profile.educationLevel == 'School') {
          score *= 0.2; // severe penalty
          missingRequirements.add('Education: Requires a college Degree, Diploma, ITI, or Vocational Certificate.');
        } else {
          matchingReasons.add('Education: You hold a college degree/diploma (${profile.educationLevel}).');
        }

        // First Gen Graduate Bonus
        if (profile.firstGenGraduate) {
          score = (score + 0.1).clamp(0.0, 1.0);
          matchingReasons.add('Priority: You are a First-Generation Graduate (priority selection).');
        }

        // Age limits
        // General: 21-35, Special (Women, SC/ST, BC, OBC, etc.): 21-45
        final maxAge = (isFemale || isSpecialCommunity) ? 45 : 35;
        if (age < 21 || age > maxAge) {
          score *= 0.3;
          missingRequirements.add('Age: Your age ($age) is outside the eligible range of 21-$maxAge years.');
        } else {
          matchingReasons.add('Age: Your age ($age) is within the eligible range of 21-$maxAge years.');
        }

        // Project Cost check
        // Eligible project cost: 10 Lakhs to 5 Crores
        if (profile.annualIncome > 50000000) { // arbitrary
          score *= 0.8;
        }
        matchingReasons.add('Funding: Supports project costs from ₹10 Lakhs to ₹5 Crores.');
        break;

      case 'PMEGP':
        matchingReasons.add('Age: Eligible for any citizen above 18 years (you are $age).');

        // Education checks
        // VIII standard pass required for project >10L manufacturing or >5L service.
        // Since we don't have project cost input in profile, we check if education level is high enough.
        if (profile.educationLevel == 'School') {
          score *= 0.9;
          matchingReasons.add('Education: VIII standard pass criteria applies for larger projects.');
        } else {
          matchingReasons.add('Education: You satisfy the minimum VIII standard pass requirement.');
        }

        if (profile.state.toLowerCase() == 'tamil nadu') {
          matchingReasons.add('Implementation: Supported in Tamil Nadu via DIC and KVIC offices.');
        }
        break;

      case 'STANDUP_INDIA':
        // Women or SC/ST
        final eligibleCategory = isFemale || isSCST;
        if (!eligibleCategory) {
          score = 0.0;
          missingRequirements.add('Category: Stand-Up India is reserved for Women entrepreneurs and SC/ST category individuals.');
        } else {
          if (isFemale) {
            matchingReasons.add('Gender: You match the requirement for Women entrepreneurs.');
          }
          if (isSCST) {
            matchingReasons.add('Community: You match the requirement for SC/ST category borrowers.');
          }
        }

        // Age
        if (age < 18) {
          score = 0.0;
          missingRequirements.add('Age: Must be at least 18 years old.');
        }

        matchingReasons.add('Project Type: Facilitates greenfield projects between ₹10 Lakhs and ₹1 Crore.');
        break;

      case 'MUDRA':
        matchingReasons.add('Eligibility: Open to all Indian citizens with a viable business plan.');
        matchingReasons.add('Collateral: 100% collateral-free loan up to ₹10 Lakhs.');
        // High matching base score because Mudra is very general
        score = 1.0;
        break;

      case 'WEP':
        if (!isFemale) {
          score *= 0.3;
          missingRequirements.add('Gender: This platform is specifically designed to support Women Entrepreneurs.');
        } else {
          matchingReasons.add('Gender: Designed for women-led businesses and female founders.');
        }
        matchingReasons.add('Aggregation: Provides aggregated support for mentoring, incubation, and networking.');
        break;

      case 'TREAD':
        if (!isFemale) {
          score = 0.0;
          missingRequirements.add('Gender: TREAD is exclusively for groups or individual Women seeking self-employment.');
        } else {
          matchingReasons.add('Gender: Exclusively supports women entrepreneur groups.');
        }
        matchingReasons.add('Funding structure: Government grants up to 30% of the project cost through registered NGOs.');
        break;

      case 'KALAIGNAR_KAIVINAI':
        if (!isTN) {
          score = 0.0;
          missingRequirements.add('Residency: Strictly for artisans residing in Tamil Nadu.');
        } else {
          matchingReasons.add('Location: You reside in Tamil Nadu.');
        }

        // Artisan check: if the profile lists "Artisan" or "Self-employed" as employment, or if community is special.
        // Since we removed Employment/Occupation, we check if they have general eligibility but flag Artisan Card.
        missingRequirements.add('Artisan Status: Must hold a valid Pehchan Artisan Card from the Ministry of Textiles.');
        score *= 0.5; // lower match unless they explicitly select it in filters/search
        break;

      case 'STARTUP_TN':
        if (!isTN) {
          score = 0.0;
          missingRequirements.add('Residency: Startups must be incorporated or registered in Tamil Nadu.');
        } else {
          matchingReasons.add('Location: Available for startups incorporated in Tamil Nadu.');
        }
        
        // General startup match
        missingRequirements.add('DPIIT Recognition: Requires registration and recognition from DPIIT (Govt of India).');
        score *= 0.7; // Needs DPIIT recognition
        matchingReasons.add('Innovation: Offers TANSEED grants of up to ₹15 Lakhs.');
        break;

      case 'POST_MATRIC':
        if (profile.employmentStatus.toLowerCase() != 'student') {
          score *= 0.5;
        } else {
          matchingReasons.add('Occupation: You are a Student.');
        }
        if (profile.community.toLowerCase() == 'general') {
          score *= 0.8;
          missingRequirements.add('Community: Priority is given to SC, ST, OBC and Minority community students.');
        } else {
          matchingReasons.add('Community: You belong to a priority group (${profile.community}).');
        }
        matchingReasons.add('Academic: Supports Class 11 to PhD levels.');
        break;

      case 'MERIT_MEANS':
        if (profile.employmentStatus.toLowerCase() != 'student') {
          score *= 0.4;
        }
        if (profile.annualIncome > 250000) {
          score *= 0.7;
          missingRequirements.add('Income: Requires family annual income below ₹2.5 Lakhs.');
        } else {
          matchingReasons.add('Income: Your family income is below ₹2.5 Lakhs.');
        }
        matchingReasons.add('Academic: Designed for UG & PG professional courses.');
        break;

      case 'INSPIRE':
        if (profile.employmentStatus.toLowerCase() != 'student') {
          score *= 0.3;
        }
        if (profile.age < 17 || profile.age > 22) {
          score *= 0.8;
          missingRequirements.add('Age: Designed for youth aged 17-22 years.');
        } else {
          matchingReasons.add('Age: You fit the age bracket of 17-22 years.');
        }
        matchingReasons.add('Academic: For top 1% performers in Class 12 pursuing basic sciences.');
        break;

      case 'PRAGATI':
        if (!isFemale) {
          score = 0.0;
          missingRequirements.add('Gender: Exclusively for female students.');
        } else {
          matchingReasons.add('Gender: Female candidate.');
        }
        if (profile.educationLevel != 'Undergraduate' && profile.educationLevel != 'Diploma' && profile.educationLevel != 'Postgraduate') {
          score *= 0.5;
          missingRequirements.add('Academic: Designed for Diploma, UG or PG courses.');
        } else {
          matchingReasons.add('Academic: Enrolled in eligible level (${profile.educationLevel}).');
        }
        break;

      default:
        break;
    }

    // Adjust score based on missing documents (slight penalty)
    if (score > 0.0 && missingDocuments.isNotEmpty) {
      // Scale score down slightly based on documents, but keep it high enough to recommend
      final docRatio = (scheme.requiredDocuments.length - missingDocuments.length) / scheme.requiredDocuments.length;
      score = (score * (0.8 + 0.2 * docRatio)).clamp(0.0, 1.0);
    }

    return RecommendationResult(
      score: score,
      matchingReasons: matchingReasons,
      missingRequirements: missingRequirements,
      missingDocuments: missingDocuments,
    );
  }
}
