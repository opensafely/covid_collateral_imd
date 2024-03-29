from cohortextractor import codelist_from_csv, codelist

# Diagnosis codes for GP records
# Diabetes - type 1 & 2
t1dm_codes= codelist_from_csv(
    "codelists/opensafely-type-1-diabetes.csv",
    system="ctv3",
    column="CTV3ID",)
t2dm_codes= codelist_from_csv(
    "codelists/opensafely-type-2-diabetes.csv",
    system="ctv3",
    column="CTV3ID",)
# Respiratory disease - asthma and COPD - update to SNOMED?
asthma_codes = codelist_from_csv(
    "codelists/opensafely-current-asthma.csv",
    system="ctv3",
    column="CTV3ID",)
copd_codes = codelist_from_csv(
    "codelists/opensafely-current-copd.csv",
    system="ctv3",
    column="CTV3ID",)

# ICD codes for hospitalisations and deaths
# Diabetes outcomes - DM or ketoacidosis
dm_keto_icd_codes = codelist_from_csv(
    "codelists/opensafely-diabetic-ketoacidosis-secondary-care.csv",
    system="icd10",
    column="icd10_code",)
    # confirming type 1 & type 2 codes

# CVD outcomes - MI, stroke, TIA, unstable angina, heart failure & vte
mi_icd_codes = codelist_from_csv(
    "codelists/opensafely-cardiovascular-secondary-care.csv",
    system="icd10",
    column="icd",
    category_column="mi",
)
stroke_icd_codes = codelist_from_csv(
    "codelists/opensafely-stroke-secondary-care.csv",
    system="icd10",
    column="icd",)
heart_failure_icd_codes = codelist_from_csv(
    "codelists/opensafely-cardiovascular-secondary-care.csv",
    system="icd10",
    column="icd",
    category_column="heartfailure",)
vte_icd_codes = codelist_from_csv(
    "codelists/opensafely-venous-thromboembolic-disease-hospital.csv",
    system="icd10",
    column="ICD_code",)
# Respiratory outcomes
asthma_exacerbation_icd_codes = codelist_from_csv(
    "codelists/opensafely-asthma-exacerbation-secondary-care.csv",
    system="icd10",
    column="code",)

copd_icd_codes = codelist_from_csv(
    "codelists/opensafely-copd-secondary-care.csv",
    system="icd10",
    column="code",)
copd_exacerbation_icd_codes = codelist_from_csv(
    "codelists/opensafely-copd-exacerbation.csv",
    system="icd10",
    column="code",)
lrti_icd_codes = codelist_from_csv(
    "codelists/opensafely-lower-respiratory-tract-infection-secondary-care.csv",
    system="icd10",
    column="code",)

# Mental health outcomes
depression_icd_codes = codelist_from_csv(
    "codelists/user-emilyherrett-depression_icd10.csv",
    system="icd10",
    column="code",)

severe_mental_illness_icd_codes = codelist_from_csv(
    "codelists/user-emilyherrett-severe_mental_illness_icd10.csv",
    system="icd10",
    column="code",
)

anxiety_icd_codes = codelist_from_csv(
    "codelists/user-emilyherrett-anxiety_icd10.csv",
    system="icd10",
    column="code",
)

ocd_icd_codes = codelist_from_csv(
    "codelists/user-emilyherrett-ocd_icd10.csv",
    system="icd10",
    column="code",
)

eating_disorder_icd_codes = codelist_from_csv(
    "codelists/user-emilyherrett-eating_disorder_icd10.csv",
    system="icd10",
    column="code",
)

self_harm_icd_codes = codelist_from_csv(
    "codelists/user-emilyherrett-self_harm_icd10.csv",
    system="icd10",
    column="code",
)

suicide_icd_codes = codelist_from_csv(
    "codelists/user-hjforbes-suicide-icd-10.csv",
    system="icd10",
    column="code",
)

migration_codes = codelist_from_csv(
    "codelists/user-ruthcostello-migration-status-codes.csv",
    system="snomed",
    column="code",
)