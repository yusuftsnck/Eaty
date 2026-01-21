import datetime
import os
import base64
import hashlib
import hmac
import json
from typing import List, Optional

from fastapi import FastAPI, HTTPException, Depends, Body
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Float, Boolean, ForeignKey, DateTime, text, func
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship


# --- Database Setup (SQLite) ---
DB_PATH = os.path.join(os.path.dirname(__file__), "eaty.db")
SQLALCHEMY_DATABASE_URL = f"sqlite:///{DB_PATH}"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


# --- Password helpers (PBKDF2) ---
def _hash_password(password: str) -> str:
    salt = os.urandom(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 200_000)
    return f"pbkdf2_sha256${base64.b64encode(salt).decode()}${base64.b64encode(dk).decode()}"


def _verify_password(password: str, stored: str) -> bool:
    try:
        algo, salt_b64, dk_b64 = stored.split("$", 2)
        if algo != "pbkdf2_sha256":
            return False
        salt = base64.b64decode(salt_b64.encode())
        dk_expected = base64.b64decode(dk_b64.encode())
        dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 200_000)
        return hmac.compare_digest(dk, dk_expected)
    except Exception:
        return False


# --- Models (Tablolar) ---
class BusinessDB(Base):
    __tablename__ = "businesses"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)

    name = Column(String)
    phone = Column(String)
    address = Column(String)
    category = Column(String)  # "food" | "market"
    photo_url = Column(String, nullable=True)
    min_order_amount = Column(Float, nullable=True)
    delivery_time_mins = Column(Integer, nullable=True)
    delivery_radius_km = Column(Float, nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    working_hours = Column(String, nullable=True)
    authorized_name = Column(String, nullable=True)
    authorized_surname = Column(String, nullable=True)
    company_name = Column(String, nullable=True)
    tckn = Column(String, nullable=True)
    restaurant_name = Column(String, nullable=True)
    kitchen_type = Column(String, nullable=True)
    city = Column(String, nullable=True)
    district = Column(String, nullable=True)
    neighborhood = Column(String, nullable=True)
    open_address = Column(String, nullable=True)

    password_hash = Column(String, nullable=True)  # email/şifre login için

    is_open = Column(Boolean, default=True)

    products = relationship("ProductDB", back_populates="business")
    orders = relationship("OrderDB", back_populates="business")


class CustomerProfileDB(Base):
    __tablename__ = "customer_profiles"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    name = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    updated_at = Column(
        DateTime,
        default=datetime.datetime.utcnow,
        onupdate=datetime.datetime.utcnow,
    )


class CustomerAddressDB(Base):
    __tablename__ = "customer_addresses"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, index=True)
    address_id = Column(String, index=True)
    label = Column(String)
    address_line = Column(String)
    neighborhood = Column(String)
    district = Column(String)
    city = Column(String)
    note = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    latitude = Column(Float)
    longitude = Column(Float)
    sequence = Column(Integer, default=0)
    updated_at = Column(
        DateTime,
        default=datetime.datetime.utcnow,
        onupdate=datetime.datetime.utcnow,
    )


class ProductDB(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True, index=True)
    business_id = Column(Integer, ForeignKey("businesses.id"))
    name = Column(String)
    description = Column(String)
    price = Column(Float)
    category = Column(String)
    image_url = Column(String, nullable=True)
    is_available = Column(Boolean, default=True)
    sequence = Column(Integer, default=0)
    business = relationship("BusinessDB", back_populates="products")


class OrderDB(Base):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True, index=True)
    business_id = Column(Integer, ForeignKey("businesses.id"))
    customer_email = Column(String)
    customer_name = Column(String, nullable=True)
    customer_phone = Column(String, nullable=True)
    customer_address = Column(String)
    customer_note = Column(String, nullable=True)
    total_price = Column(Float)
    status = Column(String, default="Onay Bekliyor")
    rejection_reason = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    items = relationship("OrderItemDB", back_populates="order")
    business = relationship("BusinessDB", back_populates="orders")


class OrderItemDB(Base):
    __tablename__ = "order_items"
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    product_name = Column(String)
    quantity = Column(Integer)
    price = Column(Float)
    order = relationship("OrderDB", back_populates="items")


class BusinessReviewDB(Base):
    __tablename__ = "business_reviews"
    id = Column(Integer, primary_key=True, index=True)
    business_id = Column(Integer, ForeignKey("businesses.id"))
    order_id = Column(Integer, ForeignKey("orders.id"), unique=True)
    customer_email = Column(String, index=True)
    rating = Column(Integer)
    speed_rating = Column(Integer, nullable=True)
    service_rating = Column(Integer, nullable=True)
    taste_rating = Column(Integer, nullable=True)
    comment = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    business = relationship("BusinessDB")
    order = relationship("OrderDB")


class RecipeDB(Base):
    __tablename__ = "recipes"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    subtitle = Column(String, nullable=True)
    story = Column(String, nullable=True)
    ingredients_json = Column(String, nullable=True)
    steps_json = Column(String, nullable=True)
    category = Column(String, nullable=True)
    servings = Column(String, nullable=True)
    prep_time = Column(String, nullable=True)
    cook_time = Column(String, nullable=True)
    equipment = Column(String, nullable=True)
    method = Column(String, nullable=True)
    cover_image_url = Column(String, nullable=True)
    gallery_json = Column(String, nullable=True)
    author_name = Column(String)
    author_email = Column(String)
    author_photo_url = Column(String, nullable=True)
    likes = Column(Integer, default=0)
    comments = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)


class RecipeCommentDB(Base):
    __tablename__ = "recipe_comments"
    id = Column(Integer, primary_key=True, index=True)
    recipe_id = Column(Integer, ForeignKey("recipes.id"), index=True)
    author_name = Column(String)
    author_email = Column(String, nullable=True)
    comment = Column(String)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)


class RecipeNotebookDB(Base):
    __tablename__ = "recipe_notebooks"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    cover_image_url = Column(String, nullable=True)
    owner_name = Column(String, nullable=True)
    owner_email = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    items = relationship(
        "RecipeNotebookItemDB",
        back_populates="notebook",
        cascade="all, delete-orphan",
    )


class RecipeNotebookItemDB(Base):
    __tablename__ = "recipe_notebook_items"
    id = Column(Integer, primary_key=True, index=True)
    notebook_id = Column(Integer, ForeignKey("recipe_notebooks.id"))
    recipe_id = Column(Integer, ForeignKey("recipes.id"))
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    notebook = relationship("RecipeNotebookDB", back_populates="items")


class RecipeLikeDB(Base):
    __tablename__ = "recipe_likes"
    id = Column(Integer, primary_key=True, index=True)
    recipe_id = Column(Integer, ForeignKey("recipes.id"))
    user_email = Column(String, index=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)


Base.metadata.create_all(bind=engine)


def _ensure_business_columns():
    with engine.begin() as conn:
        rows = conn.execute(text("PRAGMA table_info(businesses)")).fetchall()
        existing = {row[1] for row in rows}
        columns = {
            "min_order_amount": "REAL",
            "delivery_time_mins": "INTEGER",
            "delivery_radius_km": "REAL",
            "latitude": "REAL",
            "longitude": "REAL",
            "working_hours": "TEXT",
            "authorized_name": "TEXT",
            "authorized_surname": "TEXT",
            "company_name": "TEXT",
            "tckn": "TEXT",
            "restaurant_name": "TEXT",
            "kitchen_type": "TEXT",
            "city": "TEXT",
            "district": "TEXT",
            "neighborhood": "TEXT",
            "open_address": "TEXT",
        }
        for name, col_type in columns.items():
            if name not in existing:
                conn.execute(
                    text(f"ALTER TABLE businesses ADD COLUMN {name} {col_type}")
                )


_ensure_business_columns()


def _ensure_order_columns():
    with engine.begin() as conn:
        rows = conn.execute(text("PRAGMA table_info(orders)")).fetchall()
        if not rows:
            return
        existing = {row[1] for row in rows}
        columns = {
            "customer_name": "TEXT",
            "customer_phone": "TEXT",
            "customer_note": "TEXT",
        }
        for name, col_type in columns.items():
            if name not in existing:
                conn.execute(text(f"ALTER TABLE orders ADD COLUMN {name} {col_type}"))


_ensure_order_columns()


def _ensure_recipe_columns():
    with engine.begin() as conn:
        rows = conn.execute(text("PRAGMA table_info(recipes)")).fetchall()
        existing = {row[1] for row in rows}
        columns = {
            "subtitle": "TEXT",
            "story": "TEXT",
            "ingredients_json": "TEXT",
            "steps_json": "TEXT",
            "category": "TEXT",
            "servings": "TEXT",
            "prep_time": "TEXT",
            "cook_time": "TEXT",
            "equipment": "TEXT",
            "method": "TEXT",
            "cover_image_url": "TEXT",
            "gallery_json": "TEXT",
            "author_name": "TEXT",
            "author_email": "TEXT",
            "author_photo_url": "TEXT",
            "likes": "INTEGER",
            "comments": "INTEGER",
            "created_at": "DATETIME",
        }
        for name, col_type in columns.items():
            if name not in existing:
                conn.execute(text(f"ALTER TABLE recipes ADD COLUMN {name} {col_type}"))


_ensure_recipe_columns()


def _ensure_business_review_columns():
    with engine.begin() as conn:
        rows = conn.execute(text("PRAGMA table_info(business_reviews)")).fetchall()
        if not rows:
            return
        existing = {row[1] for row in rows}
        columns = {
            "speed_rating": "INTEGER",
            "service_rating": "INTEGER",
            "taste_rating": "INTEGER",
        }
        for name, col_type in columns.items():
            if name not in existing:
                conn.execute(
                    text(f"ALTER TABLE business_reviews ADD COLUMN {name} {col_type}")
                )


_ensure_business_review_columns()


# --- Pydantic Schemas ---
class BusinessRegister(BaseModel):
    email: str
    name: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    category: str  # "food" | "market"
    photo_url: Optional[str] = None
    password: Optional[str] = None  # email/şifre kayıtta dolu gelir
    min_order_amount: Optional[float] = None
    delivery_time_mins: Optional[int] = None
    delivery_radius_km: Optional[float] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    working_hours: Optional[str] = None
    authorized_name: Optional[str] = None
    authorized_surname: Optional[str] = None
    company_name: Optional[str] = None
    tckn: Optional[str] = None
    restaurant_name: Optional[str] = None
    kitchen_type: Optional[str] = None
    city: Optional[str] = None
    district: Optional[str] = None
    neighborhood: Optional[str] = None
    open_address: Optional[str] = None


class BusinessPublic(BaseModel):
    id: int
    email: str
    name: str
    phone: Optional[str] = None
    address: Optional[str] = None
    category: str
    photo_url: Optional[str] = None
    min_order_amount: Optional[float] = None
    delivery_time_mins: Optional[int] = None
    delivery_radius_km: Optional[float] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    is_open: bool
    rating_avg: Optional[float] = None
    rating_count: Optional[int] = None
    rating_speed_avg: Optional[float] = None
    rating_service_avg: Optional[float] = None
    rating_taste_avg: Optional[float] = None

    class Config:
        from_attributes = True


class BusinessProfile(BusinessPublic):
    working_hours: Optional[str] = None
    authorized_name: Optional[str] = None
    authorized_surname: Optional[str] = None
    company_name: Optional[str] = None
    tckn: Optional[str] = None
    restaurant_name: Optional[str] = None
    kitchen_type: Optional[str] = None
    city: Optional[str] = None
    district: Optional[str] = None
    neighborhood: Optional[str] = None
    open_address: Optional[str] = None


class BusinessLogin(BaseModel):
    email: str
    password: str


class BusinessProfileUpdate(BaseModel):
    address: Optional[str] = None
    phone: Optional[str] = None
    photo_url: Optional[str] = None
    min_order_amount: Optional[float] = None
    delivery_time_mins: Optional[int] = None
    delivery_radius_km: Optional[float] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    working_hours: Optional[str] = None


class CustomerProfileOut(BaseModel):
    email: str
    name: Optional[str] = None
    phone: Optional[str] = None

    class Config:
        from_attributes = True


class CustomerProfileUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None


class CustomerAddressIn(BaseModel):
    id: str
    label: str
    addressLine: str
    neighborhood: str
    district: str
    city: str
    note: Optional[str] = None
    phone: Optional[str] = None
    latitude: float
    longitude: float


class CustomerAddressOut(CustomerAddressIn):
    class Config:
        from_attributes = True


class BusinessPasswordReset(BaseModel):
    email: str
    password: str


class ProductCreate(BaseModel):
    name: str
    description: str
    price: float
    category: str
    image_url: Optional[str] = None
    is_available: bool = True


class OrderItemCreate(BaseModel):
    product_name: str
    quantity: int
    price: float


class OrderCreate(BaseModel):
    business_id: int
    customer_email: str
    customer_name: Optional[str] = None
    customer_phone: Optional[str] = None
    customer_address: str
    customer_note: Optional[str] = None
    total_price: float
    items: List[OrderItemCreate]


class CustomerOrderItem(BaseModel):
    product_name: str
    quantity: int
    price: float


class CustomerOrderOut(BaseModel):
    id: int
    business_id: int
    business_name: str
    business_email: Optional[str] = None
    business_photo_url: Optional[str] = None
    business_address: Optional[str] = None
    business_category: str
    status: str
    total_price: float
    customer_address: Optional[str] = None
    created_at: datetime.datetime
    items: List[CustomerOrderItem]
    reviewed: bool = False


class ReorderItem(BaseModel):
    id: int
    sequence: int


