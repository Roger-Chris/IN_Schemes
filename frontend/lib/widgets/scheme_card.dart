import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/scheme_model.dart';
import '../engine/recommendation_engine.dart';
import '../providers/app_state_provider.dart';

class SchemeCard extends StatelessWidget {
  final Scheme scheme;
  final RecommendationResult result;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onTap;
  final bool showActions;
  final bool showMatchPercentage;

  const SchemeCard({
    super.key,
    required this.scheme,
    required this.result,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onTap,
    this.showActions = true,
    this.showMatchPercentage = true,
  });

  List<String> get _otherTags {
    final List<String> list = [];

    void addSplit(String value) {
      if (value.isNotEmpty) {
        list.addAll(
          value
              .split(',')
              .map((s) => s.trim())
              .where(
                (s) =>
                    s.isNotEmpty &&
                    s.toLowerCase() != 'pending official verification',
              ),
        );
      }
    }

    addSplit(scheme.category);
    addSplit(scheme.schemeType);
    addSplit(scheme.sector);

    final Set<String> seen = {};
    final List<String> uniqueList = [];

    final sponsoringLower = scheme.sponsoringBody.toLowerCase();
    final govLevelLower = scheme.governmentLevel.toLowerCase();
    final stateLower = scheme.state.toLowerCase();

    for (final tag in list) {
      final lower = tag.toLowerCase();
      final isSubtitleTerm =
          sponsoringLower.contains(lower) ||
          govLevelLower.contains(lower) ||
          stateLower.contains(lower) ||
          lower == 'central' ||
          lower == 'state';
      if (!seen.contains(lower) && !isSubtitleTerm) {
        seen.add(lower);
        uniqueList.add(tag);
      }
    }

    return uniqueList.take(3).toList(); // limit to 3 tags to avoid overflow
  }

  String? _getLocalStateEmblem(Scheme scheme) {
    final state = scheme.state.toLowerCase().trim();
    final code = scheme.schemeCode.toLowerCase().trim();
    final name = scheme.name.toLowerCase().trim();
    final sponsor = scheme.sponsoringBody.toLowerCase().trim();
    final issuer = scheme.issuingBody.toLowerCase().trim();

    bool matchesState(String stateKey, List<String> variations) {
      for (final v in variations) {
        if (state.contains(v) ||
            name.contains(v) ||
            sponsor.contains(v) ||
            issuer.contains(v)) {
          return true;
        }
      }
      return false;
    }

    if (matchesState('tamil nadu', ['tamil', 'tn', 'tanglish']) ||
        code.startsWith('tn_') ||
        code.contains('_tn_') ||
        code.endsWith('_tn')) {
      return 'assets/images/States assets/State Emblem/Tamil Nadu.png';
    }
    if (matchesState('andhra pradesh', ['andhra', 'ap']) ||
        code.startsWith('ap_') ||
        code.contains('_ap_') ||
        code.endsWith('_ap')) {
      return 'assets/images/States assets/State Emblem/Andhra Pradesh.png';
    }
    if (matchesState('arunachal pradesh', ['arunachal', 'ar']) ||
        code.startsWith('ar_') ||
        code.contains('_ar_') ||
        code.endsWith('_ar')) {
      return 'assets/images/States assets/State Emblem/Arunachal Pradesh.png';
    }
    if (matchesState('assam', ['assam', 'as']) ||
        code.startsWith('as_') ||
        code.contains('_as_') ||
        code.endsWith('_as')) {
      return 'assets/images/States assets/State Emblem/Assam.png';
    }
    if (matchesState('bihar', ['bihar', 'br']) ||
        code.startsWith('br_') ||
        code.contains('_br_') ||
        code.endsWith('_br')) {
      return 'assets/images/States assets/State Emblem/Bihar.png';
    }
    if (matchesState('chhattisgarh', ['chhattisgarh', 'chhatisgarh', 'cg']) ||
        code.startsWith('cg_') ||
        code.contains('_cg_') ||
        code.endsWith('_cg')) {
      return 'assets/images/States assets/State Emblem/Chhatisgarh.png';
    }
    if (matchesState('goa', ['goa', 'ga']) ||
        code.startsWith('ga_') ||
        code.contains('_ga_') ||
        code.endsWith('_ga')) {
      return 'assets/images/States assets/State Emblem/Goa.png';
    }
    if (matchesState('gujarat', ['gujarat', 'gj']) ||
        code.startsWith('gj_') ||
        code.contains('_gj_') ||
        code.endsWith('_gj')) {
      return 'assets/images/States assets/State Emblem/Gujarat.png';
    }
    if (matchesState('haryana', ['haryana', 'hr']) ||
        code.startsWith('hr_') ||
        code.contains('_hr_') ||
        code.endsWith('_hr')) {
      return 'assets/images/States assets/State Emblem/Haryana.png';
    }
    if (matchesState('himachal pradesh', ['himachal', 'hp']) ||
        code.startsWith('hp_') ||
        code.contains('_hp_') ||
        code.endsWith('_hp')) {
      return 'assets/images/States assets/State Emblem/Himachal Pradesh.png';
    }
    if (matchesState('jharkhand', ['jharkhand', 'jh']) ||
        code.startsWith('jh_') ||
        code.contains('_jh_') ||
        code.endsWith('_jh')) {
      return 'assets/images/States assets/State Emblem/Jharkhand.png';
    }
    if (matchesState('karnataka', ['karnataka', 'ka']) ||
        code.startsWith('ka_') ||
        code.contains('_ka_') ||
        code.endsWith('_ka')) {
      return 'assets/images/States assets/State Emblem/Karnataka.png';
    }
    if (matchesState('kerala', ['kerala', 'kl']) ||
        code.startsWith('kl_') ||
        code.contains('_kl_') ||
        code.endsWith('_kl')) {
      return 'assets/images/States assets/State Emblem/kerala.png';
    }
    if (matchesState('madhya pradesh', ['madhya', 'mp']) ||
        code.startsWith('mp_') ||
        code.contains('_mp_') ||
        code.endsWith('_mp')) {
      return 'assets/images/States assets/State Emblem/Madhya Pradesh.png';
    }
    if (matchesState('maharashtra', ['maharashtra', 'mh']) ||
        code.startsWith('mh_') ||
        code.contains('_mh_') ||
        code.endsWith('_mh')) {
      return 'assets/images/States assets/State Emblem/Maharashtra.png';
    }
    if (matchesState('manipur', ['manipur', 'mn']) ||
        code.startsWith('mn_') ||
        code.contains('_mn_') ||
        code.endsWith('_mn')) {
      return 'assets/images/States assets/State Emblem/Manipur.png';
    }
    if (matchesState('meghalaya', ['meghalaya', 'ml', 'maghalaya']) ||
        code.startsWith('ml_') ||
        code.contains('_ml_') ||
        code.endsWith('_ml')) {
      return 'assets/images/States assets/State Emblem/Maghalaya.png';
    }
    if (matchesState('mizoram', ['mizoram', 'mz']) ||
        code.startsWith('mz_') ||
        code.contains('_mz_') ||
        code.endsWith('_mz')) {
      return 'assets/images/States assets/State Emblem/Mizoram.png';
    }
    if (matchesState('nagaland', ['nagaland', 'nl']) ||
        code.startsWith('nl_') ||
        code.contains('_nl_') ||
        code.endsWith('_nl')) {
      return 'assets/images/States assets/State Emblem/Nagaland.png';
    }
    if (matchesState('odisha', ['odisha', 'orissa', 'od']) ||
        code.startsWith('od_') ||
        code.contains('_od_') ||
        code.endsWith('_od') ||
        code.startsWith('or_') ||
        code.contains('_or_') ||
        code.endsWith('_or')) {
      return 'assets/images/States assets/State Emblem/Odisha.png';
    }
    if (matchesState('punjab', ['punjab', 'pb']) ||
        code.startsWith('pb_') ||
        code.contains('_pb_') ||
        code.endsWith('_pb')) {
      return 'assets/images/States assets/State Emblem/Punjab.png';
    }
    if (matchesState('rajasthan', ['rajasthan', 'rj']) ||
        code.startsWith('rj_') ||
        code.contains('_rj_') ||
        code.endsWith('_rj')) {
      return 'assets/images/States assets/State Emblem/Rajasthan.png';
    }
    if (matchesState('sikkim', ['sikkim', 'sk']) ||
        code.startsWith('sk_') ||
        code.contains('_sk_') ||
        code.endsWith('_sk')) {
      return 'assets/images/States assets/State Emblem/Sikkim.png';
    }
    if (matchesState('telangana', ['telangana', 'tg', 'telagana']) ||
        code.startsWith('tg_') ||
        code.contains('_tg_') ||
        code.endsWith('_tg')) {
      return 'assets/images/States assets/State Emblem/Telagana.png';
    }
    if (matchesState('tripura', ['tripura', 'tr']) ||
        code.startsWith('tr_') ||
        code.contains('_tr_') ||
        code.endsWith('_tr')) {
      return 'assets/images/States assets/State Emblem/Tripura.png';
    }
    if (matchesState('uttar pradesh', ['uttar pradesh', 'up']) ||
        code.startsWith('up_') ||
        code.contains('_up_') ||
        code.endsWith('_up')) {
      return 'assets/images/States assets/State Emblem/Uttar Pradesh.png';
    }
    if (matchesState('uttarakhand', ['uttarakhand', 'uttarkhand', 'uk', 'ua']) ||
        code.startsWith('uk_') ||
        code.contains('_uk_') ||
        code.endsWith('_uk')) {
      return 'assets/images/States assets/State Emblem/Uttarakhand.png';
    }
    if (matchesState('west bengal', ['west bengal', 'wb']) ||
        code.startsWith('wb_') ||
        code.contains('_wb_') ||
        code.endsWith('_wb')) {
      return 'assets/images/States assets/State Emblem/West Bengal.png';
    }

    return null;
  }

  Widget _buildSchemeLogo(Scheme scheme, {double size = 48}) {
    final localStateEmblem = _getLocalStateEmblem(scheme);
    
    if (localStateEmblem != null) {
      return Image.asset(
        localStateEmblem,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/Logo/Logo icon.png',
            fit: BoxFit.contain,
            width: size,
            height: size,
          );
        },
      );
    }
    
    final code = scheme.schemeCode.toUpperCase();
    String logoUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Emblem_of_India.svg/358px-Emblem_of_India.svg.png';
    
    if (code.contains('MUDRA') || code.contains('PMMY')) {
      logoUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Logo_of_the_Pradhan_Mantri_Mudra_Yojana.svg/450px-Logo_of_the_Pradhan_Mantri_Mudra_Yojana.svg.png';
    } else if (code.contains('MSME') || code.contains('CGTMSE') || code.contains('PMEGP')) {
      logoUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/MSME_logo_%28colour%29.svg/330px-MSME_logo_%28colour%29.svg.png';
    }

    return Image.network(
      logoUrl,
      fit: BoxFit.contain,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/Logo/Logo icon.png',
          fit: BoxFit.contain,
          width: size,
          height: size,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: size,
          height: size,
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, Color> _getTagColors(String tag, String category) {
    final cleanTag = tag.toLowerCase().trim();
    final cleanCat = category.toLowerCase().trim();

    if (cleanTag == cleanCat) {
      if (cleanCat.contains('farmer') ||
          cleanCat.contains('agri') ||
          cleanCat.contains('rural')) {
        return {'text': const Color(0xFF15803D), 'bg': const Color(0xFFDCFCE7)};
      } else if (cleanCat.contains('student') ||
          cleanCat.contains('edu') ||
          cleanCat.contains('scholarship')) {
        return {'text': const Color(0xFF6D28D9), 'bg': const Color(0xFFF5F3FF)};
      } else if (cleanCat.contains('business') ||
          cleanCat.contains('msme') ||
          cleanCat.contains('employment')) {
        return {'text': const Color(0xFF1E3A8A), 'bg': const Color(0xFFDBEAFE)};
      } else if (cleanCat.contains('women') ||
          cleanCat.contains('female') ||
          cleanCat.contains('girl') ||
          cleanCat.contains('child')) {
        return {'text': const Color(0xFFBE185D), 'bg': const Color(0xFFFCE7F3)};
      } else {
        return {'text': const Color(0xFF0F766E), 'bg': const Color(0xFFCCFBF1)};
      }
    }

    if (cleanTag.contains('central') ||
        cleanTag.contains('national') ||
        cleanTag.contains('india')) {
      return {'text': const Color(0xFFC2410C), 'bg': const Color(0xFFFFEDD5)};
    } else if (cleanTag.contains('state') ||
        cleanTag.contains('tamil') ||
        cleanTag.contains('tn')) {
      return {'text': const Color(0xFF7C3AED), 'bg': const Color(0xFFF3E8FF)};
    } else if (cleanTag.contains('loan') || cleanTag.contains('credit')) {
      return {'text': const Color(0xFFB91C1C), 'bg': const Color(0xFFFEE2E2)};
    } else if (cleanTag.contains('subsidy') || cleanTag.contains('grant')) {
      return {'text': const Color(0xFF047857), 'bg': const Color(0xFFD1FAE5)};
    } else if (cleanTag.contains('msme')) {
      return {'text': const Color(0xFF15803D), 'bg': const Color(0xFFE8F5E9)};
    }

    final hash = cleanTag.hashCode;
    final index = hash.abs() % 4;
    if (index == 0) {
      return {'text': const Color(0xFF0369A1), 'bg': const Color(0xFFE0F2FE)};
    } else if (index == 1) {
      return {'text': const Color(0xFF0F766E), 'bg': const Color(0xFFE6FFFA)};
    } else if (index == 2) {
      return {'text': const Color(0xFF6D28D9), 'bg': const Color(0xFFF5F3FF)};
    } else {
      return {'text': const Color(0xFFB45309), 'bg': const Color(0xFFFEF3C7)};
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = List<String>.from(_otherTags)
      ..sort((a, b) => a.length.compareTo(b.length));
    final provider = Provider.of<AppProvider>(context);



    final department = scheme.sponsoringBody.isNotEmpty
        ? scheme.sponsoringBody
        : scheme.issuingBody;
    final level = scheme.state.isNotEmpty && scheme.state != 'All India'
        ? scheme.state
        : scheme.governmentLevel;
    final subtitleText = [
      if (department.isNotEmpty) department,
      if (level.isNotEmpty) level,
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Circular Logo Container (64x64)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  padding: _getLocalStateEmblem(scheme) != null ? EdgeInsets.zero : const EdgeInsets.all(8),
                  child: ClipOval(
                    child: _buildSchemeLogo(
                      scheme,
                      size: 64,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Middle Content Block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Match Badge Pill & Title block
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              scheme.name,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showMatchPercentage) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${RecommendationEngine.evaluate(provider.profile, scheme).percentage}% Match",
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF2E7D32),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitleText.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitleText,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),

                      // Tags Row
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: tags.map((tag) {
                          final colors = _getTagColors(tag, scheme.category);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors['bg'],
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: colors['text'],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Far Right Actions Column
                if (showActions) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onBookmarkToggle,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: const Color(0xFF2563EB),
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sharing "${scheme.name}"...'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.share_outlined,
                            color: Color(0xFF2563EB),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
