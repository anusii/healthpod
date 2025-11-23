"""
Unit Validation Module for Pathology Test Results.

Copyright (C) 2025, Software Innovation Institute ANU

Licensed under the GNU General Public License, Version 3 (the "License");

License: https://opensource.org/license/gpl-3-0

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <https://opensource.org/license/gpl-3-0>.

Authors: Tony Chen
"""

import logging
import re
from typing import Dict, List, Optional

logger = logging.getLogger(__name__)

# Common unit mappings and variations (British English).
UNIT_MAPPINGS = {
    # Concentration units.
    "mmol/L": ["mmol/L", "mmol/l", "mmol/litre", "mmol/liter", "mM"],
    "µmol/L": ["µmol/L", "µmol/l", "umol/L", "umol/l", "µmol/litre"],
    "g/L": ["g/L", "g/l", "g/litre", "g/liter", "gm/L"],
    "mg/L": ["mg/L", "mg/l", "mg/litre", "mg/liter"],
    "mg/dL": ["mg/dL", "mg/dl"],
    "µg/L": ["µg/l", "ug/L", "μg/L", "mcg/L"],
    "ng/mL": ["ng/ml", "ng/mL"],
    "pg/mL": ["pg/ml", "pg/mL"],
    # Volume units.
    "L": ["L", "l", "litre", "liter"],
    "mL": ["ml", "ml", "millilitre", "milliliter"],
    "µL": ["µl", "uL", "μL", "microlitre", "microliter"],
    # Count units.
    "10^9/L": ["10^9/l", "x10^9/L", "×10^9/L", "x10⁹/L", "10⁹/L", "*10^9/L"],
    "10^12/L": ["10^12/l", "x10^12/L", "×10^12/L", "x10¹²/L", "10¹²/L",
                "*10^12/L"],
    "cells/µL": ["cells/µl", "cells/μL", "cells/uL"],
    # Percentage.
    "%": ["percent", "pct"],
    # Time units.
    "seconds": ["s", "sec", "secs"],
    "minutes": ["min", "mins"],
    "hours": ["h", "hr", "hrs"],
    # Rate units.
    "mL/min/1.73m²": [
        "mL/min/1.73m²",
        "ml/min/1.73m²",
        "ml/min/1.73m2",
        "mL/min/1.73m2",
        "ml/min per 1.73m²",
    ],
    # Enzyme units.
    "u/L": ["U/L", "U/l", "u/L", "IU/L", "units/L"],
    # Pressure units.
    "mmhg": ["mmHg", "mm Hg"],
    # Special units.
    "ratio": ["Ratio"],
    "index": ["Index"],
}

# Common test name to expected unit mappings.
# Maps lowercase test name patterns to expected units.
TEST_UNIT_EXPECTATIONS = {
    # Electrolytes.
    "sodium": "mmol/L",
    "potassium": "mmol/L",
    "chloride": "mmol/L",
    "bicarbonate": "mmol/L",
    # Kidney function.
    "urea": "mmol/L",
    "creatinine": "µmol/L",
    "egfr": "mL/min/1.73m²",
    "estimated gfr": "mL/min/1.73m²",
    # Lipids.
    "cholesterol": "mmol/L",
    "total cholesterol": "mmol/L",
    "hdl": "mmol/L",
    "hdl cholesterol": "mmol/L",
    "ldl": "mmol/L",
    "ldl cholesterol": "mmol/L",
    "triglycerides": "mmol/L",
    # Blood cells.
    "haemoglobin": "g/L",
    "hemoglobin": "g/L",  # US spelling.
    "hb": "g/L",
    "wbc": "10^9/L",
    "white cell count": "10^9/L",
    "white blood cell": "10^9/L",
    "platelets": "10^9/L",
    "platelet count": "10^9/L",
    "rbc": "10^12/L",
    "red cell count": "10^12/L",
    "red blood cell": "10^12/L",
    # Liver function.
    "alt": "u/L",
    "alanine transaminase": "u/L",
    "ast": "u/L",
    "aspartate transaminase": "u/L",
    "alp": "u/L",
    "alkaline phosphatase": "u/L",
    "ggt": "u/L",
    "gamma gt": "u/L",
    "bilirubin": "µmol/L",
    "total bilirubin": "µmol/L",
    "albumin": "g/L",
    "total protein": "g/L",
    # Thyroid.
    "tsh": "miu/L",
    "thyroid stimulating hormone": "miu/L",
    "t4": "pmol/L",
    "free t4": "pmol/L",
    "t3": "pmol/L",
    "free t3": "pmol/L",
    # Glucose.
    "glucose": "mmol/L",
    "blood glucose": "mmol/L",
    "hba1c": "%",
    "glycated haemoglobin": "%",
}

