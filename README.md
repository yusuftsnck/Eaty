

#  Eaty
### Integrated Food, Grocery & AI Ecosystem  "All in One"

**A modern, cloud-native super app that unifies food delivery, grocery shopping, and AI-powered recipe generation.**

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/></a>
  <a href="https://fastapi.tiangolo.com"><img src="https://img.shields.io/badge/FastAPI-Backend-009688?style=for-the-badge&logo=fastapi&logoColor=white"/></a>
  <a href="https://www.postgresql.org"><img src="https://img.shields.io/badge/PostgreSQL-Database-336791?style=for-the-badge&logo=postgresql&logoColor=white"/></a>
  <a href="https://cloud.google.com/run"><img src="https://img.shields.io/badge/Google%20Cloud-Run-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white"/></a>
  <a href="https://deepmind.google/technologies/gemini/"><img src="https://img.shields.io/badge/Gemini%20AI-Powered-8E75B2?style=for-the-badge"/></a>
</p>

</div>

---

## ✨ Why Eaty?

Most users rely on **multiple apps** for food delivery, grocery shopping, and recipes.  
Eaty brings all of these experiences together into **one intelligent ecosystem**.

With **AI-powered cooking assistance**, a **unified marketplace**, and a **business management panel**, Eaty is designed to simplify daily food decisions for consumers while empowering food businesses with modern digital tools.

---

## 🧠 Key Highlights

- 🍽 **Unified Food & Grocery Marketplace**
- 🤖 **AI Recipe Assistant (Text & Image Based)**
- 🏪 **Business Dashboard for Restaurants & Markets**
- ☁️ **Cloud-Native & Scalable Architecture**
- 🔐 **Secure Authentication with Firebase**

---

## 🚀 Features

### Consumer Experience (B2C)
- Browse restaurants and markets from a single interface  
- Generate recipes by entering ingredients or uploading a photo  
- Smart cart and smooth checkout flow  
- Live order status tracking  

### Business Experience (B2B)
- Accept or reject orders in real-time  
- Manage menus, categories, and product images  
- Track daily revenue and order analytics  
- One-tap open / close store status  

---

## 🏗 Architecture Overview

```mermaid
graph LR
    A[Flutter Mobile App] -->|REST / JSON| B[FastAPI Backend]
    B --> C[(PostgreSQL / Cloud SQL)]
    B --> D[Google Gemini AI]
    B --> E[Firebase Authentication]
```

### Design Principles
- Stateless backend services  
- Horizontal scalability via Cloud Run  
- Modular and maintainable architecture  

---

## 🛠 Tech Stack

| Layer | Technology |
|-----|-----------|
| Mobile | Flutter |
| Backend | FastAPI (Python) |
| Database | PostgreSQL |
| Cloud | Google Cloud Run |
| AI | Google Gemini Pro |
| Auth | Firebase Authentication |

---

## 📱 website
https://yusuftsnck.github.io/website/ 

---

## ⚡ Getting Started

### Requirements
- Flutter 3.x+
- Python 3.10+
- Google Cloud Project (Cloud SQL + Gemini API enabled)

### Installation

```bash
git clone https://github.com/yusuftsnck/Eaty.git
cd Eaty
```

#### Backend
```bash
cd api
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

#### Mobile
```bash
flutter pub get
flutter run
```


---

## 🛣 Roadmap

- [ ] Multi-language support (EN / AR)
- [ ] Health-aware AI (diet & allergies)
- [ ] Real-time courier tracking
- [ ] Promotions & campaigns for businesses

---

## 👨‍💻 Author

**Yusuf Şaban Tosuncuk**  
Software Engineering Student  

🔗 GitHub: https://github.com/yusuftsnck  

---


