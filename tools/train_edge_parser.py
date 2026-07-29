"""Task-specific LoRA training for the private scheme statement parser.

The dataset is generated from reviewed templates and contains no user data.
Run from the repository root:
  python tools/train_edge_parser.py --full-precision-base \
    --steps 70 --output artifacts/edge-parser-v4
"""

from __future__ import annotations

import argparse
import json
import random
import sys
from dataclasses import dataclass
from pathlib import Path

import torch
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
from torch.nn.utils.rnn import pad_sequence
from torch.utils.data import Dataset
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    BitsAndBytesConfig,
    Trainer,
    TrainingArguments,
)


SYSTEM_PROMPT = """Parse an Indian government-scheme request in English, Tamil, Tanglish, or mixed language. Return JSON only with language, concepts, and explicitly stated facts. Never guess. Valid concepts: agriculture, education, business, housing, health, employment, disability, senior, marriage, community, fisheries, livestock, food. Valid fact keys: age, state, district, annualIncome, gender, community, occupation, education, disability, maritalStatus, studentStatus, businessStage, businessSector, fundingNeed, landholding."""


def fact(key: str, value: str, confidence: float = 0.98) -> dict:
    return {
        "key": key,
        "value": value,
        "confidence": confidence,
        "negated": False,
    }


def result(language: str, concepts: list[str], facts: list[dict]) -> str:
    return json.dumps(
        {"language": language, "concepts": concepts, "facts": facts},
        ensure_ascii=False,
        separators=(",", ":"),
    )


