"""Evaluate a local parser adapter on held-out multilingual statements."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass

import torch
from peft import PeftModel
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig

from train_edge_parser import SYSTEM_PROMPT


@dataclass(frozen=True)
class Case:
    statement: str
    language: str
    concept: str
    facts: dict[str, str]


CASES = (
    Case(
        "I am 29 in Tirunelveli and need five lakh to open a bakery.",
        "en",
        "business",
        {"age": "29", "district": "Tirunelveli", "fundingNeed": "500000"},
    ),
    Case(
        "enakku 37 vayasu, Thanjavur la 4 acre irukku, drip irrigation venum",
        "tanglish",
        "agriculture",
        {"age": "37", "district": "Thanjavur", "landholding": "4 acres"},
    ),
    Case(
        "நான் வேலூரில் டிப்ளமோ படிக்கிறேன். எனக்கு கல்வி உதவித்தொகை வேண்டும்.",
        "ta",
        "education",
        {"studentStatus": "Yes"},
    ),
    Case(
        "என் தந்தைக்கு 72 வயது. முதியோர் ஓய்வூதியம் கிடைக்குமா?",
        "ta",
        "senior",
        {"age": "72"},
    ),
    Case(
        "veedu roof repair panna government help venum",
        "tanglish",
        "housing",
        {},
    ),
    Case(
        "I am not a student and want vocational job training.",
        "en",
        "employment",
        {"studentStatus": "No"},
    ),
    Case(
        "மருத்துவமனை சிகிச்சை செலவுக்கு உதவி வேண்டும்.",
        "ta",
        "health",
        {},
    ),
    Case(
        "நான் மாற்றுத்திறனாளி. உதவித்தொகை கிடைக்குமா?",
        "ta",
        "disability",
        {},
    ),
    Case(
        "en magal kalyanathukku government udhavi venum",
        "tanglish",
        "marriage",
        {},
    ),
    Case(
        "நான் மீனவர். புதிய படகு வாங்க மானியம் வேண்டும்.",
        "ta",
        "fisheries",
        {},
    ),
    Case(
        "I rear dairy cows and need a livestock subsidy.",
        "en",
        "livestock",
        {},
    ),
    Case(
        "I belong to the SC community and need financial support.",
        "en",
        "community",
        {"community": "Scheduled Caste"},
    ),
    Case(
        "ரேஷன் உணவு உதவி வேண்டும்.",
        "ta",
        "food",
        {},
    ),
)


def parse_json(value: str) -> dict:
    start, end = value.find("{"), value.rfind("}")
    if start < 0 or end <= start:
        raise ValueError("missing JSON object")
    return json.loads(value[start : end + 1])


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", default="Qwen/Qwen3-0.6B")
    parser.add_argument(
        "--adapter",
        default="artifacts/edge-parser/checkpoints/checkpoint-60",
    )
    parser.add_argument(
        "--merged",
        action="store_true",
        help="Evaluate --model directly instead of attaching a LoRA adapter.",
    )
    args = parser.parse_args()

    tokenizer = AutoTokenizer.from_pretrained(args.model)
    if args.merged:
        model = AutoModelForCausalLM.from_pretrained(
            args.model,
            torch_dtype=torch.float16,
            device_map="auto",
        )
    else:
        quantization = BitsAndBytesConfig(
            load_in_4bit=True,
            bnb_4bit_quant_type="nf4",
            bnb_4bit_compute_dtype=torch.bfloat16,
            bnb_4bit_use_double_quant=True,
        )
        base = AutoModelForCausalLM.from_pretrained(
            args.model,
            quantization_config=quantization,
            torch_dtype=torch.bfloat16,
            device_map="auto",
        )
        model = PeftModel.from_pretrained(base, args.adapter)
    model.eval()

    passed = 0
    for index, case in enumerate(CASES, start=1):
        prompt = tokenizer.apply_chat_template(
            [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": case.statement},
            ],
            tokenize=False,
            add_generation_prompt=True,
            enable_thinking=False,
        )
        inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
        with torch.inference_mode():
            output = model.generate(
                **inputs,
                max_new_tokens=192,
                do_sample=False,
                pad_token_id=tokenizer.eos_token_id,
            )
        generated = tokenizer.decode(
            output[0][inputs.input_ids.shape[1] :],
            skip_special_tokens=True,
        )
        ok = False
        try:
            decoded = parse_json(generated)
            actual_facts = {
                item.get("key"): str(item.get("value"))
                for item in decoded.get("facts", [])
                if isinstance(item, dict) and not item.get("negated", False)
            }
            language_ok = decoded.get("language") == case.language
            concept_ok = case.concept in decoded.get("concepts", [])
            facts_ok = all(actual_facts.get(key) == value for key, value in case.facts.items())
            ok = language_ok and concept_ok and facts_ok
        except (TypeError, ValueError, json.JSONDecodeError):
            decoded = generated
        passed += int(ok)
        print(json.dumps({"case": index, "ok": ok, "output": decoded}, ensure_ascii=False))

    print(f"RESULT {passed}/{len(CASES)}")
    raise SystemExit(0 if passed == len(CASES) else 1)


if __name__ == "__main__":
    main()
