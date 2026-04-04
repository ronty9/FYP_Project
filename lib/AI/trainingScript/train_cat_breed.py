import argparse
import json
import random
from pathlib import Path

import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from tensorflow.keras.applications import EfficientNetB0

AUTOTUNE = tf.data.AUTOTUNE


def set_seed(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    tf.random.set_seed(seed)


def parse_args():
    parser = argparse.ArgumentParser(description="Train cat breed classifier with EfficientNetB0")
    parser.add_argument("--data_root", type=str, required=True, help="Folder containing train/val/test")
    parser.add_argument("--out_dir", type=str, default="/home/stfd/fyp_data/cat_train_effnet_12_18")
    parser.add_argument("--img_size", type=int, default=224)
    parser.add_argument("--batch", type=int, default=16)
    parser.add_argument("--epochs1", type=int, default=12)
    parser.add_argument("--epochs2", type=int, default=18)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--n_unfreeze", type=int, default=120)
    parser.add_argument("--mixed_precision", action="store_true")
    parser.add_argument("--ignore_decode_errors", action="store_true")
    return parser.parse_args()


def maybe_enable_mixed_precision(enabled: bool) -> None:
    if enabled:
        try:
            from tensorflow.keras import mixed_precision
            mixed_precision.set_global_policy("mixed_float16")
            print("Mixed precision enabled: mixed_float16")
        except Exception as e:
            print(f"Could not enable mixed precision: {e}")


def build_datasets(data_root: Path, img_size: int, batch_size: int, ignore_decode_errors: bool):
    train_dir = data_root / "train"
    val_dir = data_root / "val"
    test_dir = data_root / "test"

    for d in [train_dir, val_dir, test_dir]:
        if not d.exists():
            raise FileNotFoundError(f"Missing folder: {d}")

    common = dict(
        image_size=(img_size, img_size),
        batch_size=batch_size,
        label_mode="int",
    )

    train_ds = keras.utils.image_dataset_from_directory(
        train_dir,
        shuffle=True,
        seed=42,
        **common,
    )
    val_ds = keras.utils.image_dataset_from_directory(
        val_dir,
        shuffle=False,
        **common,
    )
    test_ds = keras.utils.image_dataset_from_directory(
        test_dir,
        shuffle=False,
        **common,
    )

    class_names = train_ds.class_names
    num_classes = len(class_names)

    if ignore_decode_errors:
        train_ds = train_ds.apply(tf.data.experimental.ignore_errors())
        val_ds = val_ds.apply(tf.data.experimental.ignore_errors())
        test_ds = test_ds.apply(tf.data.experimental.ignore_errors())

    train_ds = train_ds.prefetch(AUTOTUNE)
    val_ds = val_ds.prefetch(AUTOTUNE)
    test_ds = test_ds.prefetch(AUTOTUNE)

    return train_ds, val_ds, test_ds, class_names, num_classes


def build_model(img_size: int, num_classes: int):
    data_augmentation = keras.Sequential(
        [
            layers.RandomFlip("horizontal"),
            layers.RandomRotation(0.05),
            layers.RandomZoom(0.10),
        ],
        name="data_augmentation",
    )

    base_model = EfficientNetB0(
        include_top=False,
        weights="imagenet",
        input_shape=(img_size, img_size, 3),
    )
    base_model.trainable = False

    inputs = keras.Input(shape=(img_size, img_size, 3), name="image")
    x = data_augmentation(inputs)
    x = base_model(x, training=False)
    x = layers.GlobalAveragePooling2D(name="gap")(x)
    x = layers.Dropout(0.30, name="dropout")(x)
    outputs = layers.Dense(num_classes, activation="softmax", dtype="float32", name="predictions")(x)

    model = keras.Model(inputs, outputs, name="cat_breed_effnetb0")
    return model, base_model


def compile_stage1(model: keras.Model):
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=[
            "accuracy",
            keras.metrics.SparseTopKCategoricalAccuracy(k=3, name="top3_acc"),
        ],
    )


def compile_stage2(model: keras.Model):
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=3e-6),
        loss="sparse_categorical_crossentropy",
        metrics=[
            "accuracy",
            keras.metrics.SparseTopKCategoricalAccuracy(k=3, name="top3_acc"),
        ],
    )


def unfreeze_top_layers(base_model: keras.Model, n_unfreeze: int):
    base_model.trainable = True

    if n_unfreeze <= 0:
        for layer in base_model.layers:
            layer.trainable = False
        return

    freeze_until = max(0, len(base_model.layers) - n_unfreeze)

    for i, layer in enumerate(base_model.layers):
        if i < freeze_until:
            layer.trainable = False
        else:
            # keep BatchNorm frozen for stable fine-tuning
            if isinstance(layer, layers.BatchNormalization):
                layer.trainable = False
            else:
                layer.trainable = True


def make_callbacks(out_dir: Path, ckpt_name: str, csv_name: str, append_csv: bool):
    return [
        keras.callbacks.ModelCheckpoint(
            filepath=str(out_dir / ckpt_name),
            monitor="val_accuracy",
            mode="max",
            save_best_only=True,
            verbose=1,
        ),
        keras.callbacks.EarlyStopping(
            monitor="val_accuracy",
            mode="max",
            patience=6,
            restore_best_weights=True,
            verbose=1,
        ),
        keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=2,
            min_lr=1e-7,
            verbose=1,
        ),
        keras.callbacks.CSVLogger(str(out_dir / csv_name), append=append_csv),
    ]


def save_labels(class_names, out_dir: Path, labels_name: str):
    payload = {
        "class_names": class_names,
        "class_to_index": {name: idx for idx, name in enumerate(class_names)},
        "index_to_class": {str(idx): name for idx, name in enumerate(class_names)},
    }
    with open(out_dir / labels_name, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)