def build_examples(seed: int = 7) -> list[tuple[str, str]]:
    rng = random.Random(seed)
    districts = ["Chennai", "Madurai", "Coimbatore", "Salem", "Trichy", "Erode"]
    sectors = ["Tailoring", "Retail", "Textiles", "Food processing", "Dairy"]
    courses = ["Engineering", "Nursing", "Arts", "Diploma", "ITI"]
    examples: list[tuple[str, str]] = []

    for index in range(180):
        age = 18 + index % 48
        district = districts[index % len(districts)]
        sector = sectors[index % len(sectors)]
        course = courses[index % len(courses)]
        amount_lakh = 1 + index % 9
        amount = str(amount_lakh * 100000)
        acres = 1 + index % 7
        language = ("en", "tanglish", "ta")[index % 3]

        if language == "en":
            business = (
                f"I am {age} years old and live in {district}. I want to start a "
                f"{sector.lower()} business and need {amount_lakh} lakh rupees."
            )
            farming = (
                f"I am a {age} year old farmer from {district} with {acres} acres. "
                "I need an irrigation subsidy."
            )
            education = (
                f"I am {age}, studying {course} in {district}, and need a scholarship."
            )
        elif language == "tanglish":
            business = (
                f"enakku {age} vayasu, {district} la {sector.lower()} kadai pudhusa "
                f"start panna {amount_lakh} latcham loan venum"
            )
            farming = (
                f"naan {age} vayasu {district} vivasayi, {acres} acre nilam irukku, "
                "pasana maaniyam venum"
            )
            education = (
                f"enakku {age} vayasu, {district} la {course} padikkiren, scholarship venum"
            )
        else:
            business = (
                f"எனக்கு {age} வயது. {district} மாவட்டத்தில் புதிதாக {sector} தொழில் "
                f"தொடங்க {amount_lakh} லட்சம் கடன் வேண்டும்."
            )
            farming = (
                f"நான் {district} மாவட்டத்தைச் சேர்ந்த {age} வயது விவசாயி. எனக்கு "
                f"{acres} ஏக்கர் நிலம் உள்ளது. பாசன மானியம் வேண்டும்."
            )
            education = (
                f"எனக்கு {age} வயது. {district} மாவட்டத்தில் {course} படிக்கிறேன். "
                "கல்வி உதவித்தொகை வேண்டும்."
            )

        examples.append(
            (
                business,
                result(
                    language,
                    ["business"],
                    [
                        fact("age", str(age)),
                        fact("district", district),
                        fact("businessStage", "New business", 0.94),
                        fact("businessSector", sector, 0.96),
                        fact("fundingNeed", amount, 0.97),
                    ],
                ),
            )
        )
        examples.append(
            (
                farming,
                result(
                    language,
                    ["agriculture"],
                    [
                        fact("age", str(age)),
                        fact("district", district),
                        fact("occupation", "Farmer", 0.97),
                        fact("landholding", f"{acres} acres", 0.97),
                    ],
                ),
            )
        )
        examples.append(
            (
                education,
                result(
                    language,
                    ["education"],
                    [
                        fact("age", str(age)),
                        fact("district", district),
                        fact("studentStatus", "Yes", 0.97),
                        fact("education", course, 0.95),
                    ],
                ),
            )
        )

    other_examples = [
        ("I am not a student. I need job training.", "en", ["employment"], [fact("studentStatus", "No")]),
        ("naan student illa, velai training venum", "tanglish", ["employment"], [fact("studentStatus", "No")]),
        ("நான் மாணவர் இல்லை. வேலை பயிற்சி வேண்டும்.", "ta", ["employment"], [fact("studentStatus", "No")]),
        ("My mother is 68 and needs an old age pension.", "en", ["senior"], [fact("age", "68")]),
        ("enga amma vayasu 68, muthiyor pension venum", "tanglish", ["senior"], [fact("age", "68")]),
        ("என் அம்மாவுக்கு 68 வயது. முதியோர் ஓய்வூதியம் வேண்டும்.", "ta", ["senior"], [fact("age", "68")]),
        ("I need assistance to repair my house.", "en", ["housing"], []),
        ("veedu repair panna udhavi venum", "tanglish", ["housing"], []),
        ("வீட்டை பழுது பார்க்க உதவி வேண்டும்.", "ta", ["housing"], []),
        ("I need support for hospital treatment.", "en", ["health"], []),
        ("hospital treatment ku udhavi venum", "tanglish", ["health"], []),
        ("மருத்துவ சிகிச்சைக்கு உதவி வேண்டும்.", "ta", ["health"], []),
        ("I have a disability and need an assistive device subsidy.", "en", ["disability"], [fact("disability", "Yes")]),
        ("enakku disability irukku, assistive device udhavi venum", "tanglish", ["disability"], [fact("disability", "Yes")]),
        ("நான் மாற்றுத்திறனாளி. உதவி உபகரண மானியம் வேண்டும்.", "ta", ["disability"], [fact("disability", "Yes")]),
        ("I need government assistance for my daughter's marriage.", "en", ["marriage"], []),
        ("en magal kalyanathukku government udhavi venum", "tanglish", ["marriage"], []),
        ("என் மகளின் திருமணத்திற்கு அரசு உதவி வேண்டும்.", "ta", ["marriage"], []),
        ("I am a fisherman and need a subsidy to buy a new boat.", "en", ["fisheries"], [fact("occupation", "Fisherman")]),
        ("naan meenavar, pudhu boat vaanga maaniyam venum", "tanglish", ["fisheries"], [fact("occupation", "Fisherman")]),
        ("நான் மீனவர். புதிய படகு வாங்க மானியம் வேண்டும்.", "ta", ["fisheries"], [fact("occupation", "Fisherman")]),
        ("I rear dairy cows and need a livestock subsidy.", "en", ["livestock"], [fact("occupation", "Dairy farmer")]),
        ("maadu valarkiren, dairy subsidy venum", "tanglish", ["livestock"], [fact("occupation", "Dairy farmer")]),
        ("நான் கறவை மாடுகள் வளர்க்கிறேன். கால்நடை மானியம் வேண்டும்.", "ta", ["livestock"], [fact("occupation", "Dairy farmer")]),
        ("I belong to the Scheduled Caste community and need financial support.", "en", ["community"], [fact("community", "Scheduled Caste")]),
        ("naan SC community, financial help venum", "tanglish", ["community"], [fact("community", "Scheduled Caste")]),
        ("நான் பட்டியல் சாதியைச் சேர்ந்தவர். நிதி உதவி வேண்டும்.", "ta", ["community"], [fact("community", "Scheduled Caste")]),
        ("I need subsidized ration food for my family.", "en", ["food"], []),
        ("family ku ration food udhavi venum", "tanglish", ["food"], []),
        ("என் குடும்பத்திற்கு ரேஷன் உணவு உதவி வேண்டும்.", "ta", ["food"], []),
        ("Which food security or ration card scheme can help me?", "en", ["food"], []),
        ("ration card scheme um food subsidy um venum", "tanglish", ["food"], []),
        ("ரேஷன் உணவு உதவி வேண்டும்.", "ta", ["food"], []),
        ("I need a nutrition scheme for my children.", "en", ["food"], []),
        ("kuzhandhaigalukku nutrition scheme venum", "tanglish", ["food"], []),
        ("குழந்தைகளுக்கு ஊட்டச்சத்து திட்டம் வேண்டும்.", "ta", ["food"], []),
        ("I am a woman in Tamil Nadu with annual income 180000 and want a tailoring business loan.", "en", ["business"], [fact("gender", "Female"), fact("state", "Tamil Nadu"), fact("annualIncome", "180000"), fact("businessSector", "Tailoring")]),
        ("naan Tamil Nadu pen, varusha income 2 latcham, tailoring business loan venum", "tanglish", ["business"], [fact("gender", "Female"), fact("state", "Tamil Nadu"), fact("annualIncome", "200000"), fact("businessSector", "Tailoring")]),
        ("நான் தமிழ்நாட்டைச் சேர்ந்த பெண். ஆண்டு வருமானம் 150000. தையல் தொழில் கடன் வேண்டும்.", "ta", ["business"], [fact("gender", "Female"), fact("state", "Tamil Nadu"), fact("annualIncome", "150000"), fact("businessSector", "Tailoring")]),
        ("What is the weather tomorrow?", "en", [], []),
        ("naalaikku weather eppadi irukkum", "tanglish", [], []),
        ("நாளை வானிலை எப்படி இருக்கும்?", "ta", [], []),
    ]
    for _ in range(8):
        for statement, language, concepts, facts in other_examples:
            examples.append((statement, result(language, concepts, facts)))

    rng.shuffle(examples)
    return examples


