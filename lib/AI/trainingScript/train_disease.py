import tensorflow as tf
from tensorflow.keras.preprocessing import image_dataset_from_directory
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras import layers, models, callbacks
import numpy as np
import json
import os

# ==========================================
#              CONFIGURATION
# ==========================================
BATCH_SIZE = 32
IMG_SIZE = (224, 224)
STAGE_1_EPOCHS = 15  # Increased to 15
STAGE_2_EPOCHS = 15  # Increased to 15 for deeper fine-tuning

def train_model(species_name, dataset_dir):
    print(f"\n--- Training {species_name.upper()} Disease Model ---")
    
    # 1. Load Data
    train_dataset = image_dataset_from_directory(
        dataset_dir, validation_split=0.2, subset="training",
        seed=123, image_size=IMG_SIZE, batch_size=BATCH_SIZE
    )
    val_dataset = image_dataset_from_directory(
        dataset_dir, validation_split=0.2, subset="validation",
        seed=123, image_size=IMG_SIZE, batch_size=BATCH_SIZE
    )

    # 2. Extract and Save Labels
    class_names = train_dataset.class_names
    num_classes = len(class_names)
    label_dict = {str(i): name for i, name in enumerate(class_names)}
    
    json_filename = f"{species_name}_disease_labels.json"
    with open(json_filename, 'w') as f:
        json.dump(label_dict, f, indent=4)
    print(f"Saved labels to {json_filename}")

    AUTOTUNE = tf.data.AUTOTUNE
    train_dataset = train_dataset.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
    val_dataset = val_dataset.cache().prefetch(buffer_size=AUTOTUNE)

    # 3. Data Augmentation
    data_augmentation = tf.keras.Sequential([
        layers.RandomFlip("horizontal"),
        layers.RandomRotation(0.2), # ±20° rotation
        layers.RandomZoom(0.1),
    ], name="data_augmentation")

    # 4. Build Model (Transfer Learning)
    base_model = MobileNetV2(input_shape=IMG_SIZE + (3,), include_top=False, weights='imagenet')
    base_model.trainable = False  # Freeze base model for Stage 1

    inputs = tf.keras.Input(shape=IMG_SIZE + (3,))
    x = data_augmentation(inputs) 
    x = tf.keras.applications.mobilenet_v2.preprocess_input(x)
    x = base_model(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.2)(x)
    outputs = layers.Dense(num_classes, activation='softmax')(x)

    model = models.Model(inputs, outputs)

    # 5. Define Callbacks (This prevents overfitting even with 15 epochs)
    model_filename = f"{species_name}_disease_model.keras"
    my_callbacks = [
        callbacks.ModelCheckpoint(filepath=model_filename, save_best_only=True, monitor='val_accuracy'),
        callbacks.EarlyStopping(patience=4, restore_best_weights=True, monitor='val_accuracy')
    ]

    # ==========================================
    #      STAGE 1: TRAIN TOP LAYER ONLY
    # ==========================================
    print(f"\n--- STAGE 1: Training Top Layers (Max {STAGE_1_EPOCHS} Epochs) ---")
    model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
                  loss='sparse_categorical_crossentropy',
                  metrics=['accuracy'])
                  
    model.fit(train_dataset, validation_data=val_dataset, epochs=STAGE_1_EPOCHS, callbacks=my_callbacks)

    # ==========================================
    #      STAGE 2: FINE-TUNING
    # ==========================================
    print(f"\n--- STAGE 2: Fine-Tuning MobileNetV2 (Max {STAGE_2_EPOCHS} Epochs) ---")
    base_model.trainable = True
    
    # Freeze all layers except the last 20 for fine-tuning
    for layer in base_model.layers[:-20]:
        layer.trainable = False

    # Recompile with a lower learning rate
    model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
                  loss='sparse_categorical_crossentropy',
                  metrics=['accuracy'])

    model.fit(train_dataset, validation_data=val_dataset, epochs=STAGE_2_EPOCHS, callbacks=my_callbacks)

    # ==========================================
    #          TEST EVALUATION SECTION
    # ==========================================
    print("\n" + "="*40)
    print(f"   FINAL EVALUATION: {species_name.upper()} MODEL")
    print("="*40)

    model = tf.keras.models.load_model(model_filename)
    test_loss, test_accuracy = model.evaluate(val_dataset, verbose=1)
    print(f"\nFinal Test Accuracy: {test_accuracy * 100:.2f}%")

    # Generate Confusion Matrix
    print("\nGenerating Confusion Matrix data...")
    y_true = []
    y_pred = []
    
    for images, labels in val_dataset:
        preds = model.predict(images, verbose=0)
        y_true.extend(labels.numpy().tolist())
        y_pred.extend(np.argmax(preds, axis=1).tolist())

    cm = tf.math.confusion_matrix(y_true, y_pred, num_classes=num_classes).numpy()
    cm_filename = f"{species_name}_confusion_matrix.csv"
    np.savetxt(cm_filename, cm, fmt="%d", delimiter=",")
    print(f"Saved confusion matrix to {cm_filename}")
    print("==========================================\n")

# Execute the training for both folders
if os.path.exists("dataset/dogs"):
    train_model("dog", "dataset/dogs")
else:
    print("Error: dataset/dogs folder not found.")

if os.path.exists("dataset/cats"):
    train_model("cat", "dataset/cats")
else:
    print("Error: dataset/cats folder not found.")