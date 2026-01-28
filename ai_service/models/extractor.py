"""
Item Extractor - Uses rule-based extraction and optional LLM enhancement
Supports local models for $0 inference
"""

import os
import re
import json
from typing import Dict, Any, Optional, List

import torch
from transformers import AutoTokenizer, AutoModelForCausalLM

from utils.prompts import EXTRACTION_PROMPTS, CATEGORIES


class ItemExtractor:
    def __init__(self, device: str = "cuda"):
        self.device = device
        self.llm_mode = os.getenv("LLM_MODEL", "local")
        self.model = None
        self.tokenizer = None
        
        if self.llm_mode == "local":
            try:
                self._init_local_model()
            except Exception as e:
                print(f"Warning: Failed to load local LLM: {e}")
                print("Warning: Falling back to rule-based extraction")
        else:
            print(f"Warning: LLM mode '{self.llm_mode}' - using rule-based extraction")
    
    def _init_local_model(self):
        model_name = os.getenv("LOCAL_LLM", "microsoft/phi-2")
        cache_dir = os.getenv("MODEL_CACHE_DIR", "./models")
        print(f"Loading local LLM: {model_name}")
        
        self.tokenizer = AutoTokenizer.from_pretrained(
            model_name, cache_dir=cache_dir, trust_remote_code=True,
        )
        if self.tokenizer.pad_token is None:
            self.tokenizer.pad_token = self.tokenizer.eos_token
        
        self.model = AutoModelForCausalLM.from_pretrained(
            model_name, cache_dir=cache_dir,
            torch_dtype=torch.float16 if self.device == "cuda" else torch.float32,
            device_map="auto" if self.device == "cuda" else None,
            trust_remote_code=True,
        )
        if self.device != "cuda":
            self.model = self.model.to(self.device)
        self.model.eval()
        print("Local LLM loaded!")
    
    async def extract_from_text(self, text: str, post_type: Optional[str] = None) -> Dict[str, Any]:
        result = self._rule_based_extraction(text)
        if self.model is not None:
            llm_result = await self._llm_extraction(text, post_type)
            result = self._merge_results(result, llm_result)
        
        filled_fields = sum(1 for v in [result.get("title"), result.get("category"), 
                                        result.get("attributes"), result.get("location"), 
                                        result.get("date")] if v)
        confidence = min(filled_fields / 5, 1.0)
        detected_post_type = post_type.upper() if post_type else self._detect_post_type(text)
        tags = self._generate_tags(result)
        
        return {
            "post_type": detected_post_type,
            "category": result.get("category", "other"),
            "title": result.get("title", ""),
            "clean_description": self._clean_description(text),
            "description": result.get("description", text[:500]),
            "item_attributes": result.get("attributes", {}),
            "attributes": result.get("attributes", {}),
            "location": result.get("location"),
            "date_time": result.get("date"),
            "date": result.get("date"),
            "contact_info": result.get("contact_info"),
            "reward": result.get("reward"),
            "tags": tags,
            "confidence_scores": {
                "overall": confidence,
                "category": 0.8 if result.get("category") != "other" else 0.3,
                "title": 0.9 if len(result.get("title", "")) > 5 else 0.5,
            },
            "confidence": confidence,
            "original_text": text,
        }
    
    def _detect_post_type(self, text: str) -> str:
        text_lower = text.lower()
        lost_keywords = ["lost", "missing", "misplaced", "can't find", "cannot find", 
                        "dropped", "left behind", "help me find", "looking for",
                        "have you seen", "please help", "i lost"]
        found_keywords = ["found", "picked up", "discovered", "someone left", 
                         "claim", "owner", "is this yours", "belongs to",
                         "i found", "we found", "came across"]
        lost_score = sum(1 for kw in lost_keywords if kw in text_lower)
        found_score = sum(1 for kw in found_keywords if kw in text_lower)
        return "FOUND" if found_score > lost_score else "LOST"
    
    def _clean_description(self, text: str) -> str:
        cleaned = re.sub(r'\s+', ' ', text.strip())
        cleaned = re.sub(r'#\w+', '', cleaned)
        cleaned = re.sub(r'@\w+', '', cleaned)
        cleaned = re.sub(r'https?://\S+', '', cleaned)
        cleaned = re.sub(r'RT\s*:', '', cleaned)
        cleaned = re.sub(r'\s+', ' ', cleaned).strip()
        return cleaned[:1000] if cleaned else text[:1000]
    
    def _generate_tags(self, result: Dict[str, Any]) -> List[str]:
        tags = []
        category = result.get("category", "")
        if category and category != "other":
            tags.append(category)
        attrs = result.get("attributes", {})
        if attrs.get("color"):
            tags.append(attrs["color"])
        if attrs.get("brand"):
            tags.append(attrs["brand"].lower())
        title = result.get("title", "").lower()
        for kw in ["phone", "wallet", "keys", "bag", "laptop", "watch", "glasses", 
                   "dog", "cat", "ring", "earbuds", "headphones", "camera", "tablet", "id", "passport"]:
            if kw in title:
                tags.append(kw)
                break
        return list(set(tags))
    
    async def extract_from_image(self, detected_objects: List[Dict[str, Any]], ocr_text: Optional[str] = None) -> Dict[str, Any]:
        result = {"title": None, "description": None, "category": None, "attributes": {}, "location": None, "date": None}
        if detected_objects:
            primary = detected_objects[0]
            result["title"] = f"{primary['label'].title()}"
            result["category"] = primary.get("category", "other")
            object_names = [obj["label"] for obj in detected_objects[:3]]
            result["description"] = f"Image shows: {', '.join(object_names)}"
        if ocr_text:
            from models.ocr import OCRModel
            ocr = OCRModel()
            identifiers = ocr.extract_potential_identifiers(ocr_text)
            result["attributes"].update(identifiers)
        return result
    
    def merge_extractions(self, text_result: Dict[str, Any], image_result: Dict[str, Any]) -> Dict[str, Any]:
        merged = text_result.copy()
        for key, value in image_result.items():
            if key in ("attributes", "item_attributes"):
                merged_attrs = text_result.get("attributes", {}).copy()
                merged_attrs.update(value or {})
                merged["attributes"] = merged_attrs
                merged["item_attributes"] = merged_attrs
            elif key in ("detected_objects", "extracted_text"):
                merged[key] = value
            elif not merged.get(key) and value:
                merged[key] = value
        return merged
    
    def _rule_based_extraction(self, text: str) -> Dict[str, Any]:
        result = {"title": None, "description": text[:500] if text else None, "category": None, 
                  "attributes": {}, "location": None, "date": None, "contact_info": None, "reward": None}
        text_lower = text.lower()
        
        for category, keywords in CATEGORIES.items():
            if any(kw in text_lower for kw in keywords):
                result["category"] = category
                break
        if not result["category"]:
            result["category"] = "other"
        
        colors = ["black", "white", "red", "blue", "green", "yellow", "orange", "purple", 
                  "pink", "brown", "gray", "grey", "silver", "gold", "beige", "navy", "maroon"]
        for color in colors:
            if color in text_lower:
                result["attributes"]["color"] = color
                break
        
        brands = ["apple", "iphone", "samsung", "galaxy", "google", "pixel", "huawei", "xiaomi", 
                  "oneplus", "sony", "lg", "motorola", "nokia", "hp", "dell", "lenovo", "asus", 
                  "acer", "microsoft", "surface", "macbook", "ipad", "airpods", "nike", "adidas", 
                  "puma", "reebok", "converse", "vans", "gucci", "louis vuitton", "prada", 
                  "coach", "michael kors", "ray-ban", "oakley", "rolex", "casio", "fossil"]
        for brand in brands:
            if brand in text_lower:
                result["attributes"]["brand"] = brand.title()
                break
        
        location_patterns = [
            r'(?:at|near|in|around|by|outside|inside)\s+(?:the\s+)?([A-Z][a-zA-Z\s]+(?:station|park|mall|center|centre|street|road|avenue|plaza|square|building|hospital|school|university|college|airport|market|store|shop|restaurant|cafe|hotel|office|gym|library|church|mosque|temple))',
            r'(?:near|at|in)\s+([A-Z][a-zA-Z\s]+)',
            r'(?:on|along)\s+([A-Z][a-zA-Z]+\s+(?:Street|Road|Avenue|Boulevard|Lane|Drive|Way|Place))',
        ]
        for pattern in location_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                loc_text = match.group(1).strip()
                if len(loc_text) > 3:
                    result["location"] = {"description": loc_text}
                    break
        
        date_patterns = [
            r'(?:on|dated?)\s+(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
            r'(\d{1,2}\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)(?:\s+\d{4})?)',
            r'\b(yesterday|today|last\s+(?:night|evening|morning|week))\b',
            r'\b(this\s+(?:morning|afternoon|evening))\b',
        ]
        for pattern in date_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                result["date"] = match.group(1) if match.lastindex else match.group(0)
                break
        
        contact = {}
        phone_match = re.search(r'(\+?\d{1,3}[-.\s]?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4})', text)
        if phone_match:
            phone = re.sub(r'[^\d+]', '', phone_match.group(1))
            if len(phone) >= 10:
                contact["phone"] = phone
        email_match = re.search(r'[\w\.-]+@[\w\.-]+\.\w+', text)
        if email_match:
            contact["email"] = email_match.group(0)
        if contact:
            result["contact_info"] = contact
        
        reward_match = re.search(r'(?:reward|cash reward|offering)\s*[:of]?\s*\$?\s*(\d+)', text, re.IGNORECASE)
        if reward_match:
            result["reward"] = f"${reward_match.group(1)}"
        
        item_types = {
            "phone": ["phone", "iphone", "android", "smartphone", "mobile"],
            "wallet": ["wallet", "purse", "billfold"],
            "keys": ["keys", "keychain", "key fob", "car key"],
            "bag": ["bag", "backpack", "handbag", "purse", "tote", "suitcase", "luggage"],
            "laptop": ["laptop", "macbook", "notebook computer"],
            "watch": ["watch", "smartwatch", "fitbit"],
            "glasses": ["glasses", "sunglasses", "spectacles", "eyeglasses"],
            "dog": ["dog", "puppy", "golden retriever", "labrador", "bulldog", "poodle", "beagle", "husky"],
            "cat": ["cat", "kitten"],
            "earbuds": ["earbuds", "airpods", "headphones", "earphones"],
            "ring": ["ring", "engagement ring", "wedding ring"],
            "necklace": ["necklace", "chain", "pendant"],
            "camera": ["camera", "gopro", "dslr"],
            "tablet": ["tablet", "ipad"],
            "id card": ["id", "id card", "license", "passport", "driving license"],
        }
        
        detected_item = None
        for item_name, keywords in item_types.items():
            if any(kw in text_lower for kw in keywords):
                detected_item = item_name
                break
        
        title_parts = []
        if result["attributes"].get("color"):
            title_parts.append(result["attributes"]["color"].title())
        if result["attributes"].get("brand"):
            title_parts.append(result["attributes"]["brand"])
        if detected_item:
            title_parts.append(detected_item.title())
        
        if title_parts:
            result["title"] = " ".join(title_parts)
        else:
            sentences = text.split('.')
            for sentence in sentences:
                clean = sentence.strip()
                if 10 < len(clean) < 100:
                    if not re.search(r'call|contact|reward|email|phone|@', clean, re.IGNORECASE):
                        result["title"] = clean
                        break
            if not result["title"]:
                result["title"] = text[:80].strip()
        
        return result
    
    async def _llm_extraction(self, text: str, post_type: Optional[str] = None) -> Dict[str, Any]:
        try:
            prompt = EXTRACTION_PROMPTS["text_extraction"].format(post_type=post_type or "lost or found", text=text[:1000])
            inputs = self.tokenizer(prompt, return_tensors="pt", truncation=True, max_length=1024).to(self.device)
            with torch.no_grad():
                outputs = self.model.generate(**inputs, max_new_tokens=200, do_sample=True, 
                                              temperature=0.3, top_p=0.9, pad_token_id=self.tokenizer.pad_token_id)
            response = self.tokenizer.decode(outputs[0][inputs["input_ids"].shape[1]:], skip_special_tokens=True)
            return self._parse_llm_response(response)
        except Exception as e:
            print(f"LLM extraction error: {e}")
            return {}
    
    def _parse_llm_response(self, response: str) -> Dict[str, Any]:
        result = {}
        try:
            json_match = re.search(r'\{[^{}]*\}', response, re.DOTALL)
            if json_match:
                result = json.loads(json_match.group())
                return result
        except json.JSONDecodeError:
            pass
        patterns = {"title": r"title[:\s]+(.+?)(?:\n|$)", "category": r"category[:\s]+(.+?)(?:\n|$)",
                    "color": r"color[:\s]+(.+?)(?:\n|$)", "brand": r"brand[:\s]+(.+?)(?:\n|$)"}
        for key, pattern in patterns.items():
            match = re.search(pattern, response, re.IGNORECASE)
            if match:
                if key in ["color", "brand"]:
                    if "attributes" not in result:
                        result["attributes"] = {}
                    result["attributes"][key] = match.group(1).strip()
                else:
                    result[key] = match.group(1).strip()
        return result
    
    def _merge_results(self, rule_result: Dict[str, Any], llm_result: Dict[str, Any]) -> Dict[str, Any]:
        merged = rule_result.copy()
        for key, value in llm_result.items():
            if key == "attributes":
                merged_attrs = rule_result.get("attributes", {}).copy()
                merged_attrs.update(value or {})
                merged["attributes"] = merged_attrs
            elif value:
                merged[key] = value
        return merged
