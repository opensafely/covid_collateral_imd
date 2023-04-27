# Creating script for common variables: age, gender, ethnicity & IMD
from cohortextractor import patients
from codelists import *

common_variables = dict(
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
    # Migration status
    migration_status=patients.with_these_clinical_events(
        migration_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence":0.2,},
    )
)