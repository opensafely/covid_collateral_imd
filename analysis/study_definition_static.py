from cohortextractor import (
    StudyDefinition,
    Measure,
    patients,
)
from codelists import *

study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1980-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.05,
    },
    index_date="2019-03-01",
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
    #IMD
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
    # Urban-rural classification
    urban_rural=patients.address_as_of(
        "index_date",
        returning="rural_urban_classification",
        return_expectations={
        "rate": "universal",
        "category": 
            {"ratios": {
                "1": 0.1,
                "2": 0.1,
                "3": 0.1,
                "4": 0.1,
                "5": 0.1,
                "6": 0.1,
                "7": 0.2,
                "8": 0.2,
                }
            },
        },
    ),

    # Add migration status once have code list
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
)