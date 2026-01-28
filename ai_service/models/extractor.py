"""
Item Extractor - Uses LLM to extract structured data from text
Supports local models for $0 inference
"""

import os
import re
import json
from typing import Dict, Any, Optional, List

import torch
from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline

from utils.prompts import EXTRACTION_PROMPTS, CATEGORIES


class ItemExtractor:
    """
    Extracts structured item information using LLM
    Uses local model by default for free inference
    """
    
    def __init__(self, device: str = "cuda"):
        self.device = device
        self.llm_mode = os.getenv("LLM_MODEL", "local")
        
        if self.llm_mode == "local":
            self._init_local_model()
        else:
            # For other modes (ollama, openai), we'd use their APIs
            print(f"⚠️ LLM mode '{self.llm_mode}' - using rule-based extraction")
            self.model = None
            self.tokenizer = None
    
    def _init_local_model(self):
        """Initialize local LLM"""
        model_name = os.getenv("LOCAL_LLM", "microsoft/phi-2")
        cache_dir = os.getenv("MODEL_CACHE_DIR", "./models")
        
        print(f"📥 Loading local LLM: {model_name}")
        
        self.tokenizer = AutoTokenizer.from_pretrained(
            model_name,
            cache_dir=cache_dir,
            trust_remote_code=True,
        )
        
        # Set padding token if not set
        if self.tokenizer.pad_token is None:
            self.tokenizer.pad_token = self.tokenizer.eos_token
        
        self.model = AutoModelForCausalLM.from_pretrained(
            model_name,
            cache_dir=cache_dir,
            torch_dtype=torch.float16 if self.device == "cuda" else torch.float32,
            device_map="auto" if self.device == "cuda" else None,
            trust_remote_code=True,
        )
        
        if self.device != "cuda":
            self.model = self.model.to(self.device)
        
        self.model.eval()
        print("✅ Local LLM loaded!")
    
    async def extract_from_text(
        self,
        text: str,
        post_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Extract structured item information from text description
        """
        # Use rule-based extraction with LLM enhancement
        result = self._rule_based_extraction(text)
        
        # Try LLM extraction if available
        if self.model is not None:
            llm_result = await self._llm_extraction(text, post_type)
            result = self._merge_results(result, llm_result)
        
        # Calculate confidence
        filled_fields = sum(1 for v in result.values() if v)
        result["confidence"] = min(filled_fields / 6, 1.0)
        
        return result
    
    async def extract_from_image(
        self,
        detected_objects: List[Dict[str, Any]],
        ocr_text: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Extract item information from image analysis results
        """
        result = {
            "title": None,
            "description": None,
            "category": None,
            "attributes": {},
            "location": None,
            "date": None,
        }
        
        # Get primary object
        if detected_objects:
            primary = detected_objects[0]
            result["title"] = f"{primary['label'].title()}"
            result["category"] = primary.get("category", "other")
            
            # Build description from objects
            object_names = [obj["label"] for obj in detected_objects[:3]]
            result["description"] = f"Image shows: {', '.join(object_names)}"
        
        # Extract identifiers from OCR
        if ocr_text:
            from models.ocr import OCRModel
            ocr = OCRModel()
            identifiers = ocr.extract_potential_identifiers(ocr_text)
            result["attributes"].update(identifiers)
        
        return result
    
    def merge_extractions(
        self,
        text_result: Dict[str, Any],
        image_result: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Merge text and image extraction results
        Text takes priority, image fills gaps
        """
        merged = text_result.copy()
        
        for key, value in image_result.items():
            if key == "attributes":
                # Merge attributes
                merged_attrs = text_result.get("attributes", {}).copy()
                merged_attrs.update(value or {})
                merged["attributes"] = merged_attrs
            elif key == "detected_objects" or key == "extracted_text":
                # Always include these from image
                merged[key] = value
            elif not merged.get(key) and value:
                # Fill gaps
                merged[key] = value
        
        return merged
    
    def _rule_based_extraction(self, text: str) -> Dict[str, Any]:
        """
        Extract information using regex patterns and rules
        """
        result = {
            "title": None,
            "description": text[:500] if text else None,
            "category": None,
            "attributes": {},
            "location": None,
            "date": None,
        }
        
        text_lower = text.lower()
        
        # Category detection
        for category, keywords in CATEGORIES.items():
            if any(kw in text_lower for kw in keywords):
                result["category"] = category
                break
        
        if not result["category"]:
            result["category"] = "other"
        
        # Color extraction
        colors = [
            "black", "white", "red", "blue", "green", "yellow",
            "orange", "purple", "pink", "brown", "gray", "grey",
            "silver", "gold", "beige", "navy", "maroon"
        ]
        for color in colors:
            if color in text_lower:
                result["attributes"]["color"] = color
                break
        
        # Brand extraction
        brands = [
            "apple", "iphone", "samsung", "galaxy", "google", "pixel",
            "huawei", "xiaomi", "oneplus", "sony", "lg", "motorola",
            "nokia", "hp", "dell", "lenovo", "asus", "acer",
            "microsoft", "surface", "macbook", "ipad", "airpods",
            "nike", "adidas", "puma", "reebok", "converse", "vans",
            "gucci", "louis vuitton", "prada", "coach", "michael kors",
            "ray-ban", "oakley", "rolex", "casio", "fossil"
        ]
        for brand in brands:
            if brand in text_lower:
                result["attributes"]["brand"] = brand.title()
                break
        
        # Location patterns
        location_patterns = [
            r'(?:at|near|in|around|by)\s+(?:the\s+)?([A-Z][a-zA-Z\s]+(?:station|park|mall|center|centre|street|road|avenue|plaza|square|building))',
            r'(?:near|at)\s+(\d+\s+[A-Z][a-zA-Z\s]+)',
            r'in\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)?)\s+(?:city|town|area)',
        ]
        for pattern in location_patterns:
            match = re.search(pattern, text)
            if match:
                result["location"] = {"description": match.group(1).strip()}
                break
        
        # Date patterns
        date_patterns = [
            r'on\s+(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})',
            r'(\d{1,2}\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4})',
            r'(?:yesterday|today|last\s+(?:night|week|monday|tuesday|wednesday|thursday|friday|saturday|sunday))',
        ]
        for pattern in date_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                result["date"] = match.group(0)
                break
        
        # Generate title
        title_parts = []
        if result["attributes"].get("color"):
            title_parts.append(result["attributes"]["color"].title())
        if result["attributes"].get("brand"):
            title_parts.append(result["attributes"]["brand"])
        
        # Add item type
        item_types = [
            "phone", "wallet", "keys", "bag", "laptop", "watch",
            "glasses", "umbrella", "jacket", "dog", "cat", "ring",
            "necklace", "earbuds", "headphones", "camera", "tablet"
        ]
        for item in item_types:
            if item in text_lower:
                title_parts.append(item.title())
                break
        
        if title_parts:
            result["title"] = " ".join(title_parts)
        else:
            # Use first sentence as title
            first_sentence = text.split('.')[0][:100]
            result["title"] = first_sentence
        
        return result
    
    async def _llm_extraction(
        self,
        text: str,
        post_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Use LLM for more accurate extraction
        """
        try:
            prompt = EXTRACTION_PROMPTS["text_extraction"].format(
                post_type=post_type or "lost or found",
                text=text[:1000],  # Limit input length
            )
            
            inputs = self.tokenizer(
                prompt,
                return_tensors="pt",
                truncation=True,
                max_length=1024,
            ).to(self.device)
            
            with torch.no_grad():
                outputs = self.model.generate(
                    **inputs,
                    max_new_tokens=200,
                    do_sample=True,
                    temperature=0.3,
                    top_p=0.9,
                    pad_token_id=self.tokenizer.pad_token_id,
                )
            
            response = self.tokenizer.decode(
                outputs[0][inputs["input_ids"].shape[1]:],
                skip_special_tokens=True,
            )
            
            # Try to parse JSON from response
            return self._parse_llm_response(response)
        
        except Exception as e:
            print(f"LLM extraction error: {e}")
            return {}
    
    def _parse_llm_response(self, response: str) -> Dict[str, Any]:
        """Parse LLM response into structured data"""
        result = {}
        
        # Try JSON parsing
        try:
            # Find JSON in response
            json_match = re.search(r'\{[^{}]*\}', response, re.DOTALL)
            if json_match:
                result = json.loads(json_match.group())
                return result
        except json.JSONDecodeError:
            pass
        
        # Fall back to key-value parsing
        patterns = {
            "title": r"title[:\s]+(.+?)(?:\n|$)",
            "category": r"category[:\s]+(.+?)(?:\n|$)",
            "color": r"color[:\s]+(.+?)(?:\n|$)",
            "brand": r"brand[:\s]+(.+?)(?:\n|$)",
        }
        
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
    
    def _merge_results(
        self,
        rule_result: Dict[str, Any],
        llm_result: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Merge rule-based and LLM results, preferring LLM"""
        merged = rule_result.copy()
        
        for key, value in llm_result.items():
            if key == "attributes":
                merged_attrs = rule_result.get("attributes", {}).copy()
                merged_attrs.update(value or {})
                merged["attributes"] = merged_attrs
            elif value:
                merged[key] = value
        
        return merged
