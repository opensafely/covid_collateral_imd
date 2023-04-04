# Defining study population for people with either COPD or asthma for
# respiratory outcomes
from cohortextractor import (
    StudyDefinition,
    Measure,
    patients,
    codelist,
    combine_codelists
)
from codelists import *
#from common_variables import common_variables

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
        (stp != 'missing') AND
        (imd != 0) AND
        (household>=1 AND household<=15) AND
        (has_asthma OR has_copd)
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "index_date - 3 months", "index_date"
        ),
        died=patients.died_from_any_cause(
            on_or_before="index_date"
        ),      
        stp=patients.registered_practice_as_of(
            "index_date",
            returning="stp_code",
            return_expectations={
               "category": {"ratios": {"STP1": 0.3, "STP2": 0.2, "STP3": 0.5}},
            },
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
        
    # Hospital admission - COPD exacerbation
    resp_copd_exac=patients.satisfying(
        """copd_exacerbation_hospital OR 
        copd_hospital OR 
        (lrti_hospital AND copd_any)""",
        copd_exacerbation_hospital=patients.admitted_to_hospital(
            with_these_primary_diagnoses=copd_exacerbation_icd_codes,
            between=["index_date", "last_day_of_month(index_date)"],
            returning="binary_flag",
            return_expectations={"incidence": 0.1},
        ),
        copd_hospital=patients.admitted_to_hospital(
            with_these_primary_diagnoses=copd_icd_codes,
            between=["index_date", "last_day_of_month(index_date)"],
            returning="binary_flag",
            return_expectations={"incidence": 0.1},
            ),
        lrti_hospital=patients.admitted_to_hospital(
            with_these_primary_diagnoses=lrti_icd_codes,
            between=["index_date", "last_day_of_month(index_date)"],
            returning="binary_flag",
            return_expectations={"incidence": 0.1},
            ),
        copd_any=patients.admitted_to_hospital(
            with_these_diagnoses=copd_icd_codes,
            between=["index_date", "last_day_of_month(index_date)"],
            returning="binary_flag",
            return_expectations={"incidence": 0.1},
        ),
    ),
    resp_copd_exac_nolrti=patients.satisfying(
        """
        copd_exacerbation_hospital2 OR 
        copd_hospital2
        """,
        copd_exacerbation_hospital2=patients.admitted_to_hospital(
            with_these_primary_diagnoses=copd_exacerbation_icd_codes,
            between=["index_date", "last_day_of_month(index_date)"],
            returning="binary_flag",
            return_expectations={"incidence": 0.1},
        ),
        copd_hospital2=patients.admitted_to_hospital(
            with_these_primary_diagnoses=copd_icd_codes,
            between=["index_date", "last_day_of_month(index_date)"],
            returning="binary_flag",
            return_expectations={"incidence": 0.1},
            ),
    ),
    resp_asthma_exac=patients.admitted_to_hospital(
        with_these_primary_diagnoses=asthma_exacerbation_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    # No need to do primary and any code for hospital admissions because 
    # of the way asthma and copd exacerbation are defined
    resp_asthma_mortality=patients.with_these_codes_on_death_certificate(
        asthma_exacerbation_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        match_only_underlying_cause=True,
        returning="binary_flag",
    ),
    resp_copd_exac_mortality=patients.with_these_codes_on_death_certificate(
        copd_exacerbation_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        match_only_underlying_cause=True,
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
        ),
    resp_copd_diag_mortality=patients.with_these_codes_on_death_certificate(
        copd_icd_codes,
        between=["index_date", "last_day_of_month(index_date)"],
        match_only_underlying_cause=True,
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
        ),
    resp_copd_mortality=patients.satisfying(
        """resp_copd_exac_mortality OR 
        resp_copd_diag_mortality """,
        ),
    #**common_variables
)

# Generate measures

measures = [
    # Hospital admission for asthma in those with asthma
    # by IMD
    Measure(
        id="resp_asthma_exac_imd_rate",
        numerator="resp_asthma_exac",
        denominator="has_asthma",
        group_by=["imd"],
    ),
    # Hospital admission for copd in those with copd
    # by IMD
    Measure(
        id="resp_copd_exac_imd_rate",
        numerator="resp_copd_exac",
        denominator="has_copd",
        group_by=["imd"],
    ),
    Measure(
        id="resp_copd_exac_nolrti_imd_rate",
        numerator="resp_copd_exac_nolrti",
        denominator="has_copd",
        group_by=["imd"],
    ),
     Measure(
        id="resp_asthma_mortality_imd_rate",
        numerator="resp_asthma_mortality",
        denominator="has_asthma",
        group_by=["imd"],
    ),
    Measure(
        id="resp_copd_mortality_imd_rate",
        numerator="resp_copd_mortality",
        denominator="has_copd",
        group_by=["imd"],
    ),

    # by migration status
    Measure(
        id="resp_asthma_exac_migration_status_rate",
        numerator="resp_asthma_exac",
        denominator="has_asthma",
        group_by=["migration_status"],
    ),
    # Hospital admission for copd in those with copd
    # by migration_status
    Measure(
        id="resp_copd_exac_migration_status_rate",
        numerator="resp_copd_exac",
        denominator="has_copd",
        group_by=["migration_status"],
    ),
    Measure(
        id="resp_copd_exac_nolrti_migration_status_rate",
        numerator="resp_copd_exac_nolrti",
        denominator="has_copd",
        group_by=["migration_status"],
    ),
     Measure(
        id="resp_asthma_mortality_migration_status_rate",
        numerator="resp_asthma_mortality",
        denominator="has_asthma",
        group_by=["migration_status"],
    ),
    Measure(
        id="resp_copd_mortality_migration_status_rate",
        numerator="resp_copd_mortality",
        denominator="has_copd",
        group_by=["migration_status"],
    ),
]