"""
OCR Model for text extraction from images
Uses EasyOCR for robust text detection
"""

import os
from typing import Optional
from PIL import Image
import numpy as np
import easyocr


class OCRModel:
    """
    Extracts text from images using EasyOCR
    Useful for reading IDs, labels, serial numbers etc.
    """
    
    def __init__(self):
        languages = os.getenv("OCR_LANGUAGES", "en").split(",")
        use_gpu = os.getenv("USE_GPU", "true").lower() == "true"
        
        print(f"📥 Loading OCR model for languages: {languages}")
        
        self.reader = easyocr.Reader(
            languages,
            gpu=use_gpu,
            model_storage_directory=os.getenv("MODEL_CACHE_DIR", "./models"),
        )
        
        print("✅ OCR model loaded!")
    
    async def extract_text(
        self,
        image: Image.Image,
        min_confidence: float = 0.3,
    ) -> Optional[str]:
        """
        Extract text from image
        Returns concatenated text found in image
        """
        # Convert PIL to numpy array
        image_np = np.array(image)
        
        # Run OCR
        results = self.reader.readtext(
            image_np,
            detail=1,
            paragraph=False,
        )
        
        if not results:
            return None
        
        # Filter by confidence and extract text
        texts = []
        for bbox, text, confidence in results:
            if confidence >= min_confidence:
                texts.append(text.strip())
        
        if not texts:
            return None
        
        return " ".join(texts)
    
    async def extract_structured(
        self,
        image: Image.Image,
        min_confidence: float = 0.3,
    ) -> list:
        """
        Extract text with position information
        Returns list of (text, confidence, bbox) tuples
        """
        image_np = np.array(image)
        
        results = self.reader.readtext(
            image_np,
            detail=1,
            paragraph=False,
        )
        
        structured = []
        for bbox, text, confidence in results:
            if confidence >= min_confidence:
                # Convert bbox to x, y, width, height
                x_coords = [point[0] for point in bbox]
                y_coords = [point[1] for point in bbox]
                
                structured.append({
                    "text": text.strip(),
                    "confidence": round(confidence, 3),
                    "bounding_box": {
                        "x": min(x_coords),
                        "y": min(y_coords),
                        "width": max(x_coords) - min(x_coords),
                        "height": max(y_coords) - min(y_coords),
                    }
                })
        
        return structured
    
    def extract_potential_identifiers(
        self,
        text: str
    ) -> dict:
        """
        Extract potential identifiers from OCR text
        (Serial numbers, phone numbers, IDs, etc.)
        """
        import re
        
        identifiers = {}
        
        if not text:
            return identifiers
        
        # Serial number patterns
        serial_patterns = [
            r'\b[A-Z0-9]{10,20}\b',  # Generic alphanumeric
            r'\bS/N[\s:]*([A-Z0-9]+)\b',  # S/N prefix
            r'\bSerial[\s:]*([A-Z0-9]+)\b',  # Serial prefix
            r'\bIMEI[\s:]*(\d{15})\b',  # IMEI
        ]
        
        for pattern in serial_patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            if matches:
                identifiers["serial_number"] = matches[0]
                break
        
        # Phone number patterns
        phone_pattern = r'\b(?:\+?1?[-.\s]?)?\(?[0-9]{3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}\b'
        phone_matches = re.findall(phone_pattern, text)
        if phone_matches:
            identifiers["phone_number"] = phone_matches[0]
        
        # Email pattern
        email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
        email_matches = re.findall(email_pattern, text)
        if email_matches:
            identifiers["email"] = email_matches[0]
        
        # Model number patterns
        model_patterns = [
            r'\bModel[\s:]*([A-Z0-9-]+)\b',
            r'\b(iPhone\s*\d+\s*(?:Pro|Max|Plus)?)\b',
            r'\b(Galaxy\s*[A-Z]\d+)\b',
            r'\b(MacBook\s*(?:Pro|Air)?)\b',
        ]
        
        for pattern in model_patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            if matches:
                identifiers["model"] = matches[0]
                break
        
        return identifiers