class OrderStatusUpdate(BaseModel):
    status: str
    reason: Optional[str] = None


class BusinessReviewCreate(BaseModel):
    customer_email: str
    rating: int
    speed_rating: Optional[int] = None
    service_rating: Optional[int] = None
    taste_rating: Optional[int] = None
    comment: Optional[str] = None


class BusinessReviewOut(BaseModel):
    id: int
    business_id: int
    order_id: int
    customer_email: str
    rating: int
    speed_rating: Optional[int] = None
    service_rating: Optional[int] = None
    taste_rating: Optional[int] = None
    comment: Optional[str] = None
    created_at: datetime.datetime

    class Config:
        from_attributes = True


class RecipeCreate(BaseModel):
    title: str
    subtitle: Optional[str] = None
    story: Optional[str] = None
    ingredients: List[str] = []
    steps: List[str] = []
    category: Optional[str] = None
    servings: Optional[str] = None
    prep_time: Optional[str] = None
    cook_time: Optional[str] = None
    equipment: Optional[str] = None
    method: Optional[str] = None
    cover_image_url: Optional[str] = None
    gallery_images: List[str] = []
    author_name: str
    author_email: str
    author_photo_url: Optional[str] = None


class RecipeOut(BaseModel):
    id: int
    title: str
    subtitle: Optional[str] = None
    story: Optional[str] = None
    ingredients: List[str] = []
    steps: List[str] = []
    category: Optional[str] = None
    servings: Optional[str] = None
    prep_time: Optional[str] = None
    cook_time: Optional[str] = None
    equipment: Optional[str] = None
    method: Optional[str] = None
    cover_image_url: Optional[str] = None
    gallery_images: List[str] = []
    author_name: str
    author_email: str
    author_photo_url: Optional[str] = None
    likes: int
    comments: int
    saves: int
    created_at: datetime.datetime
    is_liked: Optional[bool] = None


class RecipeUpdate(BaseModel):
    user_email: Optional[str] = None
    title: Optional[str] = None
    subtitle: Optional[str] = None
    story: Optional[str] = None
    ingredients: Optional[List[str]] = None
    steps: Optional[List[str]] = None
    category: Optional[str] = None
    servings: Optional[str] = None
    prep_time: Optional[str] = None
    cook_time: Optional[str] = None
    equipment: Optional[str] = None
    method: Optional[str] = None
    cover_image_url: Optional[str] = None
    gallery_images: Optional[List[str]] = None


class RecipeCommentCreate(BaseModel):
    author_name: Optional[str] = None
    author_email: Optional[str] = None
    comment: str


class RecipeCommentOut(BaseModel):
    id: int
    recipe_id: int
    author_name: str
    comment: str
    created_at: datetime.datetime

    class Config:
        from_attributes = True


class RecipeLikeToggle(BaseModel):
    user_email: str


class RecipeNotebookCreate(BaseModel):
    title: str
    cover_image_url: Optional[str] = None
    owner_name: Optional[str] = None
    owner_email: Optional[str] = None


class RecipeNotebookUpdate(BaseModel):
    title: Optional[str] = None
    cover_image_url: Optional[str] = None


class RecipeNotebookItemCreate(BaseModel):
    recipe_id: int


class RecipeNotebookOut(BaseModel):
    id: int
    title: str
    cover_image_url: Optional[str] = None
    owner_name: Optional[str] = None
    owner_email: Optional[str] = None
    recipe_ids: List[int] = []
    created_at: datetime.datetime


# --- FastAPI App ---
app = FastAPI()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _parse_json_list(raw: Optional[str]) -> List[str]:
    if not raw:
        return []
    try:
        data = json.loads(raw)
        if isinstance(data, list):
            return [str(item) for item in data if str(item).strip()]
    except Exception:
        return []
    return []


def _get_recipe_comment_counts(
    db: Session,
    recipe_ids: List[int],
) -> dict[int, int]:
    if not recipe_ids:
        return {}
    rows = (
        db.query(RecipeCommentDB.recipe_id, func.count(RecipeCommentDB.id))
        .filter(RecipeCommentDB.recipe_id.in_(recipe_ids))
        .group_by(RecipeCommentDB.recipe_id)
        .all()
    )
    return {int(row[0]): int(row[1]) for row in rows}


def _get_recipe_save_counts(db: Session, recipe_ids: List[int]) -> dict[int, int]:
    if not recipe_ids:
        return {}
    rows = (
        db.query(RecipeNotebookItemDB.recipe_id, func.count(RecipeNotebookItemDB.id))
        .filter(RecipeNotebookItemDB.recipe_id.in_(recipe_ids))
        .group_by(RecipeNotebookItemDB.recipe_id)
        .all()
    )
    return {int(row[0]): int(row[1]) for row in rows}


def _recipe_to_out(
    recipe: RecipeDB,
    liked_ids: Optional[set] = None,
    comment_counts: Optional[dict[int, int]] = None,
    save_counts: Optional[dict[int, int]] = None,
) -> RecipeOut:
    is_liked = None
    if liked_ids is not None:
        is_liked = recipe.id in liked_ids
    comment_count = (
        comment_counts.get(recipe.id, recipe.comments or 0)
        if comment_counts is not None
        else (recipe.comments or 0)
    )
    save_count = (
        save_counts.get(recipe.id, 0) if save_counts is not None else 0
    )
    return RecipeOut(
        id=recipe.id,
        title=recipe.title,
        subtitle=recipe.subtitle,
        story=recipe.story,
        ingredients=_parse_json_list(recipe.ingredients_json),
        steps=_parse_json_list(recipe.steps_json),
        category=recipe.category,
        servings=recipe.servings,
        prep_time=recipe.prep_time,
        cook_time=recipe.cook_time,
        equipment=recipe.equipment,
        method=recipe.method,
        cover_image_url=recipe.cover_image_url,
        gallery_images=_parse_json_list(recipe.gallery_json),
        author_name=recipe.author_name,
        author_email=recipe.author_email,
        author_photo_url=recipe.author_photo_url,
        likes=recipe.likes or 0,
        comments=comment_count,
        saves=save_count,
        created_at=recipe.created_at,
        is_liked=is_liked,
    )


def _notebook_to_out(notebook: RecipeNotebookDB) -> RecipeNotebookOut:
    return RecipeNotebookOut(
        id=notebook.id,
        title=notebook.title,
        cover_image_url=notebook.cover_image_url,
        owner_name=notebook.owner_name,
        owner_email=notebook.owner_email,
        recipe_ids=[item.recipe_id for item in notebook.items],
        created_at=notebook.created_at,
    )


def _address_to_out(address: CustomerAddressDB) -> CustomerAddressOut:
    return CustomerAddressOut(
        id=address.address_id,
        label=address.label or "",
        addressLine=address.address_line or "",
        neighborhood=address.neighborhood or "",
        district=address.district or "",
        city=address.city or "",
        note=address.note,
        phone=address.phone,
        latitude=address.latitude or 0,
        longitude=address.longitude or 0,
    )


