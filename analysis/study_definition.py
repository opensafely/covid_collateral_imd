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

study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1980-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.05,
    },
    # Update index date to 2018-03-01 when ready to run on full dataset
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
    ),   
    age=patients.age_as_of(
            "index_date",
            return_expectations={
                "rate": "universal",
                "int": {"distribution": "population_ages"},
            },
    ),
    # Hospital admissions primary diagnosis - CVD
    # MI
    mi_primary_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=filter_codes_by_category(mi_icd_codes, include=["1"]),
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    # Stroke
    stroke_primary_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=stroke_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    # Heart failure
    heart_failure_primary_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=filter_codes_by_category(heart_failure_icd_codes, include=["1"]),
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    # VTE
    vte_primary_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=vte_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    # Hospital admissions - mental health
    depression_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=depression_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    anxiety_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=anxiety_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    smi_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=severe_mental_illness_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    self_harm_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=self_harm_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    eating_dis_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=eating_disorder_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    ocd_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=ocd_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    mh_admission=patients.satisfying(
        """
        depression_admission OR
        anxiety_admission OR
        smi_admission OR
        self_harm_admission OR
        eating_dis_admission OR
        ocd_admission
        """,
    ),
)
measures = [
    # Hospital admissions for MI
    Measure(
        id="mi_admission_imd_rate",
        numerator="mi_admission",
        denominator="population",
        group_by=["imd"],
    ),
    # Hospital admissions for stroke
    Measure(
        id="stroke_admission_imd_rate",
        numerator="stroke_admission",
        denominator="population",
        group_by=["imd"],
    ),
    # Hospital admission for heart failure
    Measure(
        id="heart_failure_admission_imd_rate",
        numerator="heart_failure_admission",
        denominator="population",
        group_by=["imd"],
    ),
    # Hospital admission for vte
    Measure(
        id="vte_admission_imd_rate",
        numerator="vte_admission",
        denominator="population",
        group_by=["imd"],
    ),
    # Hospital admission for mental health
    Measure(
        id="mh_admission_imd_rate",
        numerator="mh_admission",
        denominator="population",
        group_by=["imd"],
    ),
]