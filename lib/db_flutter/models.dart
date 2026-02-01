import 'package:intl/intl.dart';

class Customer {
  int id;
  String ssn;
  String fname;
  String lname;
  String? birthDate;
  String? sex;
  String? telHome;
  String? telMobile;
  String? address;
  String? town;
  String? postalCode;
  String? status;
  String? org;
  String? occupation;
  String? hobbies;
  String? referer;
  String? glassesNum;
  String? lensesNum;
  String? mailing;
  String? notes;

  Customer({
    required this.id,
    required this.ssn,
    required this.fname,
    required this.lname,
    this.birthDate,
    this.sex,
    this.telHome,
    this.telMobile,
    this.address,
    this.town,
    this.postalCode,
    this.status,
    this.org,
    this.occupation,
    this.hobbies,
    this.referer,
    this.glassesNum,
    this.lensesNum,
    this.mailing,
    this.notes,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      ssn: map['ssn'].toString(),
      fname: map['fname'],
      lname: map['lname'],
      birthDate: map['birth_date'],
      sex: map['sex'],
      telHome: map['tel_home'],
      telMobile: map['tel_mobile'],
      address: map['address'],
      town: map['town'],
      postalCode: map['postal_code'],
      status: map['status'],
      org: map['org'],
      occupation: map['occupation'],
      hobbies: map['hobbies'],
      referer: map['referer'],
      glassesNum: map['glasses_num']?.toString(),
      lensesNum: map['lenses_num']?.toString(),
      mailing: map['mailing'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ssn': ssn,
      'fname': fname,
      'lname': lname,
      'birth_date': birthDate,
      'sex': sex,
      'tel_home': telHome,
      'tel_mobile': telMobile,
      'address': address,
      'town': town,
      'postal_code': postalCode,
      'status': status,
      'org': org,
      'occupation': occupation,
      'hobbies': hobbies,
      'referer': referer,
      'glasses_num': glassesNum,
      'lenses_num': lensesNum,
      'mailing': mailing,
      'notes': notes,
    };
  }
}

class GlassesTest {
  int id;
  int customerId; // Foreign key -> customers,id

  DateTime examDate; // When the test was performed
  String? examiner; // Who performed the glasses test

  // --- Right Eye (OD) values ---
  String? rFv;
  String? rSphere;
  String? rCylinder;
  String? rAxis;
  String? rPrism;
  String? rBase;
  String? rVa;
  String? bothVa;
  String? rAddRead;
  String? rAddInt;
  String? rAddBif;
  String? rAddMul;
  String? rHigh;
  String? rPd;
  String? sumPd;
  String? nearPd;
  // --- Left Eye (OS) values ---
  String? lFv;
  String? lSphere;
  String? lCylinder;
  String? lAxis;
  String? lPrism;
  String? lBase;
  String? lVa;
  String? lAddRead; // Presbyopia addition
  String? lAddInt;
  String? lAddBif;
  String? lAddMul;
  String? lHigh;
  String? lPd;

  // --- Symptoms / Notes ---
  String? dominantEye;
  String? rIop;
  String? lIop;
  String? glassesRole;
  String? lensesMaterial;
  String? lensesDiameter1;
  String? lensesDiameter2;
  String? lensesDiameterDecentrationHorizontal;
  String? lensesDiameterDecentrationVertical;
  String? segmentDiameter;
  String? lensesManufacturer;
  String? lensesColor;
  String? lensesCoated;
  String? catalogNum;
  String? frameManufacturer;
  String? frameSupplier;
  String? frameModel;
  String? frameSize;
  String? frameBarLength;
  String? frameColor;
  String? diagnosis;
  String? notes;

  GlassesTest({
    required this.id,
    required this.customerId,
    required this.examDate,
    this.examiner,
    this.rFv,
    this.rSphere,
    this.rCylinder,
    this.rAxis,
    this.rPrism,
    this.rBase,
    this.rVa,
    this.bothVa,
    this.rAddRead,
    this.rAddInt,
    this.rAddBif,
    this.rAddMul,
    this.rHigh,
    this.rPd,
    this.sumPd,
    this.nearPd,
    this.lFv,
    this.lSphere,
    this.lCylinder,
    this.lAxis,
    this.lPrism,
    this.lBase,
    this.lVa,
    this.lAddRead,
    this.lAddInt,
    this.lAddBif,
    this.lAddMul,
    this.lHigh,
    this.lPd,
    this.dominantEye,
    this.rIop,
    this.lIop,
    this.glassesRole,
    this.lensesMaterial,
    this.lensesDiameter1,
    this.lensesDiameter2,
    this.lensesDiameterDecentrationHorizontal,
    this.lensesDiameterDecentrationVertical,
    this.segmentDiameter,
    this.lensesManufacturer,
    this.lensesColor,
    this.lensesCoated,
    this.catalogNum,
    this.frameManufacturer,
    this.frameSupplier,
    this.frameModel,
    this.frameSize,
    this.frameBarLength,
    this.frameColor,
    this.diagnosis,
    this.notes,
  });

