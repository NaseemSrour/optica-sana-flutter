const String schemaSql = """
CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ssn TEXT NOT NULL,
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
            glasses_num TEXT,
            lenses_num TEXT,
            mailing TEXT,
            notes TEXT
);

CREATE TABLE IF NOT EXISTS glasses_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER NOT NULL,
    exam_date TEXT NOT NULL,
    examiner TEXT,
    r_fv TEXT,
    r_sphere TEXT,
    r_cylinder TEXT,
    r_axis TEXT,
    r_prism TEXT,
    r_base TEXT,
    r_va TEXT,
    both_va TEXT,
    r_add_read TEXT,
    r_add_int TEXT,
    r_add_bif TEXT,
    r_add_mul TEXT,
    r_high TEXT,
    r_pd TEXT,
    sum_pd TEXT,
    near_pd TEXT,
    l_fv TEXT,
    l_sphere TEXT,
    l_cylinder TEXT,
    l_axis TEXT,
    l_prism TEXT,
    l_base TEXT,
    l_va TEXT,
    l_add_read TEXT,
    l_add_int TEXT,
    l_add_bif TEXT,
    l_add_mul TEXT,
    l_high TEXT,
    l_pd TEXT,
    dominant_eye TEXT,
    r_iop TEXT,
    l_iop TEXT,
    glasses_role TEXT,
    lenses_material TEXT,
    lenses_diameter_1 TEXT,
    lenses_diameter_2 TEXT,
    lenses_diameter_decentration_horizontal TEXT,
    lenses_diameter_decentration_vertical TEXT,
    segment_diameter TEXT,
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
    r_rH TEXT,
    r_rV TEXT,
    r_aver TEXT,
    r_k_cyl TEXT,
    r_axH TEXT,
    r_rT TEXT,
    r_rN TEXT,
    r_rI TEXT,
    r_rS TEXT,
    l_rH TEXT,
    l_rV TEXT,
    l_aver TEXT,
    l_k_cyl TEXT,
    l_axH TEXT,
    l_rT TEXT,
    l_rN TEXT,
    l_rI TEXT,
    l_rS TEXT,

    -- ===== Contact Lens Prescription =====

    r_lens_type TEXT, -- e.g., "SF"
    r_manufacturer TEXT,
    r_brand TEXT,
    r_diameter TEXT,
    r_base_curve_numerator TEXT,
    r_base_curve_denominator TEXT,
    r_lens_sph TEXT,
    r_lens_cyl TEXT,
    r_lens_axis TEXT,
    r_material TEXT,
    r_tint TEXT,
    r_lens_va_numerator TEXT,
    r_lens_va_denominator TEXT,

    l_lens_type TEXT,
    l_manufacturer TEXT,
    l_brand TEXT,
    l_diameter TEXT,
    l_base_curve_numerator TEXT,
    l_base_curve_denominator TEXT,
    l_lens_sph TEXT,
    l_lens_cyl TEXT,
    l_lens_axis TEXT,
    l_material TEXT,
    l_tint TEXT,
    l_lens_va_numerator TEXT, -- "6/6", "6/9", etc.
    l_lens_va_denominator TEXT,
    notes TEXT,


    -- ===== Dependency Constraints =====

    CHECK (
        -- Contact lens toric rules
        (r_lens_cyl IS NULL AND r_lens_axis IS NULL) OR
        (r_lens_cyl = '0' AND r_lens_axis IS NULL) OR
        (r_lens_cyl <> '0' AND CAST(r_lens_axis AS REAL) BETWEEN 0 AND 180)
    ),
        CHECK (
        -- Contact lens toric rules
        (l_lens_cyl IS NULL AND l_lens_axis IS NULL) OR
        (l_lens_cyl = '0' AND l_lens_axis IS NULL) OR
        (l_lens_cyl <> '0' AND CAST(l_lens_axis AS REAL) BETWEEN 0 AND 180)
    ),

     FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
    );
""";