def _attach_business_ratings(db: Session, businesses: List[BusinessDB]) -> None:
    if not businesses:
        return
    ids = [biz.id for biz in businesses]
    speed_expr = func.coalesce(
        BusinessReviewDB.speed_rating, BusinessReviewDB.rating
    )
    service_expr = func.coalesce(
        BusinessReviewDB.service_rating, BusinessReviewDB.rating
    )
    taste_expr = func.coalesce(
        BusinessReviewDB.taste_rating, BusinessReviewDB.rating
    )
    avg_expr = (speed_expr + service_expr + taste_expr) / 3.0
    rows = (
        db.query(
            BusinessReviewDB.business_id,
            func.avg(avg_expr),
            func.count(BusinessReviewDB.id),
            func.avg(speed_expr),
            func.avg(service_expr),
            func.avg(taste_expr),
        )
        .filter(BusinessReviewDB.business_id.in_(ids))
        .group_by(BusinessReviewDB.business_id)
        .all()
    )
    by_id = {row[0]: row[1:] for row in rows}
    for biz in businesses:
        stats = by_id.get(biz.id)
        if not stats:
            biz.rating_avg = None
            biz.rating_count = 0
            biz.rating_speed_avg = None
            biz.rating_service_avg = None
            biz.rating_taste_avg = None
            continue
        avg, count, speed_avg, service_avg, taste_avg = stats
        biz.rating_avg = float(avg) if avg is not None else None
        biz.rating_count = int(count or 0)
        biz.rating_speed_avg = float(speed_avg) if speed_avg is not None else None
        biz.rating_service_avg = (
            float(service_avg) if service_avg is not None else None
        )
        biz.rating_taste_avg = float(taste_avg) if taste_avg is not None else None


_DAY_KEYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
_TURKEY_UTC_OFFSET = datetime.timedelta(hours=3)


def _turkey_now() -> datetime.datetime:
    return datetime.datetime.utcnow() + _TURKEY_UTC_OFFSET


def _time_to_minutes(value: str) -> Optional[int]:
    parts = value.strip().split(":")
    if len(parts) != 2:
        return None
    try:
        hour = int(parts[0])
        minute = int(parts[1])
    except ValueError:
        return None
    if not (0 <= hour <= 23 and 0 <= minute <= 59):
        return None
    return hour * 60 + minute


def _is_within_working_hours(
    working_hours: Optional[str], now: Optional[datetime.datetime] = None
) -> Optional[bool]:
    if not working_hours:
        return None
    try:
        data = json.loads(working_hours)
    except Exception:
        return None
    if not isinstance(data, dict):
        return None
    current = now or _turkey_now()
    day_key = _DAY_KEYS[current.weekday()]
    day_data = data.get(day_key)
    if not isinstance(day_data, dict):
        return False
    if day_data.get("closed") is True:
        return False
    open_str = day_data.get("open")
    close_str = day_data.get("close")
    if not open_str or not close_str:
        return False
    open_minutes = _time_to_minutes(str(open_str))
    close_minutes = _time_to_minutes(str(close_str))
    if open_minutes is None or close_minutes is None:
        return False
    if open_minutes == close_minutes:
        return True
    now_minutes = current.hour * 60 + current.minute
    if open_minutes < close_minutes:
        return open_minutes <= now_minutes < close_minutes
    return now_minutes >= open_minutes or now_minutes < close_minutes


def _attach_business_open_status(businesses: List[BusinessDB]) -> None:
    if not businesses:
        return
    now = _turkey_now()
    for biz in businesses:
        manual_open = True if biz.is_open is None else bool(biz.is_open)
        schedule_open = _is_within_working_hours(biz.working_hours, now)
        if schedule_open is None:
            biz.is_open = manual_open
        else:
            biz.is_open = manual_open and schedule_open



# 1) İşletme Kaydı (Google veya Email/Şifre)
@app.post("/register/business")
def register_business(business: BusinessRegister, db: Session = Depends(get_db)):
    normalized_email = business.email.strip().lower()
    db_biz = (
        db.query(BusinessDB)
        .filter(func.lower(BusinessDB.email) == normalized_email)
        .first()
    )
    if db_biz:
        raise HTTPException(status_code=400, detail="Email already registered")

    if business.category not in ("food", "market"):
        raise HTTPException(status_code=400, detail="Invalid category (food/market)")

    display_name = business.name or business.restaurant_name or business.company_name
    if not display_name:
        raise HTTPException(status_code=400, detail="Business name is required")

    address_parts = [
        business.open_address,
        business.neighborhood,
        business.district,
        business.city,
    ]
    computed_address = ", ".join(
        [part.strip() for part in address_parts if part and part.strip()]
    )
    address = business.address or computed_address or None

    pw_hash = None
    if business.password:
        password = business.password.strip()
        if len(password) < 6:
            raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
        pw_hash = _hash_password(password)

    new_biz = BusinessDB(
        email=normalized_email,
        name=display_name,
        phone=business.phone,
        address=address,
        category=business.category,
        photo_url=business.photo_url,
        min_order_amount=business.min_order_amount,
        delivery_time_mins=business.delivery_time_mins,
        delivery_radius_km=business.delivery_radius_km,
        latitude=business.latitude,
        longitude=business.longitude,
        working_hours=business.working_hours,
        authorized_name=business.authorized_name,
        authorized_surname=business.authorized_surname,
        company_name=business.company_name,
        tckn=business.tckn,
        restaurant_name=business.restaurant_name,
        kitchen_type=business.kitchen_type,
        city=business.city,
        district=business.district,
        neighborhood=business.neighborhood,
        open_address=business.open_address,
        password_hash=pw_hash,
    )
    db.add(new_biz)
    db.commit()
    db.refresh(new_biz)
    return {"message": "Business registered", "id": new_biz.id}


# 2) İşletme Email/Şifre Giriş (Panel)
@app.post("/auth/business/login", response_model=BusinessProfile)
def business_login(payload: BusinessLogin, db: Session = Depends(get_db)):
    normalized_email = payload.email.strip().lower()
    biz = (
        db.query(BusinessDB)
        .filter(func.lower(BusinessDB.email) == normalized_email)
        .first()
    )
    if not biz:
        raise HTTPException(status_code=404, detail="Business not found")

    if not biz.password_hash:
        raise HTTPException(status_code=400, detail="This business has no password login (use Google)")

    if not _verify_password(payload.password.strip(), biz.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    _attach_business_open_status([biz])
    return biz


# Dev-only: reset password for local testing
@app.post("/auth/business/reset-password")
def reset_business_password(payload: BusinessPasswordReset, db: Session = Depends(get_db)):
    normalized_email = payload.email.strip().lower()
    biz = (
        db.query(BusinessDB)
        .filter(func.lower(BusinessDB.email) == normalized_email)
        .first()
    )
    if not biz:
        raise HTTPException(status_code=404, detail="Business not found")

    password = payload.password.strip()
    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

    biz.password_hash = _hash_password(password)
    db.commit()
    return {"message": "Password updated"}


# 3) İşletme Bilgisi
@app.get("/business/{email}", response_model=BusinessProfile)
def get_business(email: str, db: Session = Depends(get_db)):
    normalized_email = email.strip().lower()
    biz = (
        db.query(BusinessDB)
        .filter(func.lower(BusinessDB.email) == normalized_email)
        .first()
    )
    if not biz:
        raise HTTPException(status_code=404, detail="Business not found")
    _attach_business_ratings(db, [biz])
    _attach_business_open_status([biz])
    return biz


# 3b) İşletme Profilini Güncelle
@app.put("/business/{email}/profile", response_model=BusinessProfile)
def update_business_profile(
    email: str, payload: BusinessProfileUpdate, db: Session = Depends(get_db)
):
    normalized_email = email.strip().lower()
    biz = (
        db.query(BusinessDB)
        .filter(func.lower(BusinessDB.email) == normalized_email)
        .first()
    )
    if not biz:
        raise HTTPException(status_code=404, detail="Business not found")

    if payload.address is not None:
        biz.address = payload.address
    if payload.phone is not None:
        biz.phone = payload.phone
    if payload.photo_url is not None:
        biz.photo_url = payload.photo_url
    if payload.min_order_amount is not None:
        biz.min_order_amount = payload.min_order_amount
    if payload.delivery_time_mins is not None:
        biz.delivery_time_mins = payload.delivery_time_mins
    if payload.delivery_radius_km is not None:
        biz.delivery_radius_km = payload.delivery_radius_km
    if payload.latitude is not None:
        biz.latitude = payload.latitude
    if payload.longitude is not None:
        biz.longitude = payload.longitude
    if payload.working_hours is not None:
        biz.working_hours = payload.working_hours

    db.commit()
    db.refresh(biz)
    _attach_business_open_status([biz])
    return biz


# 3c) Customer profile (name/phone)
@app.get("/customers/{email}/profile", response_model=CustomerProfileOut)
def get_customer_profile(email: str, db: Session = Depends(get_db)):
    normalized_email = email.strip().lower()
    if not normalized_email:
        raise HTTPException(status_code=400, detail="Email is required")

    profile = (
        db.query(CustomerProfileDB)
        .filter(func.lower(CustomerProfileDB.email) == normalized_email)
        .first()
    )
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile


@app.put("/customers/{email}/profile", response_model=CustomerProfileOut)
def update_customer_profile(
    email: str, payload: CustomerProfileUpdate, db: Session = Depends(get_db)
):
    normalized_email = email.strip().lower()
    if not normalized_email:
        raise HTTPException(status_code=400, detail="Email is required")

    name = payload.name.strip() if payload.name is not None else None
    phone = payload.phone.strip() if payload.phone is not None else None

    profile = (
        db.query(CustomerProfileDB)
        .filter(func.lower(CustomerProfileDB.email) == normalized_email)
        .first()
    )
    if profile is None:
        if not name:
            raise HTTPException(status_code=400, detail="Name is required")
        profile = CustomerProfileDB(email=normalized_email, name=name, phone=phone)
        db.add(profile)
    else:
        if name is not None:
            profile.name = name or None
        if phone is not None:
            profile.phone = phone or None

    profile.updated_at = datetime.datetime.utcnow()
    db.commit()
    db.refresh(profile)
    return profile


# 3d) Customer addresses
@app.get("/customers/{email}/addresses", response_model=List[CustomerAddressOut])
def get_customer_addresses(email: str, db: Session = Depends(get_db)):
    normalized_email = email.strip().lower()
    if not normalized_email:
        raise HTTPException(status_code=400, detail="Email is required")

    rows = (
        db.query(CustomerAddressDB)
        .filter(func.lower(CustomerAddressDB.email) == normalized_email)
        .order_by(CustomerAddressDB.sequence.asc())
        .all()
    )
    return [_address_to_out(row) for row in rows]


@app.put("/customers/{email}/addresses", response_model=List[CustomerAddressOut])
def replace_customer_addresses(
    email: str, payload: List[CustomerAddressIn], db: Session = Depends(get_db)
):
    normalized_email = email.strip().lower()
    if not normalized_email:
        raise HTTPException(status_code=400, detail="Email is required")

    db.query(CustomerAddressDB).filter(
        func.lower(CustomerAddressDB.email) == normalized_email
    ).delete()

    rows: List[CustomerAddressDB] = []
    for index, address in enumerate(payload):
        address_id = address.id.strip()
        if not address_id:
            continue
        row = CustomerAddressDB(
            email=normalized_email,
            address_id=address_id,
            label=address.label.strip(),
            address_line=address.addressLine.strip(),
            neighborhood=address.neighborhood.strip(),
            district=address.district.strip(),
            city=address.city.strip(),
            note=address.note.strip() if address.note else None,
            phone=address.phone.strip() if address.phone else None,
            latitude=address.latitude,
            longitude=address.longitude,
            sequence=index,
        )
        rows.append(row)
        db.add(row)

    db.commit()
    return [_address_to_out(row) for row in rows]


# 4) Kategori Bazlı İşletmeler
@app.get("/businesses/{category}", response_model=List[BusinessPublic])
def get_businesses_by_category(category: str, db: Session = Depends(get_db)):
    if category not in ("food", "market"):
        raise HTTPException(status_code=400, detail="Invalid category")
    businesses = (
        db.query(BusinessDB).filter(BusinessDB.category == category).all()
    )
    _attach_business_ratings(db, businesses)
    _attach_business_open_status(businesses)
    return businesses


# 5) Ürün Ekle
@app.post("/business/{email}/products")
def add_product(email: str, product: ProductCreate, db: Session = Depends(get_db)):
    biz = db.query(BusinessDB).filter(BusinessDB.email == email).first()
    if not biz:
        raise HTTPException(status_code=404, detail="Business not found")

    new_product = ProductDB(**product.dict(), business_id=biz.id)
    db.add(new_product)
    db.commit()
    return {"message": "Product added"}


# 6) Menü Listele
@app.get("/business/{id}/menu")
def get_menu(id: int, db: Session = Depends(get_db)):
    return db.query(ProductDB).filter(ProductDB.business_id == id).order_by(ProductDB.sequence.asc()).all()


# 7) Sipariş Oluştur
@app.post("/orders")
def place_order(order: OrderCreate, db: Session = Depends(get_db)):
    customer_name = order.customer_name.strip() if order.customer_name else None
    customer_phone = order.customer_phone.strip() if order.customer_phone else None
    customer_note = order.customer_note.strip() if order.customer_note else None
    if customer_name == "":
        customer_name = None
    if customer_phone == "":
        customer_phone = None
    if customer_note == "":
        customer_note = None
    new_order = OrderDB(
        business_id=order.business_id,
        customer_email=order.customer_email,
        customer_name=customer_name,
        customer_phone=customer_phone,
        customer_address=order.customer_address,
        customer_note=customer_note,
        total_price=order.total_price,
        status="Onay Bekliyor"
    )
    db.add(new_order)
    db.commit()
    db.refresh(new_order)

    for item in order.items:
        db_item = OrderItemDB(**item.dict(), order_id=new_order.id)
        db.add(db_item)

    db.commit()
    return {"message": "Order placed", "id": new_order.id}


# 8) İşletme Siparişleri
@app.get("/business/{email}/orders")
def get_business_orders(email: str, db: Session = Depends(get_db)):
    biz = db.query(BusinessDB).filter(BusinessDB.email == email).first()
    if not biz:
        return []
    orders = db.query(OrderDB).filter(OrderDB.business_id == biz.id).order_by(OrderDB.created_at.desc()).all()

    result = []
    for o in orders:
        items = [{"product_name": i.product_name, "quantity": i.quantity, "price": i.price} for i in o.items]
        result.append({
            "id": o.id,
            "customer_name": o.customer_name,
            "customer_phone": o.customer_phone,
            "customer_address": o.customer_address,
            "customer_note": o.customer_note,
            "total_price": o.total_price,
            "status": o.status,
            "rejection_reason": o.rejection_reason,
            "created_at": o.created_at.isoformat(),
            "items": items
        })
    return result


# 8b) Müşteri Siparişleri
@app.get("/orders/customer/{email}", response_model=List[CustomerOrderOut])
def get_customer_orders(email: str, db: Session = Depends(get_db)):
    normalized_email = email.strip().lower()
    orders = (
        db.query(OrderDB)
        .filter(func.lower(OrderDB.customer_email) == normalized_email)
        .order_by(OrderDB.created_at.desc())
        .all()
    )
    order_ids = [order.id for order in orders]
    reviewed_ids = set()
    if order_ids:
        rows = (
            db.query(BusinessReviewDB.order_id)
            .filter(BusinessReviewDB.order_id.in_(order_ids))
            .all()
        )
        reviewed_ids = {row[0] for row in rows}
    result = []
    for order in orders:
        biz = db.query(BusinessDB).filter(BusinessDB.id == order.business_id).first()
        items = [
            {
                "product_name": item.product_name,
                "quantity": item.quantity,
                "price": item.price,
            }
            for item in order.items
        ]
        result.append(
            {
                "id": order.id,
                "business_id": order.business_id,
                "business_name": biz.name if biz else "İşletme",
                "business_email": biz.email if biz else None,
                "business_photo_url": biz.photo_url if biz else None,
                "business_address": biz.address if biz else None,
                "business_category": biz.category if biz else "food",
                "status": order.status,
                "total_price": order.total_price,
                "customer_address": order.customer_address,
                "created_at": order.created_at,
                "items": items,
                "reviewed": order.id in reviewed_ids,
            }
        )
    return result


# 8c) Sipariş Değerlendirme
@app.post("/orders/{order_id}/review", response_model=BusinessReviewOut)
def create_order_review(
    order_id: int, payload: BusinessReviewCreate, db: Session = Depends(get_db)
):
    order = db.query(OrderDB).filter(OrderDB.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    status = (order.status or "").strip().lower()
    if status not in ("teslim edildi", "teslim"):
        raise HTTPException(status_code=400, detail="Order not delivered")

    normalized_email = payload.customer_email.strip().lower()
    if normalized_email != (order.customer_email or "").strip().lower():
        raise HTTPException(status_code=403, detail="Not allowed to review")

    if not (1 <= payload.rating <= 5):
        raise HTTPException(status_code=400, detail="Rating must be 1-5")

    speed = payload.speed_rating
    service = payload.service_rating
    taste = payload.taste_rating
    if speed is None or service is None or taste is None:
        speed = payload.rating
        service = payload.rating
        taste = payload.rating
    for value in (speed, service, taste):
        if not (1 <= value <= 5):
            raise HTTPException(status_code=400, detail="Rating must be 1-5")
    rating = (
        int(round((speed + service + taste) / 3.0))
        if payload.speed_rating is not None
        or payload.service_rating is not None
        or payload.taste_rating is not None
        else payload.rating
    )

    existing = (
        db.query(BusinessReviewDB)
        .filter(BusinessReviewDB.order_id == order_id)
        .first()
    )
    if existing:
        raise HTTPException(status_code=400, detail="Review already exists")

    comment = payload.comment.strip() if payload.comment else None
    review = BusinessReviewDB(
        business_id=order.business_id,
        order_id=order.id,
        customer_email=normalized_email,
        rating=rating,
        speed_rating=speed,
        service_rating=service,
        taste_rating=taste,
        comment=comment,
    )
    db.add(review)
    db.commit()
    db.refresh(review)
    return review


# 8d) İşletme Yorumları
@app.get("/business/{business_id}/reviews", response_model=List[BusinessReviewOut])
def get_business_reviews(
    business_id: int,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    limit = max(1, min(limit, 200))
    reviews = (
        db.query(BusinessReviewDB)
        .filter(BusinessReviewDB.business_id == business_id)
        .order_by(BusinessReviewDB.created_at.desc())
        .limit(limit)
        .all()
    )
    return reviews


# 9) Ürün Güncelleme
@app.put("/products/{product_id}")
def update_product(product_id: int, product: ProductCreate, db: Session = Depends(get_db)):
    db_product = db.query(ProductDB).filter(ProductDB.id == product_id).first()
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found")

    db_product.name = product.name
    db_product.description = product.description
    db_product.price = product.price
    db_product.category = product.category
    db_product.image_url = product.image_url
    db_product.is_available = product.is_available

    db.commit()
    db.refresh(db_product)
    return {"message": "Product updated"}


# 10) Ürün Silme
@app.delete("/products/{product_id}")
def delete_product(product_id: int, db: Session = Depends(get_db)):
    db_product = db.query(ProductDB).filter(ProductDB.id == product_id).first()
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found")

    db.delete(db_product)
    db.commit()
    return {"message": "Product deleted"}


# 11) Sıralama Güncelleme
@app.post("/products/reorder")
def reorder_products(items: List[ReorderItem], db: Session = Depends(get_db)):
    for item in items:
        db_product = db.query(ProductDB).filter(ProductDB.id == item.id).first()
        if db_product:
            db_product.sequence = item.sequence
    db.commit()
    return {"message": "Order updated"}


# 12) SİPARİŞ DURUMU GÜNCELLEME
@app.put("/orders/{order_id}/status")
def update_order_status(order_id: int, update: OrderStatusUpdate, db: Session = Depends(get_db)):
    order = db.query(OrderDB).filter(OrderDB.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    order.status = update.status
    if update.reason:
        order.rejection_reason = update.reason

    db.commit()
    return {"message": "Status updated"}


# 13) İŞLETME DURUMU (AÇIK/KAPALI)
@app.put("/business/{email}/status")
def update_business_status(email: str, is_open: bool = Body(..., embed=True), db: Session = Depends(get_db)):
    biz = db.query(BusinessDB).filter(BusinessDB.email == email).first()
    if not biz:
        raise HTTPException(status_code=404, detail="Business not found")

    biz.is_open = is_open
    db.commit()
    return {"message": "Status updated"}


# 14) Tarif Ekle
@app.post("/recipes", response_model=RecipeOut)
def create_recipe(payload: RecipeCreate, db: Session = Depends(get_db)):
    title = payload.title.strip()
    if not title:
        raise HTTPException(status_code=400, detail="Recipe title is required")

    author_email = payload.author_email.strip().lower()
    if not author_email:
        raise HTTPException(status_code=400, detail="Author email is required")

    recipe = RecipeDB(
        title=title,
        subtitle=payload.subtitle,
        story=payload.story,
        ingredients_json=json.dumps(payload.ingredients or []),
        steps_json=json.dumps(payload.steps or []),
        category=payload.category,
        servings=payload.servings,
        prep_time=payload.prep_time,
        cook_time=payload.cook_time,
        equipment=payload.equipment,
        method=payload.method,
        cover_image_url=payload.cover_image_url,
        gallery_json=json.dumps(payload.gallery_images or []),
        author_name=payload.author_name.strip() or "Kullanici",
        author_email=author_email,
        author_photo_url=payload.author_photo_url,
        likes=0,
        comments=0,
    )
    db.add(recipe)
    db.commit()
    db.refresh(recipe)
    comment_counts = {recipe.id: recipe.comments or 0}
    save_counts = _get_recipe_save_counts(db, [recipe.id])
    return _recipe_to_out(
        recipe,
        comment_counts=comment_counts,
        save_counts=save_counts,
    )


# 14b) Tarif Guncelle
@app.put("/recipes/{recipe_id}", response_model=RecipeOut)
def update_recipe(recipe_id: int, payload: RecipeUpdate, db: Session = Depends(get_db)):
    recipe = db.query(RecipeDB).filter(RecipeDB.id == recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    user_email = (payload.user_email or "").strip().lower()
    if not user_email:
        raise HTTPException(status_code=400, detail="User email is required")
    if user_email != (recipe.author_email or "").strip().lower():
        raise HTTPException(status_code=403, detail="Not authorized")

    if payload.title is not None:
        title = payload.title.strip()
        if not title:
            raise HTTPException(status_code=400, detail="Recipe title is required")
        recipe.title = title
    if payload.subtitle is not None:
        recipe.subtitle = payload.subtitle
    if payload.story is not None:
        recipe.story = payload.story
    if payload.ingredients is not None:
        recipe.ingredients_json = json.dumps(payload.ingredients or [])
    if payload.steps is not None:
        recipe.steps_json = json.dumps(payload.steps or [])
    if payload.category is not None:
        recipe.category = payload.category
    if payload.servings is not None:
        recipe.servings = payload.servings
    if payload.prep_time is not None:
        recipe.prep_time = payload.prep_time
    if payload.cook_time is not None:
        recipe.cook_time = payload.cook_time
    if payload.equipment is not None:
        recipe.equipment = payload.equipment
    if payload.method is not None:
        recipe.method = payload.method
    if payload.cover_image_url is not None:
        recipe.cover_image_url = payload.cover_image_url
    if payload.gallery_images is not None:
        recipe.gallery_json = json.dumps(payload.gallery_images or [])

    db.commit()
    db.refresh(recipe)
    comment_counts = _get_recipe_comment_counts(db, [recipe.id])
    save_counts = _get_recipe_save_counts(db, [recipe.id])
    return _recipe_to_out(
        recipe,
        comment_counts=comment_counts,
        save_counts=save_counts,
    )


# 14c) Tarif Sil
@app.delete("/recipes/{recipe_id}")
def delete_recipe(recipe_id: int, user_email: Optional[str] = None, db: Session = Depends(get_db)):
    recipe = db.query(RecipeDB).filter(RecipeDB.id == recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    normalized = (user_email or "").strip().lower()
    if not normalized:
        raise HTTPException(status_code=400, detail="User email is required")
    if normalized != (recipe.author_email or "").strip().lower():
        raise HTTPException(status_code=403, detail="Not authorized")

    db.query(RecipeCommentDB).filter(
        RecipeCommentDB.recipe_id == recipe_id
    ).delete()
    db.query(RecipeLikeDB).filter(RecipeLikeDB.recipe_id == recipe_id).delete()
    db.query(RecipeNotebookItemDB).filter(
        RecipeNotebookItemDB.recipe_id == recipe_id
    ).delete()
    db.delete(recipe)
    db.commit()
    return {"message": "Recipe deleted"}


# 14d) Tarif Begen
@app.post("/recipes/{recipe_id}/like")
def toggle_recipe_like(
    recipe_id: int,
    payload: RecipeLikeToggle,
    db: Session = Depends(get_db),
):
    user_email = payload.user_email.strip().lower()
    if not user_email:
        raise HTTPException(status_code=400, detail="User email is required")

    recipe = db.query(RecipeDB).filter(RecipeDB.id == recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    existing = (
        db.query(RecipeLikeDB)
        .filter(
            RecipeLikeDB.recipe_id == recipe_id,
            func.lower(RecipeLikeDB.user_email) == user_email,
        )
        .first()
    )

    if existing:
        db.delete(existing)
        recipe.likes = max((recipe.likes or 0) - 1, 0)
        liked = False
    else:
        db.add(RecipeLikeDB(recipe_id=recipe_id, user_email=user_email))
        recipe.likes = (recipe.likes or 0) + 1
        liked = True

    db.commit()
    return {"liked": liked, "likes": recipe.likes or 0}


# 15) Tarif Listele
@app.get("/recipes", response_model=List[RecipeOut])
def list_recipes(
    author_email: Optional[str] = None,
    viewer_email: Optional[str] = None,
    db: Session = Depends(get_db),
):
    query = db.query(RecipeDB).order_by(RecipeDB.created_at.desc())
    if author_email:
        normalized = author_email.strip().lower()
        query = query.filter(func.lower(RecipeDB.author_email) == normalized)
    recipes = query.all()
    liked_ids = None
    if viewer_email:
        normalized_viewer = viewer_email.strip().lower()
        liked_rows = (
            db.query(RecipeLikeDB.recipe_id)
            .filter(func.lower(RecipeLikeDB.user_email) == normalized_viewer)
            .all()
        )
        liked_ids = {row[0] for row in liked_rows}
    recipe_ids = [recipe.id for recipe in recipes]
    comment_counts = _get_recipe_comment_counts(db, recipe_ids)
    save_counts = _get_recipe_save_counts(db, recipe_ids)
    return [
        _recipe_to_out(
            recipe,
            liked_ids,
            comment_counts=comment_counts,
            save_counts=save_counts,
        )
        for recipe in recipes
    ]


# 16) Tarif Detay
@app.get("/recipes/{recipe_id}", response_model=RecipeOut)
def get_recipe(recipe_id: int, db: Session = Depends(get_db)):
    recipe = db.query(RecipeDB).filter(RecipeDB.id == recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")
    comment_counts = _get_recipe_comment_counts(db, [recipe.id])
    save_counts = _get_recipe_save_counts(db, [recipe.id])
    return _recipe_to_out(
        recipe,
        comment_counts=comment_counts,
        save_counts=save_counts,
    )


# 16b) Tarif Yorumlar
@app.get("/recipes/{recipe_id}/comments", response_model=List[RecipeCommentOut])
def list_recipe_comments(
    recipe_id: int,
    limit: int = 200,
    db: Session = Depends(get_db),
):
    limit = max(1, min(limit, 200))
    recipe = db.query(RecipeDB).filter(RecipeDB.id == recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")
    comments = (
        db.query(RecipeCommentDB)
        .filter(RecipeCommentDB.recipe_id == recipe_id)
        .order_by(RecipeCommentDB.created_at.asc())
        .limit(limit)
        .all()
    )
    return comments


@app.post("/recipes/{recipe_id}/comments", response_model=RecipeCommentOut)
def create_recipe_comment(
    recipe_id: int, payload: RecipeCommentCreate, db: Session = Depends(get_db)
):
    recipe = db.query(RecipeDB).filter(RecipeDB.id == recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    comment = payload.comment.strip()
    if not comment:
        raise HTTPException(status_code=400, detail="Comment is required")

    author_name = (payload.author_name or "").strip() or "Kullanici"
    author_email = (payload.author_email or "").strip() or None
    new_comment = RecipeCommentDB(
        recipe_id=recipe_id,
        author_name=author_name,
        author_email=author_email,
        comment=comment,
    )
    db.add(new_comment)
    recipe.comments = (recipe.comments or 0) + 1
    db.commit()
    db.refresh(new_comment)
    return new_comment


# 17) Defter Olustur
@app.post("/recipe-notebooks", response_model=RecipeNotebookOut)
def create_recipe_notebook(
    payload: RecipeNotebookCreate, db: Session = Depends(get_db)
):
    title = payload.title.strip()
    if not title:
        raise HTTPException(status_code=400, detail="Notebook title is required")

    notebook = RecipeNotebookDB(
        title=title,
        cover_image_url=payload.cover_image_url,
        owner_name=payload.owner_name,
        owner_email=payload.owner_email,
    )
    db.add(notebook)
    db.commit()
    db.refresh(notebook)
    return _notebook_to_out(notebook)


# 18) Defter Listele
@app.get("/recipe-notebooks", response_model=List[RecipeNotebookOut])
def list_recipe_notebooks(
    owner_email: Optional[str] = None,
    db: Session = Depends(get_db),
):
    query = db.query(RecipeNotebookDB).order_by(RecipeNotebookDB.created_at.desc())
    if owner_email:
        normalized = owner_email.strip().lower()
        query = query.filter(func.lower(RecipeNotebookDB.owner_email) == normalized)
    notebooks = query.all()
    return [_notebook_to_out(notebook) for notebook in notebooks]


# 19) Defter Guncelle
@app.put("/recipe-notebooks/{notebook_id}", response_model=RecipeNotebookOut)
def update_recipe_notebook(
    notebook_id: int, payload: RecipeNotebookUpdate, db: Session = Depends(get_db)
):
    notebook = (
        db.query(RecipeNotebookDB).filter(RecipeNotebookDB.id == notebook_id).first()
    )
    if not notebook:
        raise HTTPException(status_code=404, detail="Notebook not found")

    if payload.title is not None:
        title = payload.title.strip()
        if not title:
            raise HTTPException(status_code=400, detail="Notebook title is required")
        notebook.title = title
    if payload.cover_image_url is not None:
        notebook.cover_image_url = payload.cover_image_url

    db.commit()
    db.refresh(notebook)
    return _notebook_to_out(notebook)


# 20) Defter Sil
@app.delete("/recipe-notebooks/{notebook_id}")
def delete_recipe_notebook(notebook_id: int, db: Session = Depends(get_db)):
    notebook = (
        db.query(RecipeNotebookDB).filter(RecipeNotebookDB.id == notebook_id).first()
    )
    if not notebook:
        raise HTTPException(status_code=404, detail="Notebook not found")
    db.delete(notebook)
    db.commit()
    return {"message": "Notebook deleted"}


# 21) Deftere Tarif Ekle
@app.post(
    "/recipe-notebooks/{notebook_id}/items",
    response_model=RecipeNotebookOut,
)
def add_recipe_to_notebook(
    notebook_id: int,
    payload: RecipeNotebookItemCreate,
    db: Session = Depends(get_db),
):
    notebook = (
        db.query(RecipeNotebookDB).filter(RecipeNotebookDB.id == notebook_id).first()
    )
    if not notebook:
        raise HTTPException(status_code=404, detail="Notebook not found")

    recipe = db.query(RecipeDB).filter(RecipeDB.id == payload.recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    existing = (
        db.query(RecipeNotebookItemDB)
        .filter(
            RecipeNotebookItemDB.notebook_id == notebook_id,
            RecipeNotebookItemDB.recipe_id == payload.recipe_id,
        )
        .first()
    )
    if existing:
        return _notebook_to_out(notebook)

    db.add(
        RecipeNotebookItemDB(
            notebook_id=notebook_id,
            recipe_id=payload.recipe_id,
        )
    )
    db.commit()
    db.refresh(notebook)
    return _notebook_to_out(notebook)


# 22) Defterden Tarif Cikar
@app.delete(
    "/recipe-notebooks/{notebook_id}/items/{recipe_id}",
    response_model=RecipeNotebookOut,
)
def remove_recipe_from_notebook(
    notebook_id: int,
    recipe_id: int,
    db: Session = Depends(get_db),
):
    notebook = (
        db.query(RecipeNotebookDB).filter(RecipeNotebookDB.id == notebook_id).first()
    )
    if not notebook:
        raise HTTPException(status_code=404, detail="Notebook not found")

    item = (
        db.query(RecipeNotebookItemDB)
        .filter(
            RecipeNotebookItemDB.notebook_id == notebook_id,
            RecipeNotebookItemDB.recipe_id == recipe_id,
        )
        .first()
    )
    if item:
        db.delete(item)
        db.commit()
        db.refresh(notebook)

    return _notebook_to_out(notebook)
