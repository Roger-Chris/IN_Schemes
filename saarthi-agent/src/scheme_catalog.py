"""Search and compact rendering for the bundled government-scheme catalog."""

from __future__ import annotations

import json
import math
import re
import unicodedata
from pathlib import Path
from typing import Any

DEFAULT_CATALOG_PATH = (
    Path(__file__).resolve().parents[1] / "data" / "scheme_catalog.json"
)


def _normalize(value: str) -> str:
    value = unicodedata.normalize("NFKC", value).casefold()
    return " ".join(re.findall(r"[^\W_]+", value, flags=re.UNICODE))


def _string_values(value: Any):
    if isinstance(value, str):
        if value.strip():
            yield value
    elif isinstance(value, dict):
        for child in value.values():
            yield from _string_values(child)
    elif isinstance(value, list):
        for child in value:
            yield from _string_values(child)


class SchemeCatalog:
    """Load a catalog once and return small, source-grounded search results."""

    def __init__(self, path: Path | str = DEFAULT_CATALOG_PATH) -> None:
        self.path = Path(path)
        payload = json.loads(self.path.read_text(encoding="utf-8"))
        records = payload.get("data")
        if not isinstance(records, list):
            raise ValueError("Scheme catalog must contain a top-level data array")

        self._records = [record for record in records if self._is_available(record)]
        self._search_rows = [self._build_search_row(record) for record in self._records]

    @property
    def count(self) -> int:
        return len(self._records)

    @staticmethod
    def _is_available(record: dict[str, Any]) -> bool:
        metadata = record.get("metadata", {})
        return metadata.get("recordStatus") in {
            None,
            "published",
        }

    @staticmethod
    def _build_search_row(record: dict[str, Any]) -> dict[str, Any]:
        identity = record.get("identity", {})
        searchable_sections = {
            "identity": identity,
            "localization": record.get("localization", {}),
            "search": record.get("search", {}),
            "classification": record.get("content", {}).get("classification", {}),
            "overview": record.get("content", {}).get("overview", {}),
            "targetBeneficiaries": record.get("content", {}).get(
                "targetBeneficiaries", {}
            ),
            "eligibility": record.get("content", {}).get("eligibility", {}),
            "benefits": record.get("content", {}).get("benefits", {}),
        }
        names = [identity.get("name", ""), identity.get("code", "")]
        names.extend(
            localized.get("name", "")
            for localized in record.get("localization", {}).values()
            if isinstance(localized, dict)
        )
        return {
            "record": record,
            "names": [_normalize(name) for name in names if name],
            "text": _normalize(" ".join(_string_values(searchable_sections))),
        }

    def search(self, query: str, *, limit: int = 3) -> list[dict[str, Any]]:
        normalized_query = _normalize(query)
        if not normalized_query:
            return []

        limit = max(1, min(limit, 5))
        tokens = normalized_query.split()
        ranked: list[tuple[int, str, dict[str, Any]]] = []

        for row in self._search_rows:
            record = row["record"]
            identity = record.get("identity", {})
            code = _normalize(str(identity.get("code", "")))
            score = 0

            if normalized_query == code:
                score += 1_000
            if normalized_query in row["names"]:
                score += 800
            elif any(normalized_query in name for name in row["names"]):
                score += 300
            if normalized_query in row["text"]:
                score += 120

            for token in tokens:
                if any(token in name for name in row["names"]):
                    score += 40
                if token in row["text"]:
                    score += 8

            if record.get("verification", {}).get("isVerified"):
                score += 5
            if score > 5:
                ranked.append((score, str(identity.get("id", "")), record))

        ranked.sort(key=lambda item: (-item[0], item[1]))
        return [
            self._compact(record, match_confidence=self._match_confidence(score))
            for score, _, record in ranked[:limit]
        ]

    @staticmethod
    def _match_confidence(score: int) -> int:
        """Map deterministic retrieval strength to a bounded UI percentage.

        This is relevance confidence, not a promise of scheme eligibility.
        """
        confidence = round((1 - math.exp(-score / 60)) * 100)
        return max(40, min(confidence, 97))

    @staticmethod
    def _compact(record: dict[str, Any], *, match_confidence: int) -> dict[str, Any]:
        identity = record.get("identity", {})
        content = record.get("content", {})
        eligibility = content.get("eligibility", {}).get("narrative", {})
        application = content.get("applicationProcess", {})
        verification = record.get("verification", {})

        localized = {
            language: {
                key: value
                for key, value in values.items()
                if key in {"name", "summary", "eligibilityText", "benefitsText"}
                and value
            }
            for language, values in record.get("localization", {}).items()
            if isinstance(values, dict) and any(values.values())
        }

        sources = [
            {"title": source.get("title"), "url": source.get("url")}
            for source in content.get("sources", [])
            if source.get("url") and source.get("isCurrent", True)
        ][:3]

        required_documents = [
            document.get("name")
            for document in content.get("requiredDocuments", [])
            if document.get("name") and document.get("mandatory") != "optional"
        ]

        return {
            "id": identity.get("id"),
            "code": identity.get("code"),
            "name": identity.get("name"),
            "match_confidence": match_confidence,
            "scheme_status": identity.get("status"),
            "summary": content.get("overview", {}).get("summary"),
            "eligibility": eligibility.get("verifiedCriteria")
            or eligibility.get("criteria"),
            "benefits": content.get("benefits", {}).get("summary"),
            "required_documents": required_documents,
            "application": {
                "mode": application.get("modeText") or application.get("mode"),
                "url": application.get("onlineUrl"),
                "fee": application.get("applicationFeeText"),
            },
            "localized": localized,
            "verification": {
                "is_verified": bool(verification.get("isVerified")),
                "status": verification.get("statusText") or verification.get("status"),
                "confidence": verification.get("confidence"),
            },
            "sources": sources,
        }
