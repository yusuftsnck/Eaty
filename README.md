# Eaty - Integrated Food, Grocery, and AI-Powered Recipe Platform

![Eaty Banner](https://via.placeholder.com/1000x300?text=Eaty+Super+App) > **"All in One" Ecosystem:** Unified Food Delivery, Grocery Shopping, and AI Kitchen Assistant.

## 📋 Executive Summary
[cite_start]**Eaty** is a comprehensive mobile application developed under the "Super App" concept[cite: 29]. [cite_start]It addresses the fragmented user experience of modern nutritional needs by unifying food ordering, grocery shopping, and recipe generation under a single roof[cite: 31].

[cite_start]Powered by **Google Cloud** technologies and **Gemini AI**, Eaty provides a scalable solution for end-users (B2C) while offering a robust management dashboard for businesses (B2B)[cite: 30, 32].

---

## 🚀 Key Features

### 📱 Consumer Module (B2C)
The consumer-facing application focuses on ease of use and smart decision-making.
* [cite_start]**Unified Marketplace:** Seamlessly switch between ordering ready-to-eat meals from restaurants and buying fresh produce from markets[cite: 40].
* **AI Chef (Gemini Powered):** Solves "decision fatigue" by generating personalized recipes based on ingredients you currently have. [cite_start]Supports **image recognition** (take a photo of ingredients) and text input[cite: 41, 65].
* [cite_start]**Recipe Social Network:** Create personal "Recipe Notebooks," share your own culinary creations, and save community recipes[cite: 77, 653].
* [cite_start]**Real-Time Order Tracking:** Monitor order status instantly (Preparing -> With Courier -> Delivered)[cite: 75].
* [cite_start]**Dynamic Cart:** Easy addition/removal of products and secure checkout[cite: 73].

### 💼 Business Module (B2B)
A professional dashboard designed for restaurants and markets to manage operations efficiently.
* [cite_start]**Order Lifecycle Management:** Single-screen workflow to Approve/Reject orders, hand over to the kitchen, and assign to couriers[cite: 84, 85].
* [cite_start]**Menu Engineering:** Drag-and-drop sorting, easy category management, and photo uploads directly from the device[cite: 80, 82].
* [cite_start]**Business Analytics:** Dashboard providing a graphical summary of daily revenue, total delivered orders, and active order status[cite: 79].
* [cite_start]**Quick Actions:** One-tap toggle for "Open/Closed" status and operating hours management[cite: 88].

---

## 🛠 Technology Stack & Architecture

[cite_start]Eaty relies on a modern, stateless, cloud-native architecture[cite: 90].

| Component | Technology | Details |
| :--- | :--- | :--- |
| **Mobile Framework** | Flutter (Dart) | [cite_start]Cross-platform Android application[cite: 52]. |
| **Backend API** | Python (FastAPI) | [cite_start]High-performance RESTful API[cite: 55]. |
| **Database** | PostgreSQL | [cite_start]Hosted on **Google Cloud SQL**[cite: 59]. |
| **Cloud Infrastructure**| Google Cloud Run | [cite_start]Containerized (Docker), auto-scaling architecture[cite: 60]. |
| **Artificial Intelligence**| Google Gemini API | [cite_start]Image processing & NLP for recipe generation[cite: 64]. |
| **Authentication** | Firebase | [cite_start]Google Sign-In & Firebase Auth integration[cite: 67]. |

### System Architecture
The mobile client communicates via JSON/REST with the FastAPI backend hosted on Cloud Run. [cite_start]The backend handles logic, connects to PostgreSQL via Unix Sockets, and interfaces with the Gemini API for AI requests[cite: 90, 91].

---

## 📸 Screenshots

| Login & Home | AI Chef | Restaurant Menu | Business Dashboard |
|:---:|:---:|:---:|:---:|
| <img src="path/to/login_screen.png" width="200"> | <img src="path/to/ai_chef.png" width="200"> | <img src="path/to/menu_screen.png" width="200"> | <img src="path/to/dashboard.png" width="200"> |
---

## 🔮 Future Roadmap
* [cite_start]**Multi-Language Support:** Expanding to English and Arabic for international markets[cite: 96].
* [cite_start]**Health-Focused AI:** Recipe filtering based on user allergies and diet history[cite: 97].
* [cite_start]**Live Logistics:** Real-time courier tracking integration on maps[cite: 98].

---

## 💿 Installation & Setup

### Prerequisites
* Flutter SDK
* Python 3.9+
* Docker (optional for backend containerization)
* Google Cloud Project (with Gemini API & Cloud SQL enabled)

### Running the App
1.  **Clone the repository**
    ```bash
    git clone [https://github.com/yusuftsnck/Eaty.git](https://github.com/yusuftsnck/Eaty.git)
    ```
2.  **Backend Setup**
    ```bash
    cd backend
    pip install -r requirements.txt
    uvicorn main:app --reload
    ```
3.  **Mobile Setup**
    ```bash
    cd mobile
    flutter pub get
    flutter run
    ```
    *(Note: Ensure you create a `.env` file with your API Keys for Firebase and Gemini)*

---



## 📞 Contact
* [cite_start]**Email:** yusuf.tsnck@gmail.com [cite: 845]
* [cite_start]**GitHub:** [github.com/yusuftsnck](https://github.com/yusuftsnck) [cite: 7]