class ParserDataset(Dataset):
    def __init__(self, tokenizer, examples: list[tuple[str, str]], max_length: int):
        self.items: list[dict[str, torch.Tensor]] = []
        for statement, answer in examples:
            prompt = tokenizer.apply_chat_template(
                [
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": statement},
                ],
                tokenize=False,
                add_generation_prompt=True,
                enable_thinking=False,
            )
            prompt_ids = tokenizer(prompt, add_special_tokens=False).input_ids
            answer_ids = tokenizer(
                answer + tokenizer.eos_token,
                add_special_tokens=False,
            ).input_ids
            input_ids = (prompt_ids + answer_ids)[:max_length]
            labels = ([-100] * len(prompt_ids) + answer_ids)[:max_length]
            self.items.append(
                {
                    "input_ids": torch.tensor(input_ids, dtype=torch.long),
                    "labels": torch.tensor(labels, dtype=torch.long),
                }
            )

    def __len__(self) -> int:
        return len(self.items)

    def __getitem__(self, index: int) -> dict[str, torch.Tensor]:
        return self.items[index]


@dataclass
class Collator:
    pad_token_id: int

    def __call__(self, batch: list[dict[str, torch.Tensor]]) -> dict[str, torch.Tensor]:
        inputs = pad_sequence(
            [item["input_ids"] for item in batch],
            batch_first=True,
            padding_value=self.pad_token_id,
        )
        labels = pad_sequence(
            [item["labels"] for item in batch],
            batch_first=True,
            padding_value=-100,
        )
        return {
            "input_ids": inputs,
            "attention_mask": inputs.ne(self.pad_token_id),
            "labels": labels,
        }


def main() -> None:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", default="Qwen/Qwen3-0.6B")
    parser.add_argument("--output", default="artifacts/edge-parser")
    parser.add_argument("--steps", type=int, default=180)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--full-precision-base",
        action="store_true",
        help="Train LoRA on BF16 weights so the merged deployment model is exact.",
    )
    args = parser.parse_args()

    examples = build_examples()
    print(f"Generated {len(examples)} private synthetic examples")
    if args.dry_run:
        for item in examples[:3]:
            print(json.dumps(item, ensure_ascii=False))
        return

    if not torch.cuda.is_available():
        raise RuntimeError("CUDA is required for this training recipe")
    tokenizer = AutoTokenizer.from_pretrained(args.model)
    tokenizer.pad_token = tokenizer.eos_token
    if args.full_precision_base:
        model = AutoModelForCausalLM.from_pretrained(
            args.model,
            torch_dtype=torch.bfloat16,
            device_map="auto",
        )
        model.gradient_checkpointing_enable()
        model.enable_input_require_grads()
        model.config.use_cache = False
    else:
        quantization = BitsAndBytesConfig(
            load_in_4bit=True,
            bnb_4bit_quant_type="nf4",
            bnb_4bit_compute_dtype=torch.bfloat16,
            bnb_4bit_use_double_quant=True,
        )
        model = AutoModelForCausalLM.from_pretrained(
            args.model,
            quantization_config=quantization,
            torch_dtype=torch.bfloat16,
            device_map="auto",
        )
        model = prepare_model_for_kbit_training(
            model,
            use_gradient_checkpointing=True,
        )
    model = get_peft_model(
        model,
        LoraConfig(
            r=16,
            lora_alpha=32,
            lora_dropout=0.05,
            bias="none",
            task_type="CAUSAL_LM",
            target_modules="all-linear",
        ),
    )
    dataset = ParserDataset(tokenizer, examples, max_length=768)
    output = Path(args.output)
    trainer = Trainer(
        model=model,
        train_dataset=dataset,
        data_collator=Collator(tokenizer.pad_token_id),
        args=TrainingArguments(
            output_dir=str(output / "checkpoints"),
            max_steps=args.steps,
            per_device_train_batch_size=2,
            gradient_accumulation_steps=8,
            learning_rate=2e-4,
            warmup_ratio=0.05,
            logging_steps=10,
            save_steps=60,
            save_total_limit=2,
            bf16=True,
            optim="paged_adamw_8bit",
            report_to="none",
            remove_unused_columns=False,
            dataloader_num_workers=0,
        ),
    )
    model.print_trainable_parameters()
    trainer.train()
    adapter_dir = output / "adapter"
    trainer.model.save_pretrained(adapter_dir)
    tokenizer.save_pretrained(adapter_dir)

    merged = trainer.model.merge_and_unload()
    merged_dir = output / "merged"
    merged.save_pretrained(merged_dir, safe_serialization=True)
    tokenizer.save_pretrained(merged_dir)
    print(f"Saved merged model to {merged_dir}")


if __name__ == "__main__":
    main()
