# Creates study population with no restrictions but include indicators for
# mental health and CVD where clinical monitoring is diagnosis specific
from cohortextractor import (
    StudyDefinition,
    Measure,
    patients,
    filter_codes_by_category,
    combine_codelists,
)
from codelists import *
#from common_variables import common_variables

all_mh_codes = combine_codelists(
    depression_icd_codes,
    anxiety_icd_codes,
    severe_mental_illness_icd_codes,
    self_harm_icd_codes,
    eating_disorder_icd_codes,
    ocd_icd_codes,
    suicide_icd_codes
)

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
        # Age
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
        return_expectations={"incidence": 0.95}
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

    has_asthma=patients.with_these_clinical_events(
        asthma_codes,
        between=["index_date - 3 years", "index_date"],
        returning="binary_flag",
        return_expectations={"incidence":0.2,}
        ),
    has_copd=patients.satisfying(
    """has_copd_code AND age40>40""",
        has_copd_code=patients.with_these_clinical_events(
        copd_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence":0.8,}
        ),
        age40=patients.age_as_of(
            "index_date",
            return_expectations={
                "rate": "universal",
                "int": {"distribution": "population_ages"},
            },
        ),
    ),  
    # Hospital admissions primary diagnosis - CVD
    # MI
    mi_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=filter_codes_by_category(mi_icd_codes, include=["1"]),
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    # Stroke
    stroke_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=stroke_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    # Heart failure
    heart_failure_admission=patients.admitted_to_hospital(
        with_these_primary_diagnoses=filter_codes_by_category(heart_failure_icd_codes, include=["1"]),
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    # VTE
    vte_admission=patients.admitted_to_hospital(
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

    # Death outcomes
     # Each CVD outcome
    stroke_mortality = patients.with_these_codes_on_death_certificate(
    stroke_icd_codes,
    between=["index_date", "last_day_of_month(index_date)"],
    match_only_underlying_cause=True,
    returning="binary_flag",
    ),
    vte_mortality = patients.with_these_codes_on_death_certificate(
    vte_icd_codes,
    between=["index_date", "last_day_of_month(index_date)"],
    match_only_underlying_cause=True,
    returning="binary_flag",
    ),
    mi_mortality = patients.with_these_codes_on_death_certificate(
    filter_codes_by_category(mi_icd_codes, include=["1"]),
    between=["index_date", "last_day_of_month(index_date)"],
    match_only_underlying_cause=True,
    returning="binary_flag",
    ),
    heart_failure_mortality = patients.with_these_codes_on_death_certificate(
    filter_codes_by_category(heart_failure_icd_codes, include=["1"]),
    between=["index_date", "last_day_of_month(index_date)"],
    match_only_underlying_cause=True,
    returning="binary_flag",
    ),

    # Mental health outcomes combined
    mh_mortality=patients.with_these_codes_on_death_certificate(
        all_mh_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        match_only_underlying_cause=True,
        returning="binary_flag",
    ),
    # **common_variables
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

    # Deaths for CVD outcomes
    Measure(
        id="mi_mortality_imd_rate",
        numerator="mi_mortality",
        denominator="population",
        group_by=["imd"],
    ),

    Measure(
        id="stroke_mortality_imd_rate",
        numerator="stroke_mortality",
        denominator="population",
        group_by=["imd"],
    ),

    Measure(
        id="vte_mortality_imd_rate",
        numerator="vte_mortality",
        denominator="population",
        group_by=["imd"],
    ),

    Measure(
        id="heart_failure_mortality_imd_rate",
        numerator="heart_failure_mortality",
        denominator="population",
        group_by=["imd"],
    ),

     # Hospital admission for mental health
    Measure(
        id="mh_mortality_imd_rate",
        numerator="mh_mortality",
        denominator="population",
        group_by=["imd"],
    ),
    # Same for migration status
        # Hospital admissions for MI
    Measure(
        id="mi_admission_migration_status_rate",
        numerator="mi_admission",
        denominator="population",
        group_by=["migration_status"],
    ),
    # Hospital admissions for stroke
    Measure(
        id="stroke_admission_migration_status_rate",
        numerator="stroke_admission",
        denominator="population",
        group_by=["migration_status"],
    ),
    # Hospital admission for heart failure
    Measure(
        id="heart_failure_admission_migration_status_rate",
        numerator="heart_failure_admission",
        denominator="population",
        group_by=["migration_status"],
    ),
    # Hospital admission for vte
    Measure(
        id="vte_admission_migration_status_rate",
        numerator="vte_admission",
        denominator="population",
        group_by=["migration_status"],
    ),
    # Hospital admission for mental health
    Measure(
        id="mh_admission_migration_status_rate",
        numerator="mh_admission",
        denominator="population",
        group_by=["migration_status"],
    ),

    # Deaths for CVD outcomes
    Measure(
        id="mi_mortality_migration_status_rate",
        numerator="mi_mortality",
        denominator="population",
        group_by=["migration_status"],
    ),

    Measure(
        id="stroke_mortality_migration_status_rate",
        numerator="stroke_mortality",
        denominator="population",
        group_by=["migration_status"],
    ),

    Measure(
        id="vte_mortality_migration_status_rate",
        numerator="vte_mortality",
        denominator="population",
        group_by=["migration_status"],
    ),

    Measure(
        id="heart_failure_mortality_migration_status_rate",
        numerator="heart_failure_mortality",
        denominator="population",
        group_by=["migration_status"],
    ),

     # Hospital admission for mental health
    Measure(
        id="mh_mortality_migration_status_rate",
        numerator="mh_mortality",
        denominator="population",
        group_by=["migration_status"],
    ),
]