def save_history(histories: dict, out_dir: Path):
    payload = {}
    for stage_name, history in histories.items():
        payload[stage_name] = history.history

    with open(out_dir / "history.json", "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)


def evaluate_model(model: keras.Model, ds):
    values = model.evaluate(ds, verbose=0)
    return {name: float(val) for name, val in zip(model.metrics_names, values)}


def choose_best_model(out_dir: Path, val_ds):
    stage1_path = out_dir / "cat_breed_stage1_best.keras"
    stage2_path = out_dir / "cat_breed_stage2_best.keras"

    candidates = []

    if stage1_path.exists():
        model1 = keras.models.load_model(stage1_path)
        metrics1 = evaluate_model(model1, val_ds)
        candidates.append(("stage1", model1, metrics1, stage1_path))

    if stage2_path.exists():
        model2 = keras.models.load_model(stage2_path)
        metrics2 = evaluate_model(model2, val_ds)
        candidates.append(("stage2", model2, metrics2, stage2_path))

    if not candidates:
        raise FileNotFoundError("No saved checkpoint found to choose from.")

    best_name, best_model, best_metrics, best_path = max(
        candidates,
        key=lambda x: x[2].get("accuracy", float("-inf"))
    )

    selection_info = {
        "chosen_stage": best_name,
        "source_path": str(best_path),
        "validation_metrics": best_metrics,
        "all_candidates": {
            item[0]: item[2] for item in candidates
        },
    }

    with open(out_dir / "model_selection.json", "w", encoding="utf-8") as f:
        json.dump(selection_info, f, indent=2)

    return best_model, selection_info


def save_test_outputs(model: keras.Model, test_ds, class_names, out_dir: Path):
    results = model.evaluate(test_ds, verbose=1)
    result_dict = {name: float(val) for name, val in zip(model.metrics_names, results)}

    with open(out_dir / "test_results.json", "w", encoding="utf-8") as f:
        json.dump(result_dict, f, indent=2)

    y_true = []
    y_pred = []

    for batch_x, batch_y in test_ds:
        preds = model.predict(batch_x, verbose=0)
        y_true.extend(batch_y.numpy().tolist())
        y_pred.extend(np.argmax(preds, axis=1).tolist())

    cm = tf.math.confusion_matrix(
        y_true,
        y_pred,
        num_classes=len(class_names),
    ).numpy()

    np.savetxt(out_dir / "confusion_matrix_test.csv", cm, fmt="%d", delimiter=",")

    print("Saved test results:", out_dir / "test_results.json")
    print("Saved confusion matrix:", out_dir / "confusion_matrix_test.csv")


def main():
    args = parse_args()
    set_seed(args.seed)
    maybe_enable_mixed_precision(args.mixed_precision)

    data_root = Path(args.data_root)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    print("========== CONFIG ==========")
    print(f"Data root      : {data_root}")
    print(f"Output dir     : {out_dir}")
    print(f"Image size     : {args.img_size}")
    print(f"Batch size     : {args.batch}")
    print(f"Stage 1 epochs : {args.epochs1}")
    print(f"Stage 2 epochs : {args.epochs2}")
    print(f"Seed           : {args.seed}")
    print(f"Unfreeze top   : {args.n_unfreeze}")
    print("============================")

    train_ds, val_ds, test_ds, class_names, num_classes = build_datasets(
        data_root=data_root,
        img_size=args.img_size,
        batch_size=args.batch,
        ignore_decode_errors=args.ignore_decode_errors,
    )

    print(f"Classes found: {num_classes}")
    print("Class names:", class_names)

    save_labels(class_names, out_dir, "cat_labels.json")

    model, base_model = build_model(args.img_size, num_classes)

    histories = {}

    print("\n===== STAGE 1: TRAIN HEAD =====")
    compile_stage1(model)
    callbacks_stage1 = make_callbacks(
        out_dir=out_dir,
        ckpt_name="cat_breed_stage1_best.keras",
        csv_name="training_log.csv",
        append_csv=False,
    )
    hist1 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=args.epochs1,
        callbacks=callbacks_stage1,
        verbose=1,
    )
    histories["stage1"] = hist1

    if args.epochs2 > 0:
        print("\n===== STAGE 2: FINE-TUNE =====")
        unfreeze_top_layers(base_model, args.n_unfreeze)
        compile_stage2(model)
        callbacks_stage2 = make_callbacks(
            out_dir=out_dir,
            ckpt_name="cat_breed_stage2_best.keras",
            csv_name="training_log.csv",
            append_csv=True,
        )
        hist2 = model.fit(
            train_ds,
            validation_data=val_ds,
            epochs=args.epochs2,
            callbacks=callbacks_stage2,
            verbose=1,
        )
        histories["stage2"] = hist2

    save_history(histories, out_dir)

    print("\n===== SELECT BEST MODEL =====")
    best_model, selection_info = choose_best_model(out_dir, val_ds)
    final_model_path = out_dir / "cat_breed.keras"
    best_model.save(final_model_path)
    print("Chosen stage:", selection_info["chosen_stage"])
    print("Final model :", final_model_path)

    print("\n===== TEST EVALUATION =====")
    save_test_outputs(best_model, test_ds, class_names, out_dir)

    print("\nDone.")
    print(f"Model  : {out_dir / 'cat_breed.keras'}")
    print(f"Labels : {out_dir / 'cat_labels.json'}")
    print(f"Log    : {out_dir / 'training_log.csv'}")


if __name__ == "__main__":
    main()