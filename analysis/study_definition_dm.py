# Creates study population with no restrictions but include indicators for
# mental health and CVD where clinical monitoring is diagnosis specific
from cohortextractor import (
    StudyDefinition,
    Measure,
    patients,
    filter_codes_by_category,
)
from codelists import *
from common_variables import common_variables

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
        (household>=1 AND household<=15)
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
        age=patients.age_as_of(
            "index_date",
            return_expectations={
                "rate": "universal",
                "int": {"distribution": "population_ages"},
            },
        ),
     # Inpatient admission with primary code of diabetes 
    # Type 1 DM
    t1dm_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=t1dm_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    # Type 2 DM
    t2dm_admission=patients.admitted_to_hospital(
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
    **common_variables
 )

measures = [
# Generate summary data by IMD for each outcome
    # Primary admission code type 1 DM
    Measure(
        id="dm_t1_imd_rate",
        numerator="t1dm_admission",
        denominator="has_t1_diabetes",
        group_by=["imd"],
    ),
    # Primary admission code type 2 DM
    Measure(
        id="dm_t2_imd_rate",
        numerator="t2dm_admission",
        denominator="has_t2_diabetes",
        group_by=["imd"],
    ),
    # Primary admission code ketoacidosis
    Measure(
        id="dm_keto_imd_rate",
        numerator="dm_keto_admission",
        denominator="population",
        group_by=["imd"],
    ),
]