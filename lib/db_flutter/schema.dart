const String schemaSql = """
CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ssn INTEGER NOT NULL,
            fname TEXT NOT NULL,
            lname TEXT NOT NULL,
            birth_date TEXT,
            sex TEXT,
            tel_home TEXT,
            tel_mobile TEXT,
            address TEXT,
            town TEXT,
            postal_code TEXT,
            status TEXT,
            org TEXT,
            occupation TEXT,
            hobbies TEXT,
            referer TEXT,
            glasses_num INTEGER,
            lenses_num INTEGER,
            mailing INTEGER,
            notes TEXT
);

CREATE TABLE IF NOT EXISTS glasses_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER NOT NULL,
    exam_date TEXT NOT NULL,
    examiner TEXT,
    r_fv TEXT,
    r_sphere TEXT,
    r_cylinder REAL,
    r_axis INTEGER,
    r_prism REAL,
    r_base TEXT,
    r_va TEXT,
    both_va TEXT,
    r_add_read REAL,
    r_add_int REAL,
    r_add_bif REAL,
    r_add_mul REAL,
    r_high REAL,
    r_pd REAL,
    sum_pd REAL,
    near_pd REAL,
    l_fv TEXT,
    l_sphere REAL,
    l_cylinder REAL,
    l_axis INTEGER,
    l_prism REAL,
    l_base TEXT,
    l_va TEXT,
    l_add_read REAL,
    l_add_int REAL,
    l_add_bif REAL,
    l_add_mul REAL,
    l_high REAL,
    l_pd REAL,
    dominant_eye TEXT,
    r_iop REAL,
    l_iop REAL,
    glasses_role TEXT,
    lenses_material TEXT,
    lenses_diameter_1 REAL,
    lenses_diameter_2 REAL,
    lenses_diameter_decentration_horizontal REAL,
    lenses_diameter_decentration_vertical REAL,
    segment_diameter REAL,
    lenses_manufacturer TEXT,
    lenses_color TEXT,
    lenses_coated TEXT,
    catalog_num TEXT,
    frame_manufacturer TEXT,
    frame_supplier TEXT,
    frame_model TEXT,
    frame_size TEXT,
    frame_bar_length TEXT,
    frame_color TEXT,
    diagnosis TEXT,
    notes TEXT,

    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);


    CREATE TABLE IF NOT EXISTS contact_lenses_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER NOT NULL,
    exam_date TEXT NOT NULL,
    examiner TEXT,
        -- ===== Keratometry =====
    r_rH REAL,
    r_rV REAL,
    r_aver REAL,
    r_k_cyl REAL,
    r_axH INTEGER,
    r_rT REAL,
    r_rN REAL,
    r_rI REAL,
    r_rS REAL,
    l_rH REAL,
    l_rV REAL,
    l_aver REAL,
    l_k_cyl REAL,
    l_axH INTEGER,
    l_rT REAL,
    l_rN REAL,
    l_rI REAL,
    l_rS REAL,

    -- ===== Contact Lens Prescription =====

    r_lens_type TEXT, -- e.g., "SF"
    r_manufacturer TEXT,
    r_brand TEXT,
    r_diameter REAL,
    r_base_curve_numerator REAL,
    r_base_curve_denominator REAL,
    r_lens_sph REAL,
    r_lens_cyl REAL,
    r_lens_axis INTEGER,
    r_material TEXT,
    r_tint TEXT,
    r_lens_va_numerator INTEGER,
    r_lens_va_denominator INTEGER,

    l_lens_type TEXT,
    l_manufacturer TEXT,
    l_brand TEXT,
    l_diameter REAL,
    l_base_curve_numerator REAL,
    l_base_curve_denominator REAL,
    l_lens_sph REAL,
    l_lens_cyl REAL,
    l_lens_axis INTEGER,
    l_material TEXT,
    l_tint TEXT,
    l_lens_va_numerator INTEGER, -- "6/6", "6/9", etc.
    l_lens_va_denominator INTEGER,
    notes TEXT,


    -- ===== Dependency Constraints =====

    CHECK (
        -- Contact lens toric rules
        (r_lens_cyl IS NULL AND r_lens_axis IS NULL) OR
        (r_lens_cyl = 0 AND r_lens_axis IS NULL) OR
        (r_lens_cyl <> 0 AND r_lens_axis BETWEEN 0 AND 180)
    ),
        CHECK (
        -- Contact lens toric rules
        (l_lens_cyl IS NULL AND l_lens_axis IS NULL) OR
        (l_lens_cyl = 0 AND l_lens_axis IS NULL) OR
        (l_lens_cyl <> 0 AND l_lens_axis BETWEEN 0 AND 180)
    ),

     FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
    );
""";
