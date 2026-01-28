"""
Prompt templates for AI extraction
"""

# Category keywords for classification
CATEGORIES = {
    "electronics": [
        "phone", "iphone", "android", "samsung", "laptop", "computer",
        "tablet", "ipad", "airpods", "headphones", "earbuds", "charger",
        "cable", "camera", "gopro", "drone", "smartwatch", "fitbit",
        "kindle", "e-reader", "speaker", "powerbank", "usb", "mouse",
        "keyboard"
    ],
    "documents": [
        "passport", "id", "license", "driver's license", "driving license",
        "credit card", "debit card", "bank card", "social security",
        "birth certificate", "visa", "green card", "permit", "ticket",
        "boarding pass", "certificate", "diploma"
    ],
    "accessories": [
        "watch", "glasses", "sunglasses", "umbrella", "scarf", "gloves",
        "belt", "tie", "hat", "cap", "wallet", "purse", "case"
    ],
    "clothing": [
        "jacket", "coat", "sweater", "hoodie", "shirt", "pants", "jeans",
        "dress", "skirt", "shoes", "boots", "sneakers", "sandals"
    ],
    "bags": [
        "bag", "backpack", "purse", "handbag", "briefcase", "suitcase",
        "luggage", "duffel", "tote", "messenger bag", "laptop bag"
    ],
    "keys": [
        "keys", "key", "keychain", "car key", "house key", "key fob"
    ],
    "pets": [
        "dog", "cat", "puppy", "kitten", "bird", "parrot", "rabbit",
        "hamster", "pet", "golden retriever", "labrador", "bulldog",
        "poodle", "beagle", "german shepherd", "husky"
    ],
    "jewelry": [
        "ring", "necklace", "bracelet", "earring", "watch", "pendant",
        "chain", "diamond", "gold", "silver", "engagement ring",
        "wedding ring"
    ],
    "sports": [
        "ball", "soccer", "football", "basketball", "tennis", "golf",
        "skateboard", "bicycle", "bike", "helmet", "racket", "bat",
        "glove"
    ],
    "books": [
        "book", "notebook", "journal", "diary", "textbook", "novel"
    ],
    "toys": [
        "toy", "doll", "teddy bear", "stuffed animal", "lego", "game",
        "puzzle"
    ],
    "medical": [
        "medication", "medicine", "insulin", "inhaler", "hearing aid",
        "glasses", "prescription", "medical device"
    ],
    "instruments": [
        "guitar", "violin", "piano", "keyboard", "drums", "flute",
        "saxophone", "trumpet", "ukulele"
    ],
}

# Extraction prompts
EXTRACTION_PROMPTS = {
    "text_extraction": """Extract item details from this {post_type} item description.

Text: "{text}"

Extract the following information as JSON:
- title: A short descriptive title for the item
- category: One of [electronics, documents, accessories, clothing, bags, keys, pets, jewelry, sports, books, toys, medical, instruments, other]
- attributes: Object with color, brand, model, size, material if mentioned
- location: Object with description, city if mentioned
- date: Date when lost/found if mentioned

Return ONLY valid JSON, no explanation.""",

    "image_analysis": """Analyze this image and extract item details.

Detected objects: {objects}
OCR text found: {ocr_text}

Based on the above, extract:
- What is the main item in the image?
- What category does it belong to?
- What are its attributes (color, brand, condition)?

Return as JSON.""",

    "match_explanation": """Explain why these two items might be a match.

Lost item: {lost_item}
Found item: {found_item}

Match score: {score}%

Provide a brief, friendly explanation of why these items might be the same.""",

    "generate_title": """Generate a short, descriptive title for this {post_type} item.

Description: {description}
Category: {category}
Attributes: {attributes}

Return only the title, 5-10 words maximum.""",

    "improve_description": """Improve this item description to help find the owner/item.

Original: {description}

Make it clear, detailed, and helpful. Include any identifying details.
Keep it under 200 words.""",
}

# Matching score explanations
MATCH_EXPLANATIONS = {
    "category": "Both items are in the same category",
    "color": "The colors match",
    "brand": "The brands match",
    "model": "The models match",
    "location": "Found in the same area",
    "time": "The timing matches",
    "embedding": "High semantic similarity detected by AI",
}

# Response templates
RESPONSE_TEMPLATES = {
    "match_notification": """🔗 Potential Match Found!

We found a {match_type} item that might be yours:
{item_title}

Match confidence: {score}%
{reasons}

Tap to view details and connect with the finder.""",

    "reunion_success": """🎉 Congratulations!

The item "{item_title}" has been marked as reunited!

Thank you for using LostLink to help bring lost items back to their owners.""",
}
