import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns

# Загрузка данных
data = pd.read_csv('client_service_dataset.csv', sep=';', encoding='cp1251')

# Предобработка данных
# Удаление дубликатов
data = data.drop_duplicates()

# Заполнение пропущенных значений
data = data.fillna(method='ffill')

# Выбор признаков и целевой переменной
features = ['client_status', 'bonus_points', 'visit_count', 'days_to_complete', 
            'device_type', 'order_total', 'service_center_type', 'service_price', 
            'payment_method', 'pay_status']
target = 'service_name'

# Кодирование категориальных признаков
label_encoders = {}
for col in ['client_status', 'device_type', 'service_center_type', 'payment_method', 'pay_status']:
    le = LabelEncoder()
    data[col] = le.fit_transform(data[col])
    label_encoders[col] = le

# Подготовка данных
X = data[features]
y = data[target]

# Разделение на train и test
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)

# Масштабирование числовых признаков
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# Обучение модели
model = RandomForestClassifier(n_estimators=100, random_state=42, max_depth=10)
model.fit(X_train_scaled, y_train)

# Предсказания
y_pred = model.predict(X_test_scaled)

# Оценка модели
accuracy = accuracy_score(y_test, y_pred)
print(f"Accuracy: {accuracy:.2f}")

# Метрики
print("\nClassification Report:")
print(classification_report(y_test, y_pred))

# Матрица ошибок
plt.figure(figsize=(10, 8))
conf_matrix = confusion_matrix(y_test, y_pred)
sns.heatmap(conf_matrix, annot=True, fmt='d', cmap='Blues')
plt.title('Confusion Matrix')
plt.xlabel('Predicted')
plt.ylabel('Actual')
plt.show()

# Важность признаков
feature_importances = pd.DataFrame({
    'Feature': features,
    'Importance': model.feature_importances_
}).sort_values('Importance', ascending=False)

plt.figure(figsize=(10, 6))
sns.barplot(x='Importance', y='Feature', data=feature_importances)
plt.title('Feature Importances')
plt.show()

# Тестовое предсказание
test_sample = X_test_scaled[0:1]
predicted_service = model.predict(test_sample)
print(f"\nTest Prediction: {predicted_service[0]}")
print(f"Actual Service: {y_test.iloc[0]}")