  factory GlassesTest.fromMap(Map<String, dynamic> map) {
    return GlassesTest(
      id: int.tryParse(map['id'].toString()) ?? -1,
      customerId: int.tryParse(map['customer_id'].toString()) ?? -1,
      examDate: DateFormat('yyyy-MM-dd').parse(map['exam_date']),
      examiner: map['examiner']?.toString(),
      rFv: map['r_fv']?.toString(),
      rSphere: map['r_sphere']?.toString(),
      rCylinder: map['r_cylinder']?.toString(),
      rAxis: map['r_axis']?.toString(),
      rPrism: map['r_prism']?.toString(),
      rBase: map['r_base']?.toString(),
      rVa: map['r_va']?.toString(),
      bothVa: map['both_va']?.toString(),
      rAddRead: map['r_add_read']?.toString(),
      rAddInt: map['r_add_int']?.toString(),
      rAddBif: map['r_add_bif']?.toString(),
      rAddMul: map['r_add_mul']?.toString(),
      rHigh: map['r_high']?.toString(),
      rPd: map['r_pd']?.toString(),
      sumPd: map['sum_pd']?.toString(),
      nearPd: map['near_pd']?.toString(),
      lFv: map['l_fv']?.toString(),
      lSphere: map['l_sphere']?.toString(),
      lCylinder: map['l_cylinder']?.toString(),
      lAxis: map['l_axis']?.toString(),
      lPrism: map['l_prism']?.toString(),
      lBase: map['l_base']?.toString(),
      lVa: map['l_va']?.toString(),
      lAddRead: map['l_add_read']?.toString(),
      lAddInt: map['l_add_int']?.toString(),
      lAddBif: map['l_add_bif']?.toString(),
      lAddMul: map['l_add_mul']?.toString(),
      lHigh: map['l_high']?.toString(),
      lPd: map['l_pd']?.toString(),
      dominantEye: map['dominant_eye']?.toString(),
      rIop: map['r_iop']?.toString(),
      lIop: map['l_iop']?.toString(),
      glassesRole: map['glasses_role']?.toString(),
      lensesMaterial: map['lenses_material']?.toString(),
      lensesDiameter1: map['lenses_diameter_1']?.toString(),
      lensesDiameter2: map['lenses_diameter_2']?.toString(),
      lensesDiameterDecentrationHorizontal:
          map['lenses_diameter_decentration_horizontal']?.toString(),
      lensesDiameterDecentrationVertical:
          map['lenses_diameter_decentration_vertical']?.toString(),
      segmentDiameter: map['segment_diameter']?.toString(),
      lensesManufacturer: map['lenses_manufacturer']?.toString(),
      lensesColor: map['lenses_color']?.toString(),
      lensesCoated: map['lenses_coated']?.toString(),
      catalogNum: map['catalog_num']?.toString(),
      frameManufacturer: map['frame_manufacturer']?.toString(),
      frameSupplier: map['frame_supplier']?.toString(),
      frameModel: map['frame_model']?.toString(),
      frameSize: map['frame_size']?.toString(),
      frameBarLength: map['frame_bar_length']?.toString(),
      frameColor: map['frame_color']?.toString(),
      diagnosis: map['diagnosis']?.toString(),
      notes: map['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'exam_date': DateFormat('yyyy-MM-dd').format(examDate),
      'examiner': examiner,
      'r_fv': rFv,
      'r_sphere': rSphere,
      'r_cylinder': rCylinder,
      'r_axis': rAxis,
      'r_prism': rPrism,
      'r_base': rBase,
      'r_va': rVa,
      'both_va': bothVa,
      'r_add_read': rAddRead,
      'r_add_int': rAddInt,
      'r_add_bif': rAddBif,
      'r_add_mul': rAddMul,
      'r_high': rHigh,
      'r_pd': rPd,
      'sum_pd': sumPd,
      'near_pd': nearPd,
      'l_fv': lFv,
      'l_sphere': lSphere,
      'l_cylinder': lCylinder,
      'l_axis': lAxis,
      'l_prism': lPrism,
      'l_base': lBase,
      'l_va': lVa,
      'l_add_read': lAddRead,
      'l_add_int': lAddInt,
      'l_add_bif': lAddBif,
      'l_add_mul': lAddMul,
      'l_high': lHigh,
      'l_pd': lPd,
      'dominant_eye': dominantEye,
      'r_iop': rIop,
      'l_iop': lIop,
      'glasses_role': glassesRole,
      'lenses_material': lensesMaterial,
      'lenses_diameter_1': lensesDiameter1,
      'lenses_diameter_2': lensesDiameter2,
      'lenses_diameter_decentration_horizontal':
          lensesDiameterDecentrationHorizontal,
      'lenses_diameter_decentration_vertical':
          lensesDiameterDecentrationVertical,
      'segment_diameter': segmentDiameter,
      'lenses_manufacturer': lensesManufacturer,
      'lenses_color': lensesColor,
      'lenses_coated': lensesCoated,
      'catalog_num': catalogNum,
      'frame_manufacturer': frameManufacturer,
      'frame_supplier': frameSupplier,
      'frame_model': frameModel,
      'frame_size': frameSize,
      'frame_bar_length': frameBarLength,
      'frame_color': frameColor,
      'diagnosis': diagnosis,
      'notes': notes,
    };
  }
}

class ContactLensesTest {
  int id;
  int customerId; // AUTOINCREMENT PK
  DateTime
  examDate; // ISO date string // When FETCHED from DB, it is a String here in the ContactLensesTest object!
  String? examiner;

