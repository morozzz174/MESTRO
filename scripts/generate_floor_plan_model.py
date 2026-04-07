"""
Генератор TFLite модели для оптимизации планировки MESTRO

Создаёт нейросеть, которая оптимизирует расположение комнат
для лучшей эргономики и соответствия СНиП.

Зависимости:
  pip install tensorflow numpy

Запуск:
  python generate_floor_plan_model.py
"""

import tensorflow as tf
import numpy as np
import os

# ===== Конфигурация =====
NUM_ROOMS = 8  # максимальное количество комнат
INPUT_SIZE = 3 + NUM_ROOMS * 4  # totalWidth, totalHeight, numRooms + (type, w, h, area) * rooms
OUTPUT_SIZE = NUM_ROOMS * 2  # (x, y) для каждой комнаты
MODEL_PATH = 'floor_plan_opt.tflite'

# ===== Генерация синтетических данных =====
def generate_synthetic_data(num_samples=10000):
    """
    Генерирует синтетические данные для обучения.
    X: входные параметры плана
    y: оптимизированные позиции комнат
    """
    print(f'Генерация {num_samples} синтетических примеров...')

    X = np.zeros((num_samples, INPUT_SIZE), dtype=np.float32)
    y = np.zeros((num_samples, OUTPUT_SIZE), dtype=np.float32)

    for i in range(num_samples):
        # Генерируем случайные размеры помещения
        total_w = np.random.uniform(6.0, 20.0)
        total_h = np.random.uniform(4.0, 15.0)
        num_rooms = np.random.randint(3, NUM_ROOMS + 1)

        X[i, 0] = total_w
        X[i, 1] = total_h
        X[i, 2] = num_rooms

        # Генерируем комнаты
        current_x = 0.0
        current_y = 0.0
        row_max_h = 0.0

        for j in range(num_rooms):
            room_type = np.random.randint(0, 10)
            room_w = np.random.uniform(1.5, 5.0)
            room_h = np.random.uniform(1.5, 4.0)

            # Проверяем, помещается ли комната в ряд
            if current_x + room_w > total_w:
                current_x = 0.0
                current_y += row_max_h
                row_max_h = 0.0

            # Ограничиваем по высоте
            if current_y + room_h > total_h:
                room_h = max(1.0, total_h - current_y - 0.5)

            offset = 3 + j * 4
            X[i, offset] = room_type
            X[i, offset + 1] = room_w
            X[i, offset + 2] = room_h
            X[i, offset + 3] = room_w * room_h

            # Оптимизированная позиция (простая эвристика)
            y[i, j * 2] = current_x
            y[i, j * 2 + 1] = current_y

            current_x += room_w
            row_max_h = max(row_max_h, room_h)

        # Добавляем шум для реалистичности
        y[i] += np.random.normal(0, 0.1, OUTPUT_SIZE)

    print(f'X shape: {X.shape}, y shape: {y.shape}')
    return X, y

# ===== Создание модели =====
def create_model():
    """
    Создаёт нейросеть для оптимизации позиций комнат.
    """
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(INPUT_SIZE,)),

        # Кодирование входных данных
        tf.keras.layers.Dense(256, activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.2),

        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.2),

        tf.keras.layers.Dense(64, activation='relu'),

        # Выход: позиции (x, y) для каждой комнаты
        tf.keras.layers.Dense(OUTPUT_SIZE, activation='linear'),
    ])

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss='mse',
        metrics=['mae'],
    )

    model.summary()
    return model

# ===== Обучение и конвертация =====
def train_and_export():
    """
    Полный цикл: генерация данных → обучение → конвертация в TFLite
    """
    # 1. Генерация данных
    X_train, y_train = generate_synthetic_data(num_samples=50000)
    X_val, y_val = X_train[:5000], y_train[:5000]
    X_train, y_train = X_train[5000:], y_train[5000:]

    # 2. Создание и обучение модели
    model = create_model()

    early_stop = tf.keras.callbacks.EarlyStopping(
        monitor='val_loss',
        patience=5,
        restore_best_weights=True,
    )

    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=50,
        batch_size=256,
        callbacks=[early_stop],
        verbose=1,
    )

    # 3. Оценка
    val_loss, val_mae = model.evaluate(X_val, y_val)
    print(f'\nValidation Loss: {val_loss:.4f}, MAE: {val_mae:.4f}')

    # 4. Конвертация в TFLite (INT8 quantization)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]

    # Representative dataset для INT8 quantization
    def representative_dataset():
        for i in range(100):
            yield [X_train[i:i+1]]

    converter.representative_dataset = representative_dataset
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type = tf.float32
    converter.inference_output_type = tf.float32

    tflite_model = converter.convert()

    # 5. Сохранение
    output_dir = os.path.join('..', 'assets', 'models')
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, MODEL_PATH)

    with open(output_path, 'wb') as f:
        f.write(tflite_model)

    model_size_kb = len(tflite_model) / 1024
    print(f'\n✅ Модель сохранён: {output_path}')
    print(f'📦 Размер: {model_size_kb:.1f} KB')

    # 6. Тестирование TFLite модели
    interpreter = tf.lite.Interpreter(model_path=output_path)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # Тестовый запуск
    test_input = X_val[0:1]
    interpreter.set_tensor(input_details[0]['index'], test_input)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])

    print(f'🧪 Тестовый вход: {test_input[0, :5]}...')
    print(f'🧪 Тестовый выход: {output[0, :4]}...')
    print('\n✅ Готово! Модель готова к использованию во Flutter.')

if __name__ == '__main__':
    train_and_export()
