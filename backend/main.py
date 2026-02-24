"""
Pet Breed AI – FastAPI backend
------------------------------
Runs a two-stage inference pipeline:
  1. species_best.keras  →  cat | dog
  2. cat_breed_kaggle.keras  OR  dog_breed_best_model.keras  →  top-5 breeds

Start the server:
    cd backend
    pip install -r requirements.txt
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload
"""

import io
import json
import os

import numpy as np
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image

# Lazy-import TensorFlow so startup errors are easier to diagnose
try:
    import tensorflow as tf  # type: ignore
    # EfficientNet preprocess_input was serialised as a Lambda layer inside
    # cat_breed_kaggle.keras and dog_breed_best_model.keras.  Keras 3 cannot
    # resolve it automatically, so we register it as a custom object.
    from tensorflow.keras.applications.efficientnet import (
        preprocess_input as efficientnet_preprocess_input,
    )
except ImportError as exc:
    raise RuntimeError(
        "TensorFlow is not installed. Run: pip install tensorflow"
    ) from exc

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
_HERE = os.path.dirname(os.path.abspath(__file__))
_MODELS_DIR = os.path.join(_HERE, "..", "lib", "AI", "models")


def _model_path(name: str) -> str:
    return os.path.join(_MODELS_DIR, name)


# ---------------------------------------------------------------------------
# Load models & labels at startup (once)
# ---------------------------------------------------------------------------
# Models that were saved with a Lambda(preprocess_input) layer need the
# function passed in custom_objects so Keras can deserialise the config.
_BREED_CUSTOM_OBJ = {"preprocess_input": efficientnet_preprocess_input}

print("Loading AI models …")
species_model = tf.keras.models.load_model(_model_path("species_best.keras"))
print("  species model OK")
cat_model = tf.keras.models.load_model(
    _model_path("cat_breed_kaggle.keras"),
    custom_objects=_BREED_CUSTOM_OBJ,
)
print("  cat model OK")
dog_model = tf.keras.models.load_model(
    _model_path("dog_breed_best_model.keras"),
    custom_objects=_BREED_CUSTOM_OBJ,
)
print("  dog model OK")
print("Models loaded.")

# Detect input sizes from the loaded models (e.g. 224 or 300).
_SPECIES_SIZE: int = species_model.input_shape[1]
_CAT_SIZE: int = cat_model.input_shape[1]
_DOG_SIZE: int = dog_model.input_shape[1]

with open(_model_path("species_labels.json")) as f:
    # {"0": "cat", "1": "dog"}
    species_labels: dict[str, str] = json.load(f)

with open(_model_path("cat_labels_kaggle.json")) as f:
    cat_labels: list[str] = json.load(f)

with open(_model_path("dog_breed_labels.json")) as f:
    dog_labels: list[str] = json.load(f)

# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
app = FastAPI(
    title="Pet Breed AI",
    description="Two-stage species + breed identification for cats and dogs.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _preprocess_normalised(image_bytes: bytes, size: int) -> np.ndarray:
    """Resize → normalise to [0, 1] → batch dim.  Used for species model."""
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize((size, size))
    arr = np.array(img, dtype=np.float32) / 255.0
    return np.expand_dims(arr, axis=0)


def _preprocess_raw(image_bytes: bytes, size: int) -> np.ndarray:
    """Resize → raw float32 [0, 255] → batch dim.

    Used for breed models that have a built-in Lambda(preprocess_input) layer;
    those models handle their own normalisation internally.
    """
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize((size, size))
    arr = np.array(img, dtype=np.float32)  # keep 0-255
    return np.expand_dims(arr, axis=0)


def _top_k(probs: np.ndarray, labels: list[str], k: int = 5) -> list[dict]:
    indices = np.argsort(probs)[::-1][:k]
    return [
        {"label": labels[i] if i < len(labels) else f"Unknown class {i}", "confidence": float(probs[i])}
        for i in indices
    ]


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------
@app.get("/health", tags=["utility"])
def health():
    """Quick health-check endpoint."""
    return {"status": "ok"}


@app.post("/predict", tags=["inference"])
async def predict(file: UploadFile = File(...)):
    """
    Accept a JPEG/PNG image and return:
    - detected species (cat | dog) with confidence
    - top-5 breed predictions with confidence scores
    """
    # Validate MIME type – also accept octet-stream because some HTTP clients
    # (e.g. Flutter's http package) send that as the default content-type.
    _ALLOWED = {"image/jpeg", "image/png", "image/webp", "image/heic",
                "image/heif", "application/octet-stream"}
    if file.content_type not in _ALLOWED:
        raise HTTPException(
            status_code=415,
            detail=f"Unsupported file type: {file.content_type}. "
                   "Please upload a JPEG or PNG image.",
        )

    import time
    t0 = time.perf_counter()

    data = await file.read()
    print(f"[TIMING] image received: {len(data)/1024:.1f} KB  ({time.perf_counter()-t0:.2f}s)")

    try:
        sp_arr = _preprocess_raw(data, _SPECIES_SIZE)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Could not decode image: {exc}")

    # Stage 1 — species detection
    # Use model() directly instead of model.predict() — much faster for a
    # single image because predict() has batching/callback overhead.
    sp_probs = species_model(sp_arr, training=False).numpy()[0]

    # The species model uses a single sigmoid neuron (binary classifier).
    # The model has built-in normalisation layers (TrueDivide + Subtract),
    # so raw 0-255 input is expected.
    # Labels: {"0": "cat", "1": "dog"} → sigmoid > 0.5 means dog (class 1).
    if sp_probs.shape == (1,):
        dog_prob = float(sp_probs[0])
        if dog_prob > 0.5:
            sp_label = "dog"
            sp_conf = dog_prob
        else:
            sp_label = "cat"
            sp_conf = 1.0 - dog_prob
    else:
        # Fallback: multi-class softmax (argmax as before)
        sp_idx = int(np.argmax(sp_probs))
        sp_label = species_labels[str(sp_idx)]
        sp_conf = float(sp_probs[sp_idx])

    print(f"[TIMING] species ({sp_label} {sp_conf:.0%}): {time.perf_counter()-t0:.2f}s")

    # Stage 2 — breed identification
    if sp_label == "cat":
        br_arr = _preprocess_raw(data, _CAT_SIZE)
        br_probs = cat_model(br_arr, training=False).numpy()[0]
        br_labels = cat_labels
    else:
        br_arr = _preprocess_raw(data, _DOG_SIZE)
        br_probs = dog_model(br_arr, training=False).numpy()[0]
        br_labels = dog_labels
    print(f"[TIMING] breed done: {time.perf_counter()-t0:.2f}s total")

    return {
        "species": {"label": sp_label, "confidence": sp_conf},
        "breed_predictions": _top_k(br_probs, br_labels, k=5),
    }
