import json
from pathlib import Path

from scheme_catalog import SchemeCatalog


def _record(
    scheme_id: str,
    code: str,
    name: str,
    summary: str,
    *,
    tamil_name: str | None = None,
) -> dict:
    return {
        "identity": {
            "id": scheme_id,
            "code": code,
            "name": name,
            "status": "active",
        },
        "content": {
            "overview": {"summary": summary},
            "eligibility": {"narrative": {"criteria": "Tamil Nadu residents"}},
            "benefits": {"summary": "Financial assistance"},
            "requiredDocuments": [{"name": "Identity proof", "mandatory": "required"}],
            "applicationProcess": {
                "modeText": "Online",
                "onlineUrl": "https://example.gov.in/apply",
            },
            "sources": [
                {
                    "title": "Official source",
                    "url": "https://example.gov.in/scheme",
                    "isCurrent": True,
                }
            ],
        },
        "localization": {
            "ta": {"name": tamil_name, "summary": None},
        },
        "search": {"keywords": ["assistance"], "aliases": [code]},
        "verification": {"isVerified": True, "statusText": "Verified"},
        "metadata": {"recordStatus": "published"},
    }


def _write_catalog(path: Path, records: list[dict]) -> None:
    path.write_text(json.dumps({"metadata": {}, "data": records}), encoding="utf-8")


def test_search_ranks_code_and_name_matches(tmp_path: Path) -> None:
    catalog_path = tmp_path / "schemes.json"
    _write_catalog(
        catalog_path,
        [
            _record("SCH1", "TN001", "Micro Manufacturing Subsidy", "For factories"),
            _record("SCH2", "TN002", "Student Scholarship", "For students"),
        ],
    )
    catalog = SchemeCatalog(catalog_path)

    assert catalog.search("TN001", limit=1)[0]["id"] == "SCH1"
    assert catalog.search("student scholarship", limit=1)[0]["id"] == "SCH2"


def test_search_supports_future_tamil_localization(tmp_path: Path) -> None:
    catalog_path = tmp_path / "schemes.json"
    _write_catalog(
        catalog_path,
        [
            _record(
                "SCH1",
                "TN001",
                "Farmer Support",
                "Support for farmers",
                tamil_name="விவசாயி உதவித் திட்டம்",
            )
        ],
    )

    result = SchemeCatalog(catalog_path).search("விவசாயி", limit=1)[0]

    assert result["id"] == "SCH1"
    assert result["localized"]["ta"]["name"] == "விவசாயி உதவித் திட்டம்"


def test_results_are_compact_and_source_grounded(tmp_path: Path) -> None:
    catalog_path = tmp_path / "schemes.json"
    _write_catalog(
        catalog_path,
        [_record("SCH1", "TN001", "Micro Manufacturing Subsidy", "For factories")],
    )

    result = SchemeCatalog(catalog_path).search("manufacturing", limit=1)[0]

    assert result["verification"]["is_verified"] is True
    assert 40 <= result["match_confidence"] <= 97
    assert result["application"]["url"] == "https://example.gov.in/apply"
    assert result["sources"] == [
        {"title": "Official source", "url": "https://example.gov.in/scheme"}
    ]
    assert result["required_documents"] == ["Identity proof"]


def test_production_catalog_contains_expected_scheme() -> None:
    path = Path(__file__).parents[1] / "data" / "scheme_catalog.json"
    catalog = SchemeCatalog(path)

    results = catalog.search("micro manufacturing capital subsidy", limit=1)

    assert catalog.count == 217
    assert results[0]["id"] == "SCH000001"
