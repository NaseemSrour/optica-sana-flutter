import 'package:intl/intl.dart';

class Customer {
  int id;
  int ssn;
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
  int? glassesNum;
  int? lensesNum;
  bool? mailing;
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
      ssn: map['ssn'],
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
      glassesNum: map['glasses_num'],
      lensesNum: map['lenses_num'],
      mailing: map['mailing'] == 1,
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
      'mailing': mailing == true ? 1 : 0,
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
  double? rCylinder;
  int? rAxis;
  double? rPrism;
  String? rBase;
  String? rVa;
  String? bothVa;
  double? rAddRead;
  double? rAddInt;
  double? rAddBif;
  double? rAddMul;
  double? rHigh;
  double? rPd;
  double? sumPd;
  double? nearPd;
  // --- Left Eye (OS) values ---
  String? lFv;
  String? lSphere;
  double? lCylinder;
  int? lAxis;
  double? lPrism;
  String? lBase;
  String? lVa;
  double? lAddRead; // Presbyopia addition
  double? lAddInt;
  double? lAddBif;
  double? lAddMul;
  double? lHigh;
  double? lPd;

  // --- Symptoms / Notes ---
  String? dominantEye;
  double? rIop;
  double? lIop;
  String? glassesRole;
  String? lensesMaterial;
  double? lensesDiameter1;
  double? lensesDiameter2;
  double? lensesDiameterDecentrationHorizontal;
  double? lensesDiameterDecentrationVertical;
  double? segmentDiameter;
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
      id: map['id'],
      customerId: map['customer_id'],
      examDate: DateFormat('yyyy-MM-dd').parse(map['exam_date']),
      examiner: map['examiner'],
      rFv: map['r_fv'],
      rSphere: map['r_sphere'],
      rCylinder: map['r_cylinder'],
      rAxis: map['r_axis'],
      rPrism: map['r_prism'],
      rBase: map['r_base'],
      rVa: map['r_va'],
      bothVa: map['both_va'],
      rAddRead: map['r_add_read'],
      rAddInt: map['r_add_int'],
      rAddBif: map['r_add_bif'],
      rAddMul: map['r_add_mul'],
      rHigh: map['r_high'],
      rPd: map['r_pd'],
      sumPd: map['sum_pd'],
      nearPd: map['near_pd'],
      lFv: map['l_fv'],
      lSphere: map['l_sphere'],
      lCylinder: map['l_cylinder'],
      lAxis: map['l_axis'],
      lPrism: map['l_prism'],
      lBase: map['l_base'],
      lVa: map['l_va'],
      lAddRead: map['l_add_read'],
      lAddInt: map['l_add_int'],
      lAddBif: map['l_add_bif'],
      lAddMul: map['l_add_mul'],
      lHigh: map['l_high'],
      lPd: map['l_pd'],
      dominantEye: map['dominant_eye'],
      rIop: map['r_iop'],
      lIop: map['l_iop'],
      glassesRole: map['glasses_role'],
      lensesMaterial: map['lenses_material'],
      lensesDiameter1: map['lenses_diameter_1'],
      lensesDiameter2: map['lenses_diameter_2'],
      lensesDiameterDecentrationHorizontal:
          map['lenses_diameter_decentration_horizontal'],
      lensesDiameterDecentrationVertical:
          map['lenses_diameter_decentration_vertical'],
      segmentDiameter: map['segment_diameter'],
      lensesManufacturer: map['lenses_manufacturer'],
      lensesColor: map['lenses_color'],
      lensesCoated: map['lenses_coated'],
      catalogNum: map['catalog_num'],
      frameManufacturer: map['frame_manufacturer'],
      frameSupplier: map['frame_supplier'],
      frameModel: map['frame_model'],
      frameSize: map['frame_size'],
      frameBarLength: map['frame_bar_length'],
      frameColor: map['frame_color'],
      diagnosis: map['diagnosis'],
      notes: map['notes'],
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
  double? rRH;
  double? rRV;
  double? rAver; // avg of (r_rH and r_rV)
  double? rKCyl; // elha nos7a, mnjebha b3den
  int? rAxH; // independent of cylinder
  double? rRT;
  double? rRN;
  double? rRI;
  double? rRS;
  double? lRH;
  double? lRV;
  double? lAver; // avg of (l_rH and l_rV)
  double? lKCyl;
  int? lAxH; // independent of cylinder
  double? lRT;
  double? lRN;
  double? lRI;
  double? lRS;

  // ===== Contact Lens Prescription (Right) =====
  String? rLensType;
  String? rManufacturer;
  String? rBrand;
  double? rDiameter;
  double? rBaseCurveNumerator;
  double? rBaseCurveDenominator;
  double? rLensSph;
  double? rLensCyl;
  int? rLensAxis;
  String? rMaterial;
  String? rTint;
  int? rLensVaNumerator;
  int? rLensVaDenominator;

  // ===== Contact Lens Prescription (Left) =====
  String? lLensType;
  String? lManufacturer;
  String? lBrand;
  double? lDiameter;
  double? lBaseCurveNumerator;
  double? lBaseCurveDenominator;
  double? lLensSph;
  double? lLensCyl;
  int? lLensAxis;
  String? lMaterial;
  String? lTint;
  int? lLensVaNumerator;
  int? lLensVaDenominator;

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
    return ContactLensesTest(
      id: map['id'],
      customerId: map['customer_id'],
      examDate: DateFormat('yyyy-MM-dd').parse(map['exam_date']),
      examiner: map['examiner'],
      rRH: map['r_rH'],
      rRV: map['r_rV'],
      rAver: map['r_aver'],
      rKCyl: map['r_k_cyl'],
      rAxH: map['r_axH'],
      rRT: map['r_rT'],
      rRN: map['r_rN'],
      rRI: map['r_rI'],
      rRS: map['r_rS'],
      lRH: map['l_rH'],
      lRV: map['l_rV'],
      lAver: map['l_aver'],
      lKCyl: map['l_k_cyl'],
      lAxH: map['l_axH'],
      lRT: map['l_rT'],
      lRN: map['l_rN'],
      lRI: map['l_rI'],
      lRS: map['l_rS'],
      rLensType: map['r_lens_type'],
      rManufacturer: map['r_manufacturer'],
      rBrand: map['r_brand'],
      rDiameter: map['r_diameter'],
      rBaseCurveNumerator: map['r_base_curve_numerator'],
      rBaseCurveDenominator: map['r_base_curve_denominator'],
      rLensSph: map['r_lens_sph'],
      rLensCyl: map['r_lens_cyl'],
      rLensAxis: map['r_lens_axis'],
      rMaterial: map['r_material'],
      rTint: map['r_tint'],
      rLensVaNumerator: map['r_lens_va_numerator'],
      rLensVaDenominator: map['r_lens_va_denominator'],
      lLensType: map['l_lens_type'],
      lManufacturer: map['l_manufacturer'],
      lBrand: map['l_brand'],
      lDiameter: map['l_diameter'],
      lBaseCurveNumerator: map['l_base_curve_numerator'],
      lBaseCurveDenominator: map['l_base_curve_denominator'],
      lLensSph: map['l_lens_sph'],
      lLensCyl: map['l_lens_cyl'],
      lLensAxis: map['l_lens_axis'],
      lMaterial: map['l_material'],
      lTint: map['l_tint'],
      lLensVaNumerator: map['l_lens_va_numerator'],
      lLensVaDenominator: map['l_lens_va_denominator'],
      notes: map['notes'],
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