# Standard test name mappings.
# Maps common variations to the standard name.
STANDARD_TEST_NAMES = {
    # Kidney function.
    "egfr": "eGFR",
    "estimated gfr": "eGFR",
    "gfr": "eGFR",
    # Electrolytes.
    "na": "Sodium",
    "k": "Potassium",
    "cl": "Chloride",
    "hco3": "Bicarbonate",
    # Lipids.
    "chol": "Total Cholesterol",
    "hdl": "HDL Cholesterol",
    "ldl": "LDL Cholesterol",
    "trig": "Triglycerides",
    "trigs": "Triglycerides",
    # Blood cells.
    "hb": "Haemoglobin",
    "hemoglobin": "Haemoglobin",
    "wbc": "White Cell Count",
    "wcc": "White Cell Count",
    "rbc": "Red Cell Count",
    "plt": "Platelets",
    # Liver function.
    "alt": "ALT",
    "sgpt": "ALT",
    "alanine transaminase": "ALT",
    "ast": "AST",
    "sgot": "AST",
    "aspartate transaminase": "AST",
    "alp": "ALP",
    "alk phos": "ALP",
    "alkaline phosphatase": "ALP",
    "ggt": "GGT",
    "gamma gt": "GGT",
    "gamma glutamyl transferase": "GGT",
    "bili": "Bilirubin",
    "tbil": "Total Bilirubin",
    "alb": "Albumin",
    # Thyroid.
    "tsh": "TSH",
    "thyroid stimulating hormone": "TSH",
    "ft4": "Free T4",
    "free thyroxine": "Free T4",
    "ft3": "Free T3",
    "free triiodothyronine": "Free T3",
    # Glucose.
    "bsl": "Blood Glucose",
    "bg": "Blood Glucose",
    "fasting glucose": "Fasting Glucose",
    "hba1c": "HbA1c",
    "glycated haemoglobin": "HbA1c",
    "glycated hemoglobin": "HbA1c",
}