  // # ===== Keratometry =====
  String? rRH;
  String? rRV;
  String? rAver; // avg of (r_rH and r_rV)
  String? rKCyl; // elha nos7a, mnjebha b3den
  String? rAxH; // independent of cylinder
  String? rRT;
  String? rRN;
  String? rRI;
  String? rRS;
  String? lRH;
  String? lRV;
  String? lAver; // avg of (l_rH and l_rV)
  String? lKCyl;
  String? lAxH; // independent of cylinder
  String? lRT;
  String? lRN;
  String? lRI;
  String? lRS;

  // ===== Contact Lens Prescription (Right) =====
  String? rLensType;
  String? rManufacturer;
  String? rBrand;
  String? rDiameter;
  String? rBaseCurveNumerator;
  String? rBaseCurveDenominator;
  String? rLensSph;
  String? rLensCyl;
  String? rLensAxis;
  String? rMaterial;
  String? rTint;
  String? rLensVaNumerator;
  String? rLensVaDenominator;

  // ===== Contact Lens Prescription (Left) =====
  String? lLensType;
  String? lManufacturer;
  String? lBrand;
  String? lDiameter;
  String? lBaseCurveNumerator;
  String? lBaseCurveDenominator;
  String? lLensSph;
  String? lLensCyl;
  String? lLensAxis;
  String? lMaterial;
  String? lTint;
  String? lLensVaNumerator;
  String? lLensVaDenominator;

  String? notes;

  ContactLensesTest({
    required this.id,
    required this.customerId,
    required this.examDate,
    this.examiner,
    this.rRH,
    this.rRV,
    this.rAver,
    this.rKCyl,
    this.rAxH,
    this.rRT,
    this.rRN,
    this.rRI,
    this.rRS,
    this.lRH,
    this.lRV,
    this.lAver,
    this.lKCyl,
    this.lAxH,
    this.lRT,
    this.lRN,
    this.lRI,
    this.lRS,
    this.rLensType,
    this.rManufacturer,
    this.rBrand,
    this.rDiameter,
    this.rBaseCurveNumerator,
    this.rBaseCurveDenominator,
    this.rLensSph,
    this.rLensCyl,
    this.rLensAxis,
    this.rMaterial,
    this.rTint,
    this.rLensVaNumerator,
    this.rLensVaDenominator,
    this.lLensType,
    this.lManufacturer,
    this.lBrand,
    this.lDiameter,
    this.lBaseCurveNumerator,
    this.lBaseCurveDenominator,
    this.lLensSph,
    this.lLensCyl,
    this.lLensAxis,
    this.lMaterial,
    this.lTint,
    this.lLensVaNumerator,
    this.lLensVaDenominator,
    this.notes,
  });

