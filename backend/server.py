from fastapi import FastAPI, APIRouter, HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from pydantic import BaseModel, Field, EmailStr
from typing import List, Optional
import uuid
from datetime import datetime, date, timedelta
from enum import Enum
import jwt
from passlib.context import CryptContext
from passlib.hash import bcrypt

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

# Authentication setup
SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'fleet-management-secret-key-2024')
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

# Create the main app without a prefix
app = FastAPI()

# Create a router with the /api prefix
api_router = APIRouter(prefix="/api")

# Enums
class UserRole(str, Enum):
    FLEET_MANAGER = "fleet_manager"
    REGULAR_USER = "regular_user"

class CarCategory(str, Enum):
    SEDAN = "sedan"
    SUV = "suv"
    TRUCK = "truck"
    VAN = "van"
    HATCHBACK = "hatchback"
    COUPE = "coupe"

class CarStatus(str, Enum):
    AVAILABLE = "available"
    IN_USE = "in_use"
    DOWNTIME = "downtime"
    MAINTENANCE = "maintenance"

class DowntimeReason(str, Enum):
    MAINTENANCE = "maintenance"
    REPAIR = "repair"
    ACCIDENT = "accident"
    CLEANING = "cleaning"
    INSPECTION = "inspection"
    OTHER = "other"

class BookingStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

# Authentication Models
class User(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    email: EmailStr
    role: UserRole
    department: Optional[str] = None
    phone: Optional[str] = None
    is_active: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: UserRole
    department: Optional[str] = None
    phone: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: str
    name: str
    email: EmailStr
    role: UserRole
    department: Optional[str] = None
    phone: Optional[str] = None
    is_active: bool
    created_at: datetime

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

# Models
class Car(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    make: str
    model: str
    year: int
    license_plate: str
    vin: str
    mileage: int
    category: CarCategory
    status: CarStatus = CarStatus.AVAILABLE
    created_at: datetime = Field(default_factory=datetime.utcnow)

class CarCreate(BaseModel):
    make: str
    model: str
    year: int
    license_plate: str
    vin: str
    mileage: int
    category: CarCategory

class CarUpdate(BaseModel):
    make: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    license_plate: Optional[str] = None
    vin: Optional[str] = None
    mileage: Optional[int] = None
    category: Optional[CarCategory] = None
    status: Optional[CarStatus] = None

class Downtime(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    car_id: str
    reason: DowntimeReason
    description: str
    start_date: datetime
    end_date: Optional[datetime] = None
    cost: Optional[float] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

class DowntimeCreate(BaseModel):
    car_id: str
    reason: DowntimeReason
    description: str
    start_date: datetime
    end_date: Optional[datetime] = None
    cost: Optional[float] = None

class DowntimeUpdate(BaseModel):
    reason: Optional[DowntimeReason] = None
    description: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    cost: Optional[float] = None

class FleetStats(BaseModel):
    total_cars: int
    available_cars: int
    in_downtime: int
    in_use: int
    maintenance: int

# Booking Models
class Booking(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    car_id: str
    user_id: str
    start_date: datetime
    end_date: datetime
    purpose: str
    status: BookingStatus = BookingStatus.PENDING
    approved_by: Optional[str] = None
    approved_at: Optional[datetime] = None
    rejection_reason: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

class BookingCreate(BaseModel):
    car_id: str
    start_date: datetime
    end_date: datetime
    purpose: str

class BookingUpdate(BaseModel):
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    purpose: Optional[str] = None

class BookingApproval(BaseModel):
    status: BookingStatus
    rejection_reason: Optional[str] = None

class BookingResponse(BaseModel):
    id: str
    car_id: str
    user_id: str
    start_date: datetime
    end_date: datetime
    purpose: str
    status: BookingStatus
    approved_by: Optional[str] = None
    approved_at: Optional[datetime] = None
    rejection_reason: Optional[str] = None
    created_at: datetime
    car_info: Optional[dict] = None
    user_info: Optional[dict] = None
    approver_info: Optional[dict] = None

# Authentication Helper Functions
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except jwt.PyJWTError:
        raise credentials_exception
    
    user = await db.users.find_one({"id": user_id})
    if user is None:
        raise credentials_exception
    return User(**user)

async def get_current_manager(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != UserRole.FLEET_MANAGER:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only fleet managers can access this resource"
        )
    return current_user

# Authentication routes
@api_router.post("/auth/register", response_model=Token)
async def register_user(user_data: UserCreate):
    # Check if user already exists
    existing_user = await db.users.find_one({"email": user_data.email})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user
    hashed_password = get_password_hash(user_data.password)
    user = User(
        name=user_data.name,
        email=user_data.email,
        role=user_data.role,
        department=user_data.department,
        phone=user_data.phone
    )
    
    # Store user with hashed password
    user_dict = user.dict()
    user_dict["password_hash"] = hashed_password
    await db.users.insert_one(user_dict)
    
    # Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.id}, expires_delta=access_token_expires
    )
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse(**user.dict())
    )

@api_router.post("/auth/login", response_model=Token)
async def login_user(user_credentials: UserLogin):
    # Find user by email
    user = await db.users.find_one({"email": user_credentials.email})
    if not user or not verify_password(user_credentials.password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user["id"]}, expires_delta=access_token_expires
    )
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse(**{k: v for k, v in user.items() if k != "password_hash"})
    )

