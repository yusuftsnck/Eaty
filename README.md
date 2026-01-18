# Eaty: Integrated Food, Grocery, & AI-Powered Recipe Ecosystem

**Eaty** is a comprehensive mobile application developed under the "Super App" concept. It is designed to unify three fundamental daily nutritional needs—ordering ready-to-eat food, grocery shopping, and generating recipes via AI—under a single, cohesive platform.

By leveraging **Google Cloud** technologies and **Gemini AI**, Eaty aims to eliminate the fragmented experience of switching between multiple apps while providing a scalable, cloud-based infrastructure for businesses to manage digitalization, menus, and orders.

## 📖 Table of Contents
- [The Problem](#the-problem)
- [The Solution](#the-solution)
- [Key Features](#key-features)
  - [Consumer Module (B2C)](#consumer-module-b2c)
  - [Business Module (B2B)](#business-module-b2b)
- [Technology Stack](#technology-stack)
- [System Architecture](#system-architecture)
- [Future Roadmap](#future-roadmap)

## 🧩 The Problem
Modern mobile users often face a disconnected experience when managing their nutrition:
1.  **Fragmented Ecosystem:** Users are forced to switch between different apps for food delivery, grocery shopping, and finding recipes.
2.  **Decision Fatigue:** Users often struggle with the question, "What can I cook with the ingredients I have at home?"
3.  **Business Inefficiency:** Restaurants and markets often face complex menu management processes and high digitalization barriers.

## 💡 The Solution
Eaty bridges the gap by offering a unified ecosystem:
* **Ready-to-Eat Food:** Fast ordering from partnered restaurants.
* **Grocery Shopping:** Quick procurement of essential food and daily needs.
* **AI Kitchen Assistant:** An intelligent agent that analyzes ingredients (via text or photo) to generate personalized cooking recipes.

## 🚀 Key Features

### Consumer Module (B2C)
* **Dual Marketplace:** Browse and order from both Restaurants and Grocery Markets within the same interface.
* **AI Chef (Gemini Powered):**
    * **Input:** Enter an ingredient list or snap a photo of the items in your fridge.
    * **Processing:** The app uses Gemini AI for image recognition and Natural Language Processing.
    * **Output:** Receive personalized recipe suggestions and step-by-step cooking instructions.
* **Recipe Social Network:**
    * Share your own culinary creations.
    * Create "Recipe Notebooks" to save favorite recipes from the community.
* **Live Order Tracking:** Real-time status updates (Preparing, With Courier, Delivered).
* **Dynamic Cart:** Seamlessly manage products and payments.

### Business Module (B2B)
A dedicated dashboard for Restaurant and Market partners:
* **Order Lifecycle Management:** A streamlined flow to Approve/Reject orders, send them to the Kitchen, and assign them to Couriers.
* **Menu Management:** Drag-and-drop product sorting, category management, and easy image uploading.
* **Business Analytics:** Graphical summaries of daily revenue, total orders, and active order statuses.
* **Profile Control:** One-tap toggle to open or close the business and update operating hours.

## 🛠 Technology Stack

The project is built on a modern, cloud-native stack ensuring scalability and performance.

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Mobile App** | **Flutter** (Dart) | Cross-platform frontend application. |
| **Backend API** | **Python** (FastAPI) | High-performance, asynchronous RESTful API. |
| **Database** | **PostgreSQL** | Relational database hosted on **Google Cloud SQL**. |
| **Cloud Service** | **Google Cloud Run** | Containerized, stateless architecture with auto-scaling. |
| **AI Service** | **Google Gemini API** | Powers the recipe generation and image analysis features. |
| **Auth** | **Firebase** | Handles Authentication and Google Sign-In. |

## 🏗 System Architecture
Eaty utilizes a **Stateless Backend Architecture**:
1.  **Client:** The Flutter mobile app sends REST/JSON requests via the API Gateway.
2.  **Server:** Python FastAPI runs inside Docker containers on Google Cloud Run.
3.  **Data:** The backend communicates with the PostgreSQL database via secure Unix Sockets.
4.  **AI:** Requests for recipe generation are offloaded to the external Google Gemini API.

This structure allows the system to auto-scale based on traffic density while maintaining data integrity.

## 🔮 Future Roadmap
* **Multi-Language Support:** Expanding the platform to support English and Arabic for international markets.
* **Health-Focused AI:** Advanced personalization to filter recipe suggestions based on user allergies and diet history.
* **Live Courier Tracking:** Integration with map services to show the courier's real-time location.

---

**Project By:** Yusuf Şaban Tosuncuk