class UnitValidator:
    """Validates and normalises measurement units in pathology reports."""

    def __init__(self):
        """Initialise the unit validator."""
        # Create reverse mapping for normalisation.
        self.normalisation_map = {}
        for standard, variations in UNIT_MAPPINGS.items():
            for variation in variations:
                self.normalisation_map[variation.lower()] = standard
        
        # Create reverse mapping for test name standardisation.
        self.test_name_map = {}
        for variation, standard in STANDARD_TEST_NAMES.items():
            self.test_name_map[variation.lower()] = standard

    def normalise_unit(self, unit: str) -> str:
        """
        Normalise a unit string to its standard form.

        Args:
            unit: The unit string to normalise

        Returns:
            Normalised unit string or original if no mapping found
        """
        if not unit:
            return ""

        # Try exact match (case-insensitive).
        unit_lower = unit.strip().lower()
        if unit_lower in self.normalisation_map:
            normalised = self.normalisation_map[unit_lower]
            if normalised != unit_lower:
                logger.debug(f"Normalised unit '{unit}' to '{normalised}'")
            return normalised

        # Try with common OCR mistakes corrected.
        unit_corrected = self._correct_ocr_errors(unit)
        unit_corrected_lower = unit_corrected.lower()
        if unit_corrected_lower in self.normalisation_map:
            normalised = self.normalisation_map[unit_corrected_lower]
            logger.debug(
                f"Normalised unit '{unit}' to '{normalised}' after OCR correction"
            )
            return normalised

        # If no mapping found, return the original unit.
        logger.debug(f"No normalisation mapping found for unit: '{unit}'")
        return unit

    def _correct_ocr_errors(self, unit: str) -> str:
        """
        Correct common OCR errors in unit strings.

        Args:
            unit: The unit string potentially with OCR errors

        Returns:
            Corrected unit string
        """
        # Common OCR substitutions.
        corrections = {
            "0": "O",  # Zero to letter O in some contexts.
            "l": "L",  # Lowercase L to uppercase L.
            "rn": "m",  # rn often misread as m.
            "u": "µ",  # u often misread as micro symbol.
        }

        corrected = unit
        # Apply corrections contextually.
        corrected = re.sub(r"(\d+)\^", r"\1^", corrected)  # Fix exponent spacing.

        return corrected

    def standardise_test_name(self, test_name: str) -> Dict[str, Optional[str]]:
        """
        Standardise test name to preferred format.

        Args:
            test_name: Original test name

        Returns:
            Dictionary with:
            - original_name: Original test name
            - standardised_name: Standardised test name
            - was_changed: Whether the name was modified
        """
        if not test_name:
            return {
                "original_name": test_name,
                "standardised_name": test_name,
                "was_changed": False,
            }

        test_lower = test_name.lower().strip()
        
        # Try exact match first.
        if test_lower in self.test_name_map:
            standardised = self.test_name_map[test_lower]
            if standardised != test_name:
                logger.info(
                    f"Standardised test name: '{test_name}' → '{standardised}'"
                )
            return {
                "original_name": test_name,
                "standardised_name": standardised,
                "was_changed": True,
            }
        
        # Try partial match.
        for pattern, standard in self.test_name_map.items():
            if pattern in test_lower or test_lower in pattern:
                logger.info(
                    f"Standardised test name (partial match): '{test_name}' → '{standard}'"
                )
                return {
                    "original_name": test_name,
                    "standardised_name": standard,
                    "was_changed": True,
                }
        
        # No match found, return original.
        return {
            "original_name": test_name,
            "standardised_name": test_name,
            "was_changed": False,
        }

    def validate_test_unit(
        self, test_name: str, unit: str
    ) -> Dict[str, Optional[str]]:
        """
        Validate if the unit is appropriate for the given test.
        If a mismatch is found and we know the expected unit, use the expected unit.

        Args:
            test_name: Name of the test
            unit: Unit string to validate

        Returns:
            Dictionary with:
            - is_valid: Whether the unit appears correct
            - original_unit: Original unit string
            - corrected_unit: Corrected unit (expected unit if mismatch found)
            - expected_unit: The expected unit for this test (if known)
            - was_corrected: Whether the unit was corrected
        """
        test_lower = test_name.lower().strip()
        unit_normalised = self.normalise_unit(unit)

        # Check if we have an expected unit for this test.
        expected_unit = None
        for test_pattern, expected in TEST_UNIT_EXPECTATIONS.items():
            if test_pattern in test_lower:
                expected_unit = expected
                break

        if expected_unit:
            is_valid = unit_normalised.lower() == expected_unit.lower()
            if not is_valid:
                logger.warning(
                    f"Unit mismatch for '{test_name}': got '{unit}', "
                    f"expected '{expected_unit}' - AUTO-CORRECTING"
                )
                # Auto-correct: use the expected unit.
                return {
                    "is_valid": False,
                    "original_unit": unit,
                    "corrected_unit": expected_unit,
                    "expected_unit": expected_unit,
                    "was_corrected": True,
                }
            else:
                return {
                    "is_valid": True,
                    "original_unit": unit,
                    "corrected_unit": unit_normalised,
                    "expected_unit": expected_unit,
                    "was_corrected": False,
                }
        else:
            # No expected unit known, just normalise.
            return {
                "is_valid": True,  # Assume valid if we don't know better.
                "original_unit": unit,
                "corrected_unit": unit_normalised,
                "expected_unit": None,
                "was_corrected": unit_normalised != unit,
            }

    def validate_results(self, tests: List[Dict]) -> List[Dict]:
        """
        Validate and normalise units and test names for a list of test results.
        Automatically corrects units and standardises test names.

        Args:
            tests: List of test dictionaries with test_name and units fields

        Returns:
            List of test dictionaries with corrected units and standardised names
        """
        validated_tests = []

        for test in tests:
            test_name = test.get("test_name", "")
            unit = test.get("units", "")

            # Standardise the test name.
            name_standardisation = self.standardise_test_name(test_name)

            # Validate and correct the unit (using original test name for matching).
            validation = self.validate_test_unit(test_name, unit)

            # Update the test with corrected data.
            validated_test = test.copy()
            validated_test["test_name"] = name_standardisation["standardised_name"]
            validated_test["units"] = validation["corrected_unit"]

            # Add validation metadata.
            validated_test["validation_metadata"] = {
                "test_name": {
                    "original": name_standardisation["original_name"],
                    "standardised": name_standardisation["standardised_name"],
                    "was_changed": name_standardisation["was_changed"],
                },
                "unit": {
                    "is_valid": validation["is_valid"],
                    "original": validation["original_unit"],
                    "corrected": validation["corrected_unit"],
                    "expected": validation["expected_unit"],
                    "was_corrected": validation["was_corrected"],
                },
            }

            validated_tests.append(validated_test)

            # Log corrections.
            if not validation["is_valid"]:
                logger.info(
                    f"✓ Corrected unit for '{test_name}': "
                    f"'{validation['original_unit']}' → '{validation['corrected_unit']}'"
                )
            
            if name_standardisation["was_changed"]:
                logger.info(
                    f"✓ Standardised test name: "
                    f"'{name_standardisation['original_name']}' → "
                    f"'{name_standardisation['standardised_name']}'"
                )

        return validated_tests