  factory ContactLensesTest.fromMap(Map<String, dynamic> map) {
    /*
    print(map.toString());
    map.forEach((key, value) {
      print('$key: $value ${value.runtimeType}');
    });
    */
    return ContactLensesTest(
      id: int.tryParse(map['id'].toString()) ?? -1,
      customerId: int.tryParse(map['customer_id'].toString()) ?? -1,
      examDate: DateFormat('yyyy-MM-dd').parse(map['exam_date']),
      examiner: map['examiner']?.toString(),
      rRH: map['r_rH']?.toString(),
      rRV: map['r_rV']?.toString(),
      rAver: map['r_aver']?.toString(),
      rKCyl: map['r_k_cyl']?.toString(),
      rAxH: map['r_axH']?.toString(),
      rRT: map['r_rT']?.toString(),
      rRN: map['r_rN']?.toString(),
      rRI: map['r_rI']?.toString(),
      rRS: map['r_rS']?.toString(),
      lRH: map['l_rH']?.toString(),
      lRV: map['l_rV']?.toString(),
      lAver: map['l_aver']?.toString(),
      lKCyl: map['l_k_cyl']?.toString(),
      lAxH: map['l_axH']?.toString(),
      lRT: map['l_rT']?.toString(),
      lRN: map['l_rN']?.toString(),
      lRI: map['l_rI']?.toString(),
      lRS: map['l_rS']?.toString(),
      rLensType: map['r_lens_type']?.toString(),
      rManufacturer: map['r_manufacturer']?.toString(),
      rBrand: map['r_brand']?.toString(),
      rDiameter: map['r_diameter']?.toString(),
      rBaseCurveNumerator: map['r_base_curve_numerator']?.toString(),
      rBaseCurveDenominator: map['r_base_curve_denominator']?.toString(),
      rLensSph: map['r_lens_sph']?.toString(),
      rLensCyl: map['r_lens_cyl']?.toString(),
      rLensAxis: map['r_lens_axis']?.toString(),
      rMaterial: map['r_material']?.toString(),
      rTint: map['r_tint']?.toString(),
      rLensVaNumerator: map['r_lens_va_numerator']?.toString(),
      rLensVaDenominator: map['r_lens_va_denominator']?.toString(),
      lLensType: map['l_lens_type']?.toString(),
      lManufacturer: map['l_manufacturer']?.toString(),
      lBrand: map['l_brand']?.toString(),
      lDiameter: map['l_diameter']?.toString(),
      lBaseCurveNumerator: map['l_base_curve_numerator']?.toString(),
      lBaseCurveDenominator: map['l_base_curve_denominator']?.toString(),
      lLensSph: map['l_lens_sph']?.toString(),
      lLensCyl: map['l_lens_cyl']?.toString(),
      lLensAxis: map['l_lens_axis']?.toString(),
      lMaterial: map['l_material']?.toString(),
      lTint: map['l_tint']?.toString(),
      lLensVaNumerator: map['l_lens_va_numerator']?.toString(),
      lLensVaDenominator: map['l_lens_va_denominator']?.toString(),
      notes: map['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'exam_date': DateFormat('yyyy-MM-dd').format(examDate),
      'examiner': examiner,
      'r_rH': rRH,
      'r_rV': rRV,
      'r_aver': rAver,
      'r_k_cyl': rKCyl,
      'r_axH': rAxH,
      'r_rT': rRT,
      'r_rN': rRN,
      'r_rI': rRI,
      'r_rS': rRS,
      'l_rH': lRH,
      'l_rV': lRV,
      'l_aver': lAver,
      'l_k_cyl': lKCyl,
      'l_axH': lAxH,
      'l_rT': lRT,
      'l_rN': lRN,
      'l_rI': lRI,
      'l_rS': lRS,
      'r_lens_type': rLensType,
      'r_manufacturer': rManufacturer,
      'r_brand': rBrand,
      'r_diameter': rDiameter,
      'r_base_curve_numerator': rBaseCurveNumerator,
      'r_base_curve_denominator': rBaseCurveDenominator,
      'r_lens_sph': rLensSph,
      'r_lens_cyl': rLensCyl,
      'r_lens_axis': rLensAxis,
      'r_material': rMaterial,
      'r_tint': rTint,
      'r_lens_va_numerator': rLensVaNumerator,
      'r_lens_va_denominator': rLensVaDenominator,
      'l_lens_type': lLensType,
      'l_manufacturer': lManufacturer,
      'l_brand': lBrand,
      'l_diameter': lDiameter,
      'l_base_curve_numerator': lBaseCurveNumerator,
      'l_base_curve_denominator': lBaseCurveDenominator,
      'l_lens_sph': lLensSph,
      'l_lens_cyl': lLensCyl,
      'l_lens_axis': lLensAxis,
      'l_material': lMaterial,
      'l_tint': lTint,
      'l_lens_va_numerator': lLensVaNumerator,
      'l_lens_va_denominator': lLensVaDenominator,
      'notes': notes,
    };
  }
}