@api_router.get("/auth/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    return UserResponse(**current_user.dict())

# User Management routes (only for managers)
@api_router.get("/users", response_model=List[UserResponse])
async def get_all_users(current_manager: User = Depends(get_current_manager)):
    users = await db.users.find().to_list(1000)
    return [UserResponse(**{k: v for k, v in user.items() if k != "password_hash"}) for user in users]

@api_router.post("/users", response_model=UserResponse)
async def create_user_by_manager(user_data: UserCreate, current_manager: User = Depends(get_current_manager)):
    # Check if user already exists
    existing_user = await db.users.find_one({"email": user_data.email})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user
    hashed_password = get_password_hash(user_data.password)
    user = User(
        name=user_data.name,
        email=user_data.email,
        role=user_data.role,
        department=user_data.department,
        phone=user_data.phone
    )
    
    # Store user with hashed password
    user_dict = user.dict()
    user_dict["password_hash"] = hashed_password
    await db.users.insert_one(user_dict)
    
    return UserResponse(**user.dict())

@api_router.delete("/users/{user_id}")
async def delete_user(user_id: str, current_manager: User = Depends(get_current_manager)):
    result = await db.users.delete_one({"id": user_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="User not found")
    return {"message": "User deleted successfully"}

# Car routes
@api_router.get("/cars", response_model=List[Car])
async def get_cars(current_user: User = Depends(get_current_user)):
    cars = await db.cars.find().to_list(1000)
    return [Car(**car) for car in cars]

@api_router.post("/cars", response_model=Car)
async def create_car(car_data: CarCreate, current_manager: User = Depends(get_current_manager)):
    car = Car(**car_data.dict())
    await db.cars.insert_one(car.dict())
    return car

@api_router.get("/cars/{car_id}", response_model=Car)
async def get_car(car_id: str, current_user: User = Depends(get_current_user)):
    car = await db.cars.find_one({"id": car_id})
    if not car:
        raise HTTPException(status_code=404, detail="Car not found")
    return Car(**car)

@api_router.put("/cars/{car_id}", response_model=Car)
async def update_car(car_id: str, car_update: CarUpdate, current_manager: User = Depends(get_current_manager)):
    update_data = {k: v for k, v in car_update.dict().items() if v is not None}
    if not update_data:
        raise HTTPException(status_code=400, detail="No update data provided")
    
    result = await db.cars.update_one({"id": car_id}, {"$set": update_data})
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Car not found")
    
    updated_car = await db.cars.find_one({"id": car_id})
    return Car(**updated_car)

@api_router.delete("/cars/{car_id}")
async def delete_car(car_id: str, current_manager: User = Depends(get_current_manager)):
    result = await db.cars.delete_one({"id": car_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Car not found")
    
    # Also delete associated downtimes
    await db.downtimes.delete_many({"car_id": car_id})
    return {"message": "Car deleted successfully"}

# Downtime routes
@api_router.get("/downtimes", response_model=List[Downtime])
async def get_downtimes(current_user: User = Depends(get_current_user)):
    downtimes = await db.downtimes.find().sort("start_date", -1).to_list(1000)
    return [Downtime(**downtime) for downtime in downtimes]

@api_router.get("/downtimes/car/{car_id}", response_model=List[Downtime])
async def get_car_downtimes(car_id: str, current_user: User = Depends(get_current_user)):
    downtimes = await db.downtimes.find({"car_id": car_id}).sort("start_date", -1).to_list(1000)
    return [Downtime(**downtime) for downtime in downtimes]

@api_router.post("/downtimes", response_model=Downtime)
async def create_downtime(downtime_data: DowntimeCreate, current_manager: User = Depends(get_current_manager)):
    # Check if car exists
    car = await db.cars.find_one({"id": downtime_data.car_id})
    if not car:
        raise HTTPException(status_code=404, detail="Car not found")
    
    downtime = Downtime(**downtime_data.dict())
    await db.downtimes.insert_one(downtime.dict())
    
    # Update car status to downtime if currently happening
    if downtime.start_date <= datetime.utcnow() and (not downtime.end_date or downtime.end_date >= datetime.utcnow()):
        await db.cars.update_one({"id": downtime_data.car_id}, {"$set": {"status": CarStatus.DOWNTIME}})
    
    return downtime

@api_router.put("/downtimes/{downtime_id}", response_model=Downtime)
async def update_downtime(downtime_id: str, downtime_update: DowntimeUpdate, current_manager: User = Depends(get_current_manager)):
    update_data = {k: v for k, v in downtime_update.dict().items() if v is not None}
    if not update_data:
        raise HTTPException(status_code=400, detail="No update data provided")
    
    result = await db.downtimes.update_one({"id": downtime_id}, {"$set": update_data})
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Downtime not found")
    
    updated_downtime = await db.downtimes.find_one({"id": downtime_id})
    return Downtime(**updated_downtime)

@api_router.delete("/downtimes/{downtime_id}")
async def delete_downtime(downtime_id: str, current_manager: User = Depends(get_current_manager)):
    result = await db.downtimes.delete_one({"id": downtime_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Downtime not found")
    return {"message": "Downtime deleted successfully"}

# Dashboard routes
@api_router.get("/fleet/stats", response_model=FleetStats)
async def get_fleet_stats(current_user: User = Depends(get_current_user)):
    total_cars = await db.cars.count_documents({})
    available_cars = await db.cars.count_documents({"status": CarStatus.AVAILABLE})
    in_downtime = await db.cars.count_documents({"status": CarStatus.DOWNTIME})
    in_use = await db.cars.count_documents({"status": CarStatus.IN_USE})
    maintenance = await db.cars.count_documents({"status": CarStatus.MAINTENANCE})
    
    return FleetStats(
        total_cars=total_cars,
        available_cars=available_cars,
        in_downtime=in_downtime,
        in_use=in_use,
        maintenance=maintenance
    )

@api_router.get("/fleet/categories")
async def get_fleet_by_category(current_user: User = Depends(get_current_user)):
    pipeline = [
        {"$group": {"_id": "$category", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}}
    ]
    result = await db.cars.aggregate(pipeline).to_list(100)
    return [{"category": item["_id"], "count": item["count"]} for item in result]

# Include the router in the main app
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
