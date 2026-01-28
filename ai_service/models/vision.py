"""
Vision Model for object detection and image captioning
Uses DETR (Detection Transformer) for object detection
"""

import os
from typing import List, Dict, Any, Optional
from PIL import Image
import torch
from transformers import (
    DetrImageProcessor,
    DetrForObjectDetection,
    BlipProcessor,
    BlipForConditionalGeneration,
)


class VisionModel:
    """
    Handles object detection and image captioning
    Uses DETR for detection and BLIP for captioning
    """
    
    def __init__(self, device: str = "cuda"):
        self.device = device
        cache_dir = os.getenv("MODEL_CACHE_DIR", "./models")
        
        # Object detection model
        print("📥 Loading object detection model...")
        detection_model = os.getenv("VISION_MODEL", "facebook/detr-resnet-50")
        
        self.detection_processor = DetrImageProcessor.from_pretrained(
            detection_model,
            cache_dir=cache_dir,
        )
        self.detection_model = DetrForObjectDetection.from_pretrained(
            detection_model,
            cache_dir=cache_dir,
        ).to(device)
        self.detection_model.eval()
        
        # Caption model (optional - may fail on slow networks)
        print("📥 Loading captioning model...")
        caption_model = "Salesforce/blip-image-captioning-base"
        
        self.caption_processor = None
        self.caption_model = None
        
        try:
            self.caption_processor = BlipProcessor.from_pretrained(
                caption_model,
                cache_dir=cache_dir,
                local_files_only=False,
            )
            self.caption_model = BlipForConditionalGeneration.from_pretrained(
                caption_model,
                cache_dir=cache_dir,
                local_files_only=False,
            ).to(device)
            self.caption_model.eval()
            print("✅ Captioning model loaded successfully")
        except Exception as e:
            print(f"⚠️ Captioning model failed to load: {e}")
            print("   Image captioning will be disabled, but object detection will work.")
            self.caption_processor = None
            self.caption_model = None
        
        # Category mapping for common lost & found items
        self.item_categories = {
            # Electronics
            "cell phone": "electronics",
            "laptop": "electronics",
            "remote": "electronics",
            "keyboard": "electronics",
            "mouse": "electronics",
            "tv": "electronics",
            "tablet": "electronics",
            
            # Accessories
            "handbag": "bags",
            "backpack": "bags",
            "suitcase": "bags",
            "umbrella": "accessories",
            "watch": "accessories",
            "sunglasses": "accessories",
            "tie": "accessories",
            
            # Keys
            "key": "keys",
            
            # Jewelry
            "ring": "jewelry",
            "necklace": "jewelry",
            "bracelet": "jewelry",
            "earring": "jewelry",
            
            # Documents (inferred from context)
            "book": "books",
            
            # Clothing
            "hat": "clothing",
            "shoe": "clothing",
            "jacket": "clothing",
            "coat": "clothing",
            "shirt": "clothing",
            
            # Pets
            "dog": "pets",
            "cat": "pets",
            "bird": "pets",
            
            # Sports
            "sports ball": "sports",
            "tennis racket": "sports",
            "skateboard": "sports",
            "bicycle": "sports",
            
            # Toys
            "teddy bear": "toys",
            "toy": "toys",
        }
        
        print("✅ Vision models loaded!")
    
    async def detect_objects(
        self,
        image: Image.Image,
        threshold: float = 0.7,
    ) -> List[Dict[str, Any]]:
        """
        Detect objects in image
        Returns list of detected objects with labels and confidence
        """
        with torch.no_grad():
            inputs = self.detection_processor(
                images=image,
                return_tensors="pt"
            ).to(self.device)
            
            outputs = self.detection_model(**inputs)
            
            # Get predictions
            target_sizes = torch.tensor([image.size[::-1]]).to(self.device)
            results = self.detection_processor.post_process_object_detection(
                outputs,
                target_sizes=target_sizes,
                threshold=threshold,
            )[0]
        
        detected = []
        for score, label, box in zip(
            results["scores"],
            results["labels"],
            results["boxes"]
        ):
            label_name = self.detection_model.config.id2label[label.item()]
            
            detected.append({
                "label": label_name,
                "confidence": round(score.item(), 3),
                "bounding_box": {
                    "x": round(box[0].item(), 1),
                    "y": round(box[1].item(), 1),
                    "width": round((box[2] - box[0]).item(), 1),
                    "height": round((box[3] - box[1]).item(), 1),
                },
                "category": self.item_categories.get(label_name.lower(), "other"),
            })
        
        # Sort by confidence
        detected.sort(key=lambda x: x["confidence"], reverse=True)
        
        return detected[:10]  # Return top 10
    
    async def generate_caption(
        self,
        image: Image.Image,
        max_length: int = 50,
    ) -> str:
        """
        Generate descriptive caption for image
        """
        # Check if captioning model is available
        if self.caption_model is None or self.caption_processor is None:
            return "Image caption not available (model not loaded)"
        
        with torch.no_grad():
            inputs = self.caption_processor(
                images=image,
                return_tensors="pt"
            ).to(self.device)
            
            output = self.caption_model.generate(
                **inputs,
                max_length=max_length,
                num_beams=4,
            )
            
            caption = self.caption_processor.decode(
                output[0],
                skip_special_tokens=True
            )
        
        return caption
    
    def suggest_category(
        self,
        detected_objects: List[Dict[str, Any]]
    ) -> Optional[str]:
        """
        Suggest item category based on detected objects
        """
        if not detected_objects:
            return None
        
        # Count categories
        category_counts = {}
        for obj in detected_objects:
            cat = obj.get("category", "other")
            confidence = obj.get("confidence", 0)
            category_counts[cat] = category_counts.get(cat, 0) + confidence
        
        # Return highest scoring category
        if category_counts:
            return max(category_counts, key=category_counts.get)
        
        return None
    
    def extract_colors(
        self,
        image: Image.Image,
        n_colors: int = 3,
    ) -> List[str]:
        """
        Extract dominant colors from image
        Simple implementation using color quantization
        """
        # Resize for speed
        small_image = image.copy()
        small_image.thumbnail((100, 100))
        
        # Convert to palette
        palette_image = small_image.quantize(colors=n_colors)
        
        # Get palette
        palette = palette_image.getpalette()[:n_colors * 3]
        
        colors = []
        for i in range(0, len(palette), 3):
            r, g, b = palette[i:i+3]
            color_name = self._rgb_to_color_name(r, g, b)
            if color_name not in colors:
                colors.append(color_name)
        
        return colors
    
    def _rgb_to_color_name(self, r: int, g: int, b: int) -> str:
        """Convert RGB to basic color name"""
        # Simple heuristic for common colors
        if r > 200 and g > 200 and b > 200:
            return "white"
        if r < 50 and g < 50 and b < 50:
            return "black"
        if r > 150 and g < 100 and b < 100:
            return "red"
        if r < 100 and g > 150 and b < 100:
            return "green"
        if r < 100 and g < 100 and b > 150:
            return "blue"
        if r > 150 and g > 150 and b < 100:
            return "yellow"
        if r > 150 and g < 100 and b > 150:
            return "purple"
        if r > 150 and g > 100 and b < 50:
            return "orange"
        if r > 100 and g > 80 and b > 60 and r < 180:
            return "brown"
        if abs(r - g) < 30 and abs(g - b) < 30:
            return "gray"
        
        return "multicolor"
