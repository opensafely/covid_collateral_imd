# Creates study population with no restrictions but include indicators for
# mental health and CVD where clinical monitoring is diagnosis specific
from cohortextractor import (
    StudyDefinition,
    Measure,
    patients,
    filter_codes_by_category,
)
from codelists import *
#from common_variables import common_variables

# Create ICD-10 codelists for type 1 and type 2 diabetes
# Remove once codelists are on opencodelists
t1dm_icd_codes = codelist(["E10"], system="icd10")
t2dm_icd_codes = codelist(["E11"], system="icd10")

study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1980-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.05,
    },
    
    index_date="2018-03-01",
    population=patients.satisfying(
        """
        has_follow_up AND
        (age >=18 AND age <= 110) AND
        (NOT died) AND
        (sex = 'M' OR sex = 'F') AND
        (imd != 0) AND
        (household>=1 AND household<=15) AND
        diabetes_subgroup
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "index_date - 3 months", "index_date"
        ),
        died=patients.died_from_any_cause(
            on_or_before="index_date"
            ),
        household=patients.household_as_of(
            "2020-02-01",
            returning="household_size",
        ),
    ),
    age=patients.age_as_of(
    "index_date",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),
    # Sex
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.5, "U": 0.01}},
        },
    ),
    has_msoa=patients.satisfying(
    "NOT (msoa = '')",
        msoa=patients.address_as_of(
        "index_date",
        returning="msoa",
    ),
    return_expectations={"incidence": 1.0}
    ),
    imd=patients.categorised_as(
        {
        "0": "DEFAULT",
        "1": """index_of_multiple_deprivation >=0 AND index_of_multiple_deprivation < 32844*1/5 AND has_msoa""",
        "2": """index_of_multiple_deprivation >= 32844*1/5 AND index_of_multiple_deprivation < 32844*2/5""",
        "3": """index_of_multiple_deprivation >= 32844*2/5 AND index_of_multiple_deprivation < 32844*3/5""",
        "4": """index_of_multiple_deprivation >= 32844*3/5 AND index_of_multiple_deprivation < 32844*4/5""",
        "5": """index_of_multiple_deprivation >= 32844*4/5 AND index_of_multiple_deprivation <= 32844""",
        },
    index_of_multiple_deprivation=patients.address_as_of(
        "index_date",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        ),
    return_expectations={
        "rate": "universal",
        "category": {
            "ratios": {
                "0": 0.05,
                "1": 0.19,
                "2": 0.19,
                "3": 0.19,
                "4": 0.19,
                "5": 0.19,
                }
            },
        },
    ),
    # Migration status
    migration_status=patients.with_these_clinical_events(
        migration_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence":0.2,},
    ),
    # Subgroups
    has_t1_diabetes=patients.with_these_clinical_events(
        t1dm_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence":0.2,}
        ),
    has_t2_diabetes=patients.with_these_clinical_events(
        t2dm_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence":0.8,}
        ),
    diabetes_subgroup=patients.satisfying(
        """
        has_t1_diabetes OR 
        has_t2_diabetes
        """,
    ),
     # Inpatient admission with primary code of diabetes 
    # Type 1 DM
    dmt1_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=t1dm_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    # Type 2 DM
    dmt2_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=t2dm_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    # Ketoacidosis
    dm_keto_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=dm_keto_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    # Death outcomes
    dmt1_mortality = patients.with_these_codes_on_death_certificate(
    t1dm_icd_codes,
    between=["index_date", "last_day_of_month(index_date)"],
    match_only_underlying_cause=True,
    returning="binary_flag",
    ),
    dmt2_mortality = patients.with_these_codes_on_death_certificate(
    t2dm_icd_codes,
    between=["index_date", "last_day_of_month(index_date)"],
    match_only_underlying_cause=True,
    returning="binary_flag",
    ),
    dm_keto_mortality = patients.with_these_codes_on_death_certificate(
    dm_keto_icd_codes,
    between=["index_date", "last_day_of_month(index_date)"],
    match_only_underlying_cause=True,
    returning="binary_flag",
    ),
    #**common_variables
)
measures = [
# Generate summary data by IMD for each outcome
    # Primary admission code type 1 DM
    Measure(
        id="dmt1_admission_imd_rate",
        numerator="dmt1_admission",
        denominator="has_t1_diabetes",
        group_by=["imd"],
    ),
    # Primary admission code type 2 DM
    Measure(
        id="dmt2_admission_imd_rate",
        numerator="dmt2_admission",
        denominator="has_t2_diabetes",
        group_by=["imd"],
    ),
    # Primary admission code ketoacidosis
    Measure(
        id="dm_keto_admission_imd_rate",
        numerator="dm_keto_admission",
        denominator="population",
        group_by=["imd"],
    ),
    # Death underlying cause code type 1 DM
    Measure(
        id="dmt1_mortality_imd_rate",
        numerator="dmt1_mortality",
        denominator="has_t1_diabetes",
        group_by=["imd"],
    ),
    # Death underlying cause code type 2 DM
    Measure(
        id="dmt2_mortality_imd_rate",
        numerator="dmt2_mortality",
        denominator="has_t2_diabetes",
        group_by=["imd"],
    ),
    # Death underlying cause code ketoacidosis
    Measure(
        id="dm_keto_mortality_imd_rate",
        numerator="dm_keto_mortality",
        denominator="population",
        group_by=["imd"],
    ),

    # Generate summary data by migration status for each outcome
    # Primary admission code type 1 DM
    Measure(
        id="dmt1_admission_migration_status_rate",
        numerator="dmt1_admission",
        denominator="has_t1_diabetes",
        group_by=["migration_status"],
    ),
    # Primary admission code type 2 DM
    Measure(
        id="dmt2_admission_migration_status_rate",
        numerator="dmt2_admission",
        denominator="has_t2_diabetes",
        group_by=["migration_status"],
    ),
    # Primary admission code ketoacidosis
    Measure(
        id="dm_keto_admission_migration_status_rate",
        numerator="dm_keto_admission",
        denominator="population",
        group_by=["migration_status"],
    ),
    # Death underlying cause code type 1 DM
    Measure(
        id="dmt1_mortality_migration_status_rate",
        numerator="dmt1_mortality",
        denominator="has_t1_diabetes",
        group_by=["migration_status"],
    ),
    # Death underlying cause code type 2 DM
    Measure(
        id="dmt2_mortality_migration_status_rate",
        numerator="dmt2_mortality",
        denominator="has_t2_diabetes",
        group_by=["migration_status"],
    ),
    # Death underlying cause code ketoacidosis
    Measure(
        id="dm_keto_mortality_migration_status_rate",
        numerator="dm_keto_mortality",
        denominator="population",
        group_by=["migration_status"],
    ),
]