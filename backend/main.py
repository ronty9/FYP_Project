"""
Pet Breed & Skin Disease AI – FastAPI backend
---------------------------------------------
Runs a two-stage inference pipeline for BOTH Breeds and Diseases:
  1. species_best.keras  →  cat | dog
  2a. cat_breed_kaggle.keras  OR  dog_breed_best_model.keras  →  top-5 breeds
  2b. cat_disease_model.keras OR dog_disease_model.keras      →  top-3 diseases

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
from fastapi.responses import JSONResponse
from PIL import Image
from pydantic import BaseModel

# Firebase Admin SDK
_firebase_admin_ready = False
try:
    import firebase_admin
    from firebase_admin import auth as firebase_auth_admin
    from firebase_admin import credentials

    _SA_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "serviceAccount.json")
    if os.path.exists(_SA_PATH):
        _cred = credentials.Certificate(_SA_PATH)
        firebase_admin.initialize_app(_cred)
        _firebase_admin_ready = True
        print("  Firebase Admin SDK initialised via serviceAccount.json")
    else:
        print("  WARNING: backend/serviceAccount.json not found. "
              "/reset-password endpoint will be unavailable. "
              "Download it from Firebase Console → Project Settings → Service Accounts.")
except ImportError:
    print("  WARNING: firebase-admin not installed. Run: pip install firebase-admin")

# Lazy-import TensorFlow so startup errors are easier to diagnose
try:
    import tensorflow as tf  # type: ignore
    # EfficientNet preprocess_input was serialised as a Lambda layer inside
    # cat_breed_kaggle.keras and dog_breed_best_model.keras.
    from tensorflow.keras.applications.efficientnet import (
        preprocess_input as efficientnet_preprocess_input,
    )
    # MobileNetV2 preprocess_input is used for the skin disease models
    from tensorflow.keras.applications.mobilenet_v2 import (
        preprocess_input as mobilenet_v2_preprocess_input,
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
_BREED_CUSTOM_OBJ = {"preprocess_input": efficientnet_preprocess_input}
_DISEASE_CUSTOM_OBJ = {"preprocess_input": mobilenet_v2_preprocess_input}

print("Loading AI models …")

# --- 1. Load Species Model ---
species_model = tf.keras.models.load_model(_model_path("species_best.keras"))
print("  species model OK")

# --- 2. Load Breed Models ---
cat_model = tf.keras.models.load_model(
    _model_path("cat_breed_kaggle.keras"),
    custom_objects=_BREED_CUSTOM_OBJ,
)
print("  cat breed model OK")
dog_model = tf.keras.models.load_model(
    _model_path("dog_breed_best_model.keras"),
    custom_objects=_BREED_CUSTOM_OBJ,
)
print("  dog breed model OK")

# --- 3. Load Skin Disease Models ---
try:
    cat_disease_model = tf.keras.models.load_model(
        _model_path("cat_disease_model.keras"),
        custom_objects=_DISEASE_CUSTOM_OBJ,
    )
    print("  cat disease model OK")
    
    dog_disease_model = tf.keras.models.load_model(
        _model_path("dog_disease_model.keras"),
        custom_objects=_DISEASE_CUSTOM_OBJ,
    )
    print("  dog disease model OK")
except Exception as e:
    print(f"  WARNING: Could not load disease models. Ensure files are in the models folder. Error: {e}")


print("Models loaded.")

# Detect input sizes from the loaded models
_SPECIES_SIZE: int = species_model.input_shape[1]
_CAT_SIZE: int = cat_model.input_shape[1]
_DOG_SIZE: int = dog_model.input_shape[1]

# Try to get disease model input sizes safely
_CAT_DISEASE_SIZE: int = 224
_DOG_DISEASE_SIZE: int = 224
if 'cat_disease_model' in locals():
    _CAT_DISEASE_SIZE = cat_disease_model.input_shape[1]
    _DOG_DISEASE_SIZE = dog_disease_model.input_shape[1]

# --- Load Labels ---
with open(_model_path("species_labels.json")) as f:
    species_labels: dict[str, str] = json.load(f)

with open(_model_path("cat_labels_kaggle.json")) as f:
    cat_labels: list[str] = json.load(f)

with open(_model_path("dog_breed_labels.json")) as f:
    dog_labels: list[str] = json.load(f)

# Load Disease Labels (Convert dictionary {"0": "DiseaseA"} to list ["DiseaseA"])
try:
    with open(_model_path("cat_disease_labels.json")) as f:
        c_d_dict = json.load(f)
        cat_disease_labels = [c_d_dict[str(i)] for i in range(len(c_d_dict))]

    with open(_model_path("dog_disease_labels.json")) as f:
        d_d_dict = json.load(f)
        dog_disease_labels = [d_d_dict[str(i)] for i in range(len(d_d_dict))]
except Exception as e:
    print(f"WARNING: Could not load disease labels. Error: {e}")
    cat_disease_labels = []
    dog_disease_labels = []

# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
app = FastAPI(
    title="Pet Breed & Disease AI",
    description="Two-stage species + breed/disease identification for cats and dogs.",
    version="1.1.0",
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

    Used for breed and disease models that have a built-in Lambda(preprocess_input) layer;
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


# ---------------------------------------------------------------------------
# 1. BREED PREDICTION ENDPOINT (Original)
# ---------------------------------------------------------------------------
@app.post("/predict", tags=["inference"])
async def predict(file: UploadFile = File(...)):
    """
    Accept a JPEG/PNG image and return:
    - detected species (cat | dog) with confidence
    - top-5 breed predictions with confidence scores
    """
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
    sp_probs = species_model(sp_arr, training=False).numpy()[0]

    if sp_probs.shape == (1,):
        dog_prob = float(sp_probs[0])
        if dog_prob > 0.5:
            sp_label = "dog"
            sp_conf = dog_prob
        else:
            sp_label = "cat"
            sp_conf = 1.0 - dog_prob
    else:
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


# ---------------------------------------------------------------------------
# 3. PASSWORD RESET ENDPOINT
# ---------------------------------------------------------------------------
class _ResetPasswordRequest(BaseModel):
    email: str
    new_password: str


@app.post("/reset-password", tags=["auth"])
async def reset_password(body: _ResetPasswordRequest):
    """
    Reset a user's Firebase Auth password in-app after OTP verification.
    Requires backend/serviceAccount.json (Firebase Admin SDK).
    """
    if not _firebase_admin_ready:
        raise HTTPException(
            status_code=503,
            detail="Password reset service unavailable: serviceAccount.json missing on server.",
        )

    email = body.email.strip().lower()
    new_password = body.new_password

    if len(new_password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters.")

    try:
        user = firebase_auth_admin.get_user_by_email(email)
        firebase_auth_admin.update_user(user.uid, password=new_password)
        print(f"[RESET] Password updated for uid={user.uid}")
        return {"success": True, "message": "Password updated successfully."}
    except firebase_auth_admin.UserNotFoundError:
        raise HTTPException(status_code=404, detail="No account found with this email.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update password: {e}")


# ---------------------------------------------------------------------------
# 2. SKIN DISEASE PREDICTION ENDPOINT (New)
# ---------------------------------------------------------------------------
@app.post("/predict-disease", tags=["inference"])
async def predict_disease(file: UploadFile = File(...)):
    """
    Accept a JPEG/PNG image and return:
    - detected species (cat | dog) with confidence
    - top disease predictions with confidence scores
    """
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
    
    try:
        sp_arr = _preprocess_raw(data, _SPECIES_SIZE)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Could not decode image: {exc}")

    # Stage 1 — species detection (Same logic as above)
    sp_probs = species_model(sp_arr, training=False).numpy()[0]

    if sp_probs.shape == (1,):
        dog_prob = float(sp_probs[0])
        if dog_prob > 0.5:
            sp_label = "dog"
            sp_conf = dog_prob
        else:
            sp_label = "cat"
            sp_conf = 1.0 - dog_prob
    else:
        sp_idx = int(np.argmax(sp_probs))
        sp_label = species_labels[str(sp_idx)]
        sp_conf = float(sp_probs[sp_idx])

    # Stage 2 — Disease identification
    try:
        if sp_label == "cat":
            dis_arr = _preprocess_raw(data, _CAT_DISEASE_SIZE)
            dis_probs = cat_disease_model(dis_arr, training=False).numpy()[0]
            dis_labels = cat_disease_labels
        else:
            dis_arr = _preprocess_raw(data, _DOG_DISEASE_SIZE)
            dis_probs = dog_disease_model(dis_arr, training=False).numpy()[0]
            dis_labels = dog_disease_labels
            
        print(f"[TIMING] disease done: {time.perf_counter()-t0:.2f}s total")

        # Return top 3 predictions for disease (instead of 5)
        return {
            "species": {"label": sp_label, "confidence": sp_conf},
            "disease_predictions": _top_k(dis_probs, dis_labels, k=3),
        }
    except NameError:
        raise HTTPException(
            status_code=500, 
            detail="Disease models are not loaded. Please check backend files."
        )