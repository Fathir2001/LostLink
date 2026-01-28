"""
LostLink AI Service
FastAPI-based AI service for extraction, embedding, and matching
Runs on local NVIDIA GPU for $0 inference cost
"""

import os
import io
import base64
from typing import Optional, List, Dict, Any
from contextlib import asynccontextmanager

import torch
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from PIL import Image
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Import our modules
from models.embedder import EmbeddingModel
from models.vision import VisionModel
from models.ocr import OCRModel
from models.extractor import ItemExtractor
from utils.prompts import EXTRACTION_PROMPTS

# Configuration
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", 8000))
USE_GPU = os.getenv("USE_GPU", "true").lower() == "true"
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")

# Global model instances
embedding_model: Optional[EmbeddingModel] = None
vision_model: Optional[VisionModel] = None
ocr_model: Optional[OCRModel] = None
item_extractor: Optional[ItemExtractor] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifecycle manager for loading/unloading models"""
    global embedding_model, vision_model, ocr_model, item_extractor
    
    print("🚀 Loading AI models...")
    
    device = "cuda" if USE_GPU and torch.cuda.is_available() else "cpu"
    print(f"📍 Using device: {device}")
    
    if USE_GPU and torch.cuda.is_available():
        print(f"🎮 GPU: {torch.cuda.get_device_name(0)}")
        print(f"💾 VRAM: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
    
    # Load models
    embedding_model = EmbeddingModel(device=device)
    vision_model = VisionModel(device=device)
    ocr_model = OCRModel()
    item_extractor = ItemExtractor(device=device)
    
    print("✅ All models loaded successfully!")
    
    yield
    
    # Cleanup
    print("🧹 Unloading models...")
    del embedding_model, vision_model, ocr_model, item_extractor
    if torch.cuda.is_available():
        torch.cuda.empty_cache()


# Create FastAPI app
app = FastAPI(
    title="LostLink AI Service",
    description="AI-powered extraction, embedding, and matching for lost & found items",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============== Request/Response Models ==============

class TextExtractionRequest(BaseModel):
    text: str = Field(..., description="Text to extract item details from")
    post_type: Optional[str] = Field(None, description="'lost' or 'found'")


class ImageExtractionRequest(BaseModel):
    image_url: Optional[str] = Field(None, description="URL of image")
    image_base64: Optional[str] = Field(None, description="Base64 encoded image")


class EmbeddingRequest(BaseModel):
    text: str = Field(..., description="Text to generate embedding for")


class CaptionRequest(BaseModel):
    image_url: Optional[str] = Field(None)
    image_base64: Optional[str] = Field(None)


class ExtractionResult(BaseModel):
    """Response format matching Flutter AIExtractionResult"""
    post_type: str = "LOST"
    category: str = "other"
    title: str = ""
    clean_description: str = ""
    description: Optional[str] = None  # Legacy field
    item_attributes: Dict[str, Any] = {}
    attributes: Dict[str, Any] = {}  # Legacy field
    location: Optional[Dict[str, Any]] = None
    date_time: Optional[str] = None
    date: Optional[str] = None  # Legacy field
    contact_info: Optional[Dict[str, Any]] = None
    reward: Optional[str] = None
    tags: List[str] = []
    confidence_scores: Dict[str, float] = {}
    confidence: float = 0.0  # Legacy field
    detected_objects: List[Dict[str, Any]] = []
    extracted_text: Optional[str] = None
    original_text: Optional[str] = None


class EmbeddingResult(BaseModel):
    embedding: List[float]
    dimension: int


class CaptionResult(BaseModel):
    caption: str
    detected_objects: List[Dict[str, Any]]


# ============== API Endpoints ==============

@app.get("/")
async def root():
    """Health check endpoint"""
    gpu_available = torch.cuda.is_available() if USE_GPU else False
    return {
        "service": "LostLink AI Service",
        "status": "running",
        "gpu_available": gpu_available,
        "gpu_name": torch.cuda.get_device_name(0) if gpu_available else None,
        "endpoints": {
            "/extract/text": "Extract item details from text",
            "/extract/image": "Extract item details from image",
            "/extract/combined": "Extract from both text and image",
            "/embed": "Generate text embedding",
            "/generate/caption": "Generate image caption",
        }
    }


@app.post("/extract/text", response_model=ExtractionResult)
async def extract_from_text(request: TextExtractionRequest):
    """
    Extract item details from text description
    Uses LLM to parse and structure the information
    """
    try:
        if not request.text or len(request.text.strip()) < 10:
            raise HTTPException(status_code=400, detail="Text too short")
        
        result = await item_extractor.extract_from_text(
            request.text,
            post_type=request.post_type
        )
        
        return ExtractionResult(**result)
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/extract/image", response_model=ExtractionResult)
async def extract_from_image(
    image: Optional[UploadFile] = File(None),
    image_url: Optional[str] = Form(None),
    image_base64: Optional[str] = Form(None),
):
    """
    Extract item details from image
    Uses vision model for object detection and OCR for text
    """
    try:
        # Get image
        pil_image = None
        
        if image:
            contents = await image.read()
            pil_image = Image.open(io.BytesIO(contents))
        elif image_base64:
            image_data = base64.b64decode(image_base64)
            pil_image = Image.open(io.BytesIO(image_data))
        elif image_url:
            import httpx
            async with httpx.AsyncClient() as client:
                response = await client.get(image_url)
                pil_image = Image.open(io.BytesIO(response.content))
        else:
            raise HTTPException(status_code=400, detail="No image provided")
        
        # Convert to RGB if needed
        if pil_image.mode != "RGB":
            pil_image = pil_image.convert("RGB")
        
        # Run vision and OCR
        detected_objects = await vision_model.detect_objects(pil_image)
        ocr_text = await ocr_model.extract_text(pil_image)
        
        # Extract structured data
        result = await item_extractor.extract_from_image(
            detected_objects=detected_objects,
            ocr_text=ocr_text,
        )
        
        result["detected_objects"] = detected_objects
        result["extracted_text"] = ocr_text
        
        return ExtractionResult(**result)
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/extract/combined", response_model=ExtractionResult)
async def extract_combined(
    text: str = Form(...),
    post_type: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    image_url: Optional[str] = Form(None),
):
    """
    Extract item details from both text and image
    Combines results for best accuracy
    """
    try:
        # Extract from text
        text_result = await item_extractor.extract_from_text(text, post_type)
        
        # Extract from image if provided
        image_result = {}
        if image or image_url:
            pil_image = None
            
            if image:
                contents = await image.read()
                pil_image = Image.open(io.BytesIO(contents))
            elif image_url:
                import httpx
                async with httpx.AsyncClient() as client:
                    response = await client.get(image_url)
                    pil_image = Image.open(io.BytesIO(response.content))
            
            if pil_image:
                if pil_image.mode != "RGB":
                    pil_image = pil_image.convert("RGB")
                
                detected_objects = await vision_model.detect_objects(pil_image)
                ocr_text = await ocr_model.extract_text(pil_image)
                
                image_result = await item_extractor.extract_from_image(
                    detected_objects=detected_objects,
                    ocr_text=ocr_text,
                )
                image_result["detected_objects"] = detected_objects
                image_result["extracted_text"] = ocr_text
        
        # Merge results (text takes priority, image fills gaps)
        merged = item_extractor.merge_extractions(text_result, image_result)
        
        return ExtractionResult(**merged)
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/embed", response_model=EmbeddingResult)
async def generate_embedding(request: EmbeddingRequest):
    """
    Generate embedding vector for text
    Used for semantic similarity matching
    """
    try:
        if not request.text or len(request.text.strip()) < 3:
            raise HTTPException(status_code=400, detail="Text too short")
        
        embedding = embedding_model.encode(request.text)
        
        return EmbeddingResult(
            embedding=embedding.tolist(),
            dimension=len(embedding)
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/embed/batch")
async def generate_embeddings_batch(texts: List[str]):
    """
    Generate embeddings for multiple texts
    More efficient than calling /embed multiple times
    """
    try:
        if not texts or len(texts) == 0:
            raise HTTPException(status_code=400, detail="No texts provided")
        
        if len(texts) > 100:
            raise HTTPException(status_code=400, detail="Max 100 texts per batch")
        
        embeddings = embedding_model.encode_batch(texts)
        
        return {
            "embeddings": [e.tolist() for e in embeddings],
            "count": len(embeddings),
            "dimension": len(embeddings[0]) if embeddings else 0,
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/generate/caption", response_model=CaptionResult)
async def generate_caption(
    image: Optional[UploadFile] = File(None),
    image_url: Optional[str] = Form(None),
    image_base64: Optional[str] = Form(None),
):
    """
    Generate descriptive caption for image
    Useful for accessibility and search
    """
    try:
        pil_image = None
        
        if image:
            contents = await image.read()
            pil_image = Image.open(io.BytesIO(contents))
        elif image_base64:
            image_data = base64.b64decode(image_base64)
            pil_image = Image.open(io.BytesIO(image_data))
        elif image_url:
            import httpx
            async with httpx.AsyncClient() as client:
                response = await client.get(image_url)
                pil_image = Image.open(io.BytesIO(response.content))
        else:
            raise HTTPException(status_code=400, detail="No image provided")
        
        if pil_image.mode != "RGB":
            pil_image = pil_image.convert("RGB")
        
        # Generate caption and detect objects
        detected_objects = await vision_model.detect_objects(pil_image)
        caption = await vision_model.generate_caption(pil_image)
        
        return CaptionResult(
            caption=caption,
            detected_objects=detected_objects,
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "models": {
            "embedding": embedding_model is not None,
            "vision": vision_model is not None,
            "ocr": ocr_model is not None,
            "extractor": item_extractor is not None,
        },
        "gpu": {
            "available": torch.cuda.is_available(),
            "device_count": torch.cuda.device_count() if torch.cuda.is_available() else 0,
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=HOST,
        port=PORT,
        reload=os.getenv("ENV") == "development",
    )
