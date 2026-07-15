# Supabase Edge Functions API Documentation

This API documentation serves as a guide for the Flutter frontend team to integrate with the dynamic semantic search and scheme recommendation backend engine.

---

## 1. Semantic Search Scheme API
Performs semantic similarity search over all available government schemes using text embeddings.

* **Endpoint**: `POST /functions/v1/search`
* **Headers**:
  * `Content-Type: application/json`
  * `Authorization: Bearer <ANON_KEY>`
* **Request Body**:
  ```json
  {
    "query": "subsidy scheme for women starting manufacturing units in Chennai"
  }
  ```
* **Response (Success 200)**:
  ```json
  [
    {
      "scheme_id": "e5f6a7b8-9c0d-1e2f-3a4b-5c6d7e8f9a0b",
      "scheme_code": "NEEDS",
      "scheme_name": "New Entrepreneur-cum-Enterprise Development Scheme (NEEDS)",
      "similarity_score": 0.8924,
      "overview": "The Government of Tamil Nadu has introduced the NEEDS scheme...",
      "issuing_department": "Department of Industries and Commerce"
    }
  ]
  ```

---

## 2. Recommendation Engine API
Computes matching and dynamic eligibility rules for a specific startup profile.

* **Endpoint**: `POST /functions/v1/recommend`
* **Headers**:
  * `Content-Type: application/json`
  * `Authorization: Bearer <USER_JWT>`
* **Request Body**:
  ```json
  {
    "startup_profile_id": "c4d0a1b2-3c4d-5e6f-7a8b-9c0d1e2f3a4b"
  }
  ```
* **Response (Success 200)**:
  ```json
  [
    {
      "scheme_id": "e5f6a7b8-9c0d-1e2f-3a4b-5c6d7e8f9a0b",
      "scheme_name": "New Entrepreneur-cum-Enterprise Development Scheme (NEEDS)",
      "match_score": 100.00,
      "matched_rules": [
        {
          "rule_id": "f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
          "parameter": "state",
          "description": "Business must be situated in Tamil Nadu."
        },
        {
          "rule_id": "f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6d",
          "parameter": "is_first_generation_entrepreneur",
          "description": "Applicant must be a first-generation entrepreneur."
        }
      ],
      "failed_rules": [],
      "recommendation_reason": "Your startup profile perfectly matches all eligibility criteria for this scheme."
    }
  ]
  ```

---

## 3. Schemes API (Subrouting)

### A. Fetch Scheme Details
* **Endpoint**: `GET /functions/v1/schemes-api/:scheme_id`
* **Headers**:
  * `Authorization: Bearer <ANON_KEY>`
* **Response (Success 200)**:
  ```json
  {
    "id": "e5f6a7b8-9c0d-1e2f-3a4b-5c6d7e8f9a0b",
    "scheme_code": "NEEDS",
    "scheme_name": "New Entrepreneur-cum-Enterprise Development Scheme (NEEDS)",
    "government_level": "State",
    "issuing_department": "Department of Industries and Commerce",
    "state": "Tamil Nadu",
    "subsidy_percentage": 25.00,
    "max_funding_amount": 50000000.00,
    "minimum_funding_amount": 500000.00
  }
  ```

### B. Fetch Required Scheme Documents
* **Endpoint**: `GET /functions/v1/schemes-api/:scheme_id/documents`
* **Headers**:
  * `Authorization: Bearer <ANON_KEY>`
* **Response (Success 200)**:
  ```json
  [
    {
      "is_mandatory": true,
      "remarks": "Must have at least a Degree, Diploma, ITI, or Vocational Training.",
      "document_types": {
        "id": "d2020202-2020-2020-2020-202020202020",
        "document_name": "Degree or Diploma Certificate",
        "description": "Proof of educational qualification.",
        "issuing_authority": "Recognized University / Board",
        "estimated_processing_days": 1
      }
    }
  ]
  ```

### C. Fetch Linked Support Services
* **Endpoint**: `GET /functions/v1/schemes-api/:scheme_id/services`
* **Headers**:
  * `Authorization: Bearer <ANON_KEY>`
* **Response (Success 200)**:
  ```json
  [
    {
      "is_required": true,
      "remarks": "Completion certificate of EDP training is mandatory for loan disbursement.",
      "services": {
        "id": "s1010101-1010-1010-1010-101010101010",
        "service_name": "Entrepreneurship Development Programme (EDP) Training",
        "category": "Training",
        "description": "Mandatory 15-day training program conducted by EDII Tamil Nadu."
      }
    }
  ]
  ```
