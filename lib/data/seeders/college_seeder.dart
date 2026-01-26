import 'package:cloud_firestore/cloud_firestore.dart';

class CollegeSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= STANDARD DEPARTMENT LISTS =================
  static final List<String> _autonomousBranches = [
    'CSE',
    'CSE (AI & ML)',
    'CSE (Data Science)',
    'CSE (Cyber Security)',
    'Information Technology',
    'Artificial Intelligence & Data Science',
    'ECE',
    'EEE',
    'Mechanical Engineering',
    'Civil Engineering'
  ];

  static final List<String> _universityBranches = [
    'CSE',
    'ECE',
    'EEE',
    'Mechanical Engineering',
    'Civil Engineering',
    'Chemical Engineering',
    'Metallurgical Engineering',
    'Biomedical Engineering',
    'Mining Engineering'
  ];

  static final List<String> _affiliatedBranches = [
    'CSE',
    'CSE (AI & ML)',
    'CSE (Data Science)',
    'ECE',
    'EEE',
    'Mechanical Engineering',
    'Civil Engineering',
    'Information Technology'
  ];

  // ================= MASTER COLLEGE LIST (FULL) =================
  static final List<Map<String, dynamic>> telanganaColleges = [
    {
      'id': 'ts_clg_vjit',
      'code': 'VJIT',
      'name': 'Vidya Jyothi Institute of Technology',
      'location': 'Moinabad, Hyderabad',
      'address': 'Aziznagar Gate, C.B. Post, Chilkur Road, Moinabad, Rangareddy - 500075',
      'website': 'https://vjit.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': [
        'CSE', 'CSE (AI-ML)', 'CSE (AI-DS)', 'CSE (DS)',
        'ECE', 'EEE', 'IT', 'AI', 'Mechanical', 'Civil'
      ]
    },
    {
      'id': 'ts_uni_jnth',
      'code': 'JNTUH',
      'name': 'JNTUH College of Engineering Hyderabad',
      'location': 'Kukatpally, Hyderabad',
      'website': 'https://jntuhceh.ac.in',
      'type': 'University',
      'isActive': true,
      'departments': _universityBranches
    },
    {
      'id': 'ts_uni_ouce',
      'code': 'OUCE',
      'name': 'Osmania University College of Engineering',
      'location': 'Amberpet, Hyderabad',
      'website': 'https://www.uceou.edu',
      'type': 'University',
      'isActive': true,
      'departments': _universityBranches
    },
    {
      'id': 'ts_uni_kuwl',
      'code': 'KUWL',
      'name': 'Kakatiya University College of Engineering',
      'location': 'Warangal',
      'website': 'https://kuce.ac.in',
      'type': 'University',
      'isActive': true,
      'departments': _universityBranches
    },
    {
      'id': 'ts_uni_jntj',
      'code': 'JNTJ',
      'name': 'JNTUH College of Engineering Jagtial',
      'location': 'Jagtial',
      'website': 'https://jntuhcej.ac.in',
      'type': 'University',
      'isActive': true,
      'departments': _affiliatedBranches
    },
    {
      'id': 'ts_uni_jnts',
      'code': 'JNTS',
      'name': 'JNTUH College of Engineering Sultanpur',
      'location': 'Sangareddy',
      'website': 'https://jntuhces.ac.in',
      'type': 'University',
      'isActive': true,
      'departments': _affiliatedBranches
    },
    {
      'id': 'ts_clg_cbit',
      'code': 'CBIT',
      'name': 'Chaitanya Bharathi Institute of Technology',
      'location': 'Gandipet, Hyderabad',
      'website': 'https://www.cbit.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': [..._autonomousBranches, 'Biotechnology', 'Chemical Engineering']
    },
    {
      'id': 'ts_clg_vjec',
      'code': 'VJEC',
      'name': 'VNR Vignana Jyothi Institute of Engg & Tech',
      'location': 'Bachupally, Hyderabad',
      'website': 'http://www.vnrvjiet.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': [..._autonomousBranches, 'Automobile Engineering', 'EIE']
    },
    {
      'id': 'ts_clg_vasv',
      'code': 'VASV',
      'name': 'Vasavi College of Engineering',
      'location': 'Ibrahimbagh, Hyderabad',
      'website': 'https://www.vce.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': _autonomousBranches
    },
    {
      'id': 'ts_clg_grrr',
      'code': 'GRRR',
      'name': 'Gokaraju Rangaraju Institute of Engg & Tech',
      'location': 'Bachupally, Hyderabad',
      'website': 'http://www.griet.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': _autonomousBranches
    },
    {
      'id': 'ts_clg_cvsr',
      'code': 'CVSR',
      'name': 'Anurag University',
      'location': 'Ghatkesar, Hyderabad',
      'website': 'https://anurag.edu.in',
      'type': 'Private University',
      'isActive': true,
      'departments': [..._autonomousBranches, 'Chemical Engineering', 'Pharmacy']
    },
    {
      'id': 'ts_clg_snis',
      'code': 'SNIS',
      'name': 'Sreenidhi Institute of Science and Technology',
      'location': 'Ghatkesar, Hyderabad',
      'website': 'https://www.sreenidhi.edu.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': [..._autonomousBranches, 'ECM']
    },
    {
      'id': 'ts_clg_vard',
      'code': 'VARD',
      'name': 'Vardhaman College of Engineering',
      'location': 'Shamshabad, Hyderabad',
      'website': 'https://vardhaman.org',
      'type': 'Autonomous',
      'isActive': true,
      'departments': _autonomousBranches
    },
    {
      'id': 'ts_clg_mvsr',
      'code': 'MVSR',
      'name': 'Maturi Venkata Subba Rao Engineering College',
      'location': 'Nadergul, Hyderabad',
      'website': 'http://www.mvsrec.edu.in',
      'type': 'Private',
      'isActive': true,
      'departments': [..._autonomousBranches, 'Automobile Engineering']
    },
    {
      'id': 'ts_clg_mgit',
      'code': 'MGIT',
      'name': 'Mahatma Gandhi Institute of Technology',
      'location': 'Gandipet, Hyderabad',
      'website': 'https://mgit.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': [..._autonomousBranches, 'Mechatronics', 'Metallurgy']
    },
    {
      'id': 'ts_clg_kmit',
      'code': 'KMIT',
      'name': 'Keshav Memorial Institute of Technology',
      'location': 'Narayanguda, Hyderabad',
      'website': 'https://kmit.in',
      'type': 'Private',
      'isActive': true,
      'departments': ['CSE', 'CSE (AI & ML)', 'CSE (Data Science)', 'Information Technology']
    },
    {
      'id': 'ts_clg_gnits',
      'code': 'GNITS',
      'name': 'G. Narayanamma Institute of Tech & Science (Women)',
      'location': 'Shaikpet, Hyderabad',
      'website': 'https://www.gnits.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': [..._autonomousBranches, 'ETM']
    },
    {
      'id': 'ts_clg_iare',
      'code': 'IARE',
      'name': 'Institute of Aeronautical Engineering',
      'location': 'Dundigal, Hyderabad',
      'website': 'https://www.iare.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': [..._autonomousBranches, 'Aeronautical Engineering']
    },
    {
      'id': 'ts_clg_mrec',
      'code': 'MREC',
      'name': 'Malla Reddy Engineering College',
      'location': 'Maisammaguda, Secunderabad',
      'website': 'http://www.mrec.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': [..._autonomousBranches, 'Mining Engineering']
    },
    {
      'id': 'ts_clg_cmrk',
      'code': 'CMRK',
      'name': 'CMR College of Engineering & Technology',
      'location': 'Kandlakoya, Hyderabad',
      'website': 'https://cmrcet.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': _autonomousBranches
    },
    {
      'id': 'ts_clg_bvrit',
      'code': 'BVRI',
      'name': 'BV Raju Institute of Technology',
      'location': 'Narsapur, Medak',
      'website': 'https://bvrit.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': [..._autonomousBranches, 'Chemical Engineering', 'Pharmaceutical Engg']
    },
    {
      'id': 'ts_clg_bvrw',
      'code': 'BVRW',
      'name': 'BVRIT Hyderabad College of Engineering for Women',
      'location': 'Bachupally, Hyderabad',
      'website': 'http://bvrithyderabad.edu.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': _autonomousBranches
    },
    {
      'id': 'ts_clg_tkrc',
      'code': 'TKRC',
      'name': 'TKR College of Engineering and Technology',
      'location': 'Meerpet, Hyderabad',
      'website': 'https://tkrcet.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': _autonomousBranches
    },
    {
      'id': 'ts_clg_mlid',
      'code': 'MLID',
      'name': 'Marri Laxman Reddy Institute of Technology (MLRIT)',
      'location': 'Dundigal, Hyderabad',
      'website': 'https://mlrinstitutions.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': [..._autonomousBranches, 'Aeronautical Engineering']
    },
    {
      'id': 'ts_clg_guru',
      'code': 'GURU',
      'name': 'Guru Nanak Institutions Technical Campus',
      'location': 'Ibrahimpatnam',
      'website': 'https://www.gniindia.org',
      'type': 'Autonomous',
      'isActive': true,
      'departments': _autonomousBranches
    },
    {
      'id': 'ts_clg_jbge',
      'code': 'JBGE',
      'name': 'J.B. Institute of Engineering and Technology',
      'location': 'Moinabad, Hyderabad',
      'website': 'https://www.jbiet.edu.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': [..._autonomousBranches, 'Mining Engineering', 'ECM']
    },
    {
      'id': 'ts_clg_cmtc',
      'code': 'CMTC',
      'name': 'CMR Technical Campus',
      'location': 'Kandlakoya, Hyderabad',
      'website': 'http://cmrtc.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': _autonomousBranches
    },
    {
      'id': 'ts_clg_mrcet',
      'code': 'MRCE',
      'name': 'Malla Reddy College of Engineering and Technology',
      'location': 'Maisammaguda, Secunderabad',
      'website': 'https://mrcet.com',
      'type': 'Autonomous',
      'isActive': true,
      'departments': [..._autonomousBranches, 'Aeronautical Engineering']
    },
    {
      'id': 'ts_clg_geet',
      'code': 'GEET',
      'name': 'Geethanjali College of Engineering and Technology',
      'location': 'Cheeryal, Keesara',
      'website': 'http://www.geethanjaliinstitutions.com',
      'type': 'Autonomous',
      'isActive': true,
      'departments': _autonomousBranches
    },
    {
      'id': 'ts_clg_srec',
      'code': 'SREC',
      'name': 'SR Engineering College',
      'location': 'Warangal',
      'website': 'http://srecwarangal.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': _autonomousBranches
    },
    {
      'id': 'ts_clg_kits',
      'code': 'KITS',
      'name': 'Kakatiya Institute of Technology and Science',
      'location': 'Warangal',
      'website': 'https://kitsw.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': [..._autonomousBranches, 'EIE']
    },
    {
      'id': 'ts_clg_matr',
      'code': 'MATR',
      'name': 'Matrusri Engineering College',
      'location': 'Saidabad, Hyderabad',
      'website': 'http://matrusri.edu.in',
      'type': 'Private',
      'isActive': true,
      'departments': _affiliatedBranches
    },
    {
      'id': 'ts_clg_meth',
      'code': 'METH',
      'name': 'Methodist College of Engineering and Technology',
      'location': 'Abids, Hyderabad',
      'website': 'http://methodist.edu.in',
      'type': 'Private',
      'isActive': true,
      'departments': _affiliatedBranches
    },
    {
      'id': 'ts_clg_brec',
      'code': 'BREC',
      'name': 'Bhoj Reddy Engineering College for Women',
      'location': 'Saidabad, Hyderabad',
      'website': 'http://brecw.ac.in',
      'type': 'Private',
      'isActive': true,
      'departments': ['CSE', 'ECE', 'EEE', 'IT', 'CSE (AI & ML)']
    },
    {
      'id': 'ts_clg_stan',
      'code': 'STAN',
      'name': 'Stanley College of Engineering and Technology for Women',
      'location': 'Abids, Hyderabad',
      'website': 'https://www.stanley.edu.in',
      'type': 'Private',
      'isActive': true,
      'departments': _autonomousBranches
    },
    {
      'id': 'ts_clg_smec',
      'code': 'SMEC',
      'name': 'St. Martin\'s Engineering College',
      'location': 'Dhulapally, Secunderabad',
      'website': 'https://www.smec.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': _autonomousBranches
    },
    {
      'id': 'ts_clg_spho',
      'code': 'SPHO',
      'name': 'Sphoorthy Engineering College',
      'location': 'Nadergul, Hyderabad',
      'website': 'https://sphoorthyengg.ac.in',
      'type': 'Private',
      'isActive': true,
      'departments': _affiliatedBranches
    },
    {
      'id': 'ts_clg_nall',
      'code': 'NALL',
      'name': 'Nalla Malla Reddy Engineering College',
      'location': 'Ghatkesar, Hyderabad',
      'website': 'https://www.nmrec.edu.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': _autonomousBranches
    },
    {
      'id': 'ts_clg_lori',
      'code': 'LORI',
      'name': 'Lords Institute of Engineering and Technology',
      'location': 'Himayathsagar, Hyderabad',
      'website': 'https://www.lords.ac.in',
      'type': 'Autonomous',
      'isActive': true,
      'departments': _autonomousBranches
    },
    {
      'id': 'ts_clg_islm',
      'code': 'ISLM',
      'name': 'ISL Engineering College',
      'location': 'Bandlaguda, Hyderabad',
      'website': 'https://islec.edu.in',
      'type': 'Private',
      'isActive': true,
      'departments': _affiliatedBranches
    },
    {
      'id': 'ts_clg_mjce',
      'code': 'MJCE',
      'name': 'Muffakham Jah College of Engineering and Technology',
      'location': 'Banjara Hills, Hyderabad',
      'website': 'http://mjcollege.ac.in',
      'type': 'Private',
      'isActive': true,
      'departments': [..._universityBranches, 'Artificial Intelligence', 'Production Engg']
    },
    {
      'id': 'ts_clg_jbit_2',
      'code': 'JBRE',
      'name': 'Joginpally B.R. Engineering College',
      'location': 'Moinabad, Hyderabad',
      'website': 'https://jbrec.edu.in',
      'type': 'Private',
      'isActive': true,
      'departments': _affiliatedBranches
    },
    {
      'id': 'ts_clg_sridevi',
      'code': 'SREW',
      'name': 'Sridevi Women\'s Engineering College',
      'location': 'Vattinagulapally, Hyderabad',
      'website': 'http://www.srideviengg.com',
      'type': 'Private',
      'isActive': true,
      'departments': _affiliatedBranches
    },
  ];

  static Future<void> seedColleges() async {
    WriteBatch batch = _firestore.batch();
    int count = 0;
    int operationCount = 0;

    print('🚀 Starting seed for ${telanganaColleges.length} colleges...');

    try {
      for (var college in telanganaColleges) {
        final docRef = _firestore.collection('colleges').doc(college['id'] as String);

        final data = {
          ...college,
          'searchKey': (college['name'] as String).toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        batch.set(docRef, data, SetOptions(merge: true));
        count++;
        operationCount++;

        // 🔥 SAFETY: Firestore limit is 500 operations per batch
        if (operationCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          operationCount = 0;
          print('📦 Intermediate batch committed...');
        }
      }

      await batch.commit();
      print('✅ Successfully seeded $count Telangana colleges!');
    } catch (e) {
      print('❌ Error seeding colleges: $e');
      rethrow;
    }
  }
}