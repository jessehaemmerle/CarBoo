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

class SubscriptionPlan(str, Enum):
    TRIAL = "trial"
    BASIC = "basic"
    PROFESSIONAL = "professional"
    ENTERPRISE = "enterprise"

# Company Models
class Company(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    slug: str
    email: str
    phone: Optional[str] = None
    address: Optional[str] = None
    website: Optional[str] = None
    subscription_plan: SubscriptionPlan = SubscriptionPlan.TRIAL
    max_vehicles: int = 5  # Based on subscription plan
    max_users: int = 3    # Based on subscription plan
    is_active: bool = True
    trial_end_date: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    settings: Optional[dict] = {}

class CompanyCreate(BaseModel):
    name: str
    email: str
    phone: Optional[str] = None
    address: Optional[str] = None
    website: Optional[str] = None

class CompanyUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    website: Optional[str] = None
    settings: Optional[dict] = None

class CompanyResponse(BaseModel):
    id: str
    name: str
    slug: str
    email: str
    phone: Optional[str] = None
    address: Optional[str] = None
    website: Optional[str] = None
    subscription_plan: SubscriptionPlan
    max_vehicles: int
    max_users: int
    is_active: bool
    trial_end_date: Optional[datetime] = None
    created_at: datetime
    stats: Optional[dict] = None

# Authentication Models
class User(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    company_id: str
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

class CompanyRegistration(BaseModel):
    # Company info
    company_name: str
    company_email: str
    company_phone: Optional[str] = None
    company_address: Optional[str] = None
    company_website: Optional[str] = None
    # Fleet Manager info
    manager_name: str
    manager_email: EmailStr
    manager_password: str
    manager_phone: Optional[str] = None
    manager_department: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: str
    company_id: str
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
    company: CompanyResponse

# Models
class Car(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    company_id: str
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
    company_id: str
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
    company_id: str
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
    company_id: str
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

def create_company_slug(name: str) -> str:
    """Create a unique slug from company name"""
    import re
    slug = re.sub(r'[^a-zA-Z0-9\s-]', '', name.lower())
    slug = re.sub(r'\s+', '-', slug)
    return slug.strip('-')

async def get_subscription_limits(plan: SubscriptionPlan) -> dict:
    """Get subscription plan limits"""
    limits = {
        SubscriptionPlan.TRIAL: {"max_vehicles": 5, "max_users": 3, "trial_days": 14},
        SubscriptionPlan.BASIC: {"max_vehicles": 25, "max_users": 10, "trial_days": 0},
        SubscriptionPlan.PROFESSIONAL: {"max_vehicles": 100, "max_users": 50, "trial_days": 0},
        SubscriptionPlan.ENTERPRISE: {"max_vehicles": -1, "max_users": -1, "trial_days": 0}  # Unlimited
    }
    return limits.get(plan, limits[SubscriptionPlan.TRIAL])

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

async def get_user_company(user: User) -> Company:
    """Get the company for the current user"""
    company = await db.companies.find_one({"id": user.company_id})
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    return Company(**company)

# Company routes
@api_router.post("/companies/register", response_model=Token)
async def register_company(registration_data: CompanyRegistration):
    """Register a new company with fleet manager"""
    
    # Check if company email already exists
    existing_company = await db.companies.find_one({"email": registration_data.company_email})
    if existing_company:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Company email already registered"
        )
    
    # Check if manager email already exists
    existing_user = await db.users.find_one({"email": registration_data.manager_email})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Manager email already registered"
        )
    
    # Create company slug
    base_slug = create_company_slug(registration_data.company_name)
    company_slug = base_slug
    counter = 1
    while await db.companies.find_one({"slug": company_slug}):
        company_slug = f"{base_slug}-{counter}"
        counter += 1
    
    # Get trial limits
    trial_limits = await get_subscription_limits(SubscriptionPlan.TRIAL)
    trial_end_date = datetime.utcnow() + timedelta(days=trial_limits["trial_days"])
    
    # Create company
    company = Company(
        name=registration_data.company_name,
        slug=company_slug,
        email=registration_data.company_email,
        phone=registration_data.company_phone,
        address=registration_data.company_address,
        website=registration_data.company_website,
        subscription_plan=SubscriptionPlan.TRIAL,
        max_vehicles=trial_limits["max_vehicles"],
        max_users=trial_limits["max_users"],
        trial_end_date=trial_end_date
    )
    
    await db.companies.insert_one(company.dict())
    
    # Create fleet manager
    hashed_password = get_password_hash(registration_data.manager_password)
    manager = User(
        company_id=company.id,
        name=registration_data.manager_name,
        email=registration_data.manager_email,
        role=UserRole.FLEET_MANAGER,
        department=registration_data.manager_department,
        phone=registration_data.manager_phone
    )
    
    # Store user with hashed password
    manager_dict = manager.dict()
    manager_dict["password_hash"] = hashed_password
    await db.users.insert_one(manager_dict)
    
    # Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": manager.id}, expires_delta=access_token_expires
    )
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse(**manager.dict()),
        company=CompanyResponse(**company.dict())
    )

@api_router.get("/companies/me", response_model=CompanyResponse)
async def get_my_company(current_user: User = Depends(get_current_user)):
    """Get current user's company information"""
    company = await get_user_company(current_user)
    
    # Add stats for managers
    if current_user.role == UserRole.FLEET_MANAGER:
        total_cars = await db.cars.count_documents({"company_id": current_user.company_id})
        total_users = await db.users.count_documents({"company_id": current_user.company_id})
        total_bookings = await db.bookings.count_documents({"company_id": current_user.company_id})
        
        stats = {
            "total_cars": total_cars,
            "total_users": total_users,
            "total_bookings": total_bookings,
            "usage_percentage": {
                "vehicles": (total_cars / company.max_vehicles * 100) if company.max_vehicles > 0 else 0,
                "users": (total_users / company.max_users * 100) if company.max_users > 0 else 0
            }
        }
        
        company_response = CompanyResponse(**company.dict())
        company_response.stats = stats
        return company_response
    
    return CompanyResponse(**company.dict())

@api_router.put("/companies/me", response_model=CompanyResponse)
async def update_my_company(company_update: CompanyUpdate, current_manager: User = Depends(get_current_manager)):
    """Update company information (managers only)"""
    update_data = {k: v for k, v in company_update.dict().items() if v is not None}
    if not update_data:
        raise HTTPException(status_code=400, detail="No update data provided")
    
    result = await db.companies.update_one(
        {"id": current_manager.company_id}, 
        {"$set": update_data}
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Company not found")
    
    updated_company = await get_user_company(current_manager)
    return CompanyResponse(**updated_company.dict())

# Authentication routes
@api_router.post("/auth/register", response_model=Token)
async def register_user(user_data: UserCreate):
    # This endpoint is deprecated in favor of company registration
    # Keeping for backward compatibility but should be disabled in production
    raise HTTPException(
        status_code=status.HTTP_410_GONE,
        detail="Direct user registration is no longer supported. Please use company registration instead."
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
    
    # Get user's company
    company = await db.companies.find_one({"id": user["company_id"]})
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    
    # Check if company is active
    if not company["is_active"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Company account is inactive"
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user["id"]}, expires_delta=access_token_expires
    )
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse(**{k: v for k, v in user.items() if k != "password_hash"}),
        company=CompanyResponse(**company)
    )

@api_router.get("/auth/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    return UserResponse(**current_user.dict())

# User Management routes (only for managers)
@api_router.get("/users", response_model=List[UserResponse])
async def get_all_users(current_manager: User = Depends(get_current_manager)):
    users = await db.users.find({"company_id": current_manager.company_id}).to_list(1000)
    return [UserResponse(**{k: v for k, v in user.items() if k != "password_hash"}) for user in users]

@api_router.post("/users", response_model=UserResponse)
async def create_user_by_manager(user_data: UserCreate, current_manager: User = Depends(get_current_manager)):
    # Check company user limit
    company = await get_user_company(current_manager)
    current_user_count = await db.users.count_documents({"company_id": current_manager.company_id})
    
    if company.max_users > 0 and current_user_count >= company.max_users:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"User limit reached. Your plan allows {company.max_users} users."
        )
    
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
        company_id=current_manager.company_id,
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
    # Check if user belongs to the same company
    user_to_delete = await db.users.find_one({"id": user_id, "company_id": current_manager.company_id})
    if not user_to_delete:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Prevent deleting the last fleet manager
    if user_to_delete["role"] == UserRole.FLEET_MANAGER:
        manager_count = await db.users.count_documents({
            "company_id": current_manager.company_id,
            "role": UserRole.FLEET_MANAGER
        })
        if manager_count <= 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot delete the last fleet manager"
            )
    
    result = await db.users.delete_one({"id": user_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="User not found")
    return {"message": "User deleted successfully"}

# Booking Helper Functions
async def check_car_availability(car_id: str, start_date: datetime, end_date: datetime, exclude_booking_id: Optional[str] = None):
    """Check if a car is available for booking during the specified period"""
    
    # Check if car exists and is not in permanent downtime
    car = await db.cars.find_one({"id": car_id})
    if not car:
        return False, "Car not found"
    
    # Check for overlapping downtimes
    downtime_query = {
        "car_id": car_id,
        "$or": [
            {
                "start_date": {"$lte": end_date},
                "end_date": {"$gte": start_date}
            },
            {
                "start_date": {"$lte": end_date},
                "end_date": None  # Ongoing downtime
            }
        ]
    }
    
    existing_downtime = await db.downtimes.find_one(downtime_query)
    if existing_downtime:
        return False, "Car has scheduled downtime during this period"
    
    # Check for overlapping approved bookings
    booking_query = {
        "car_id": car_id,
        "status": {"$in": [BookingStatus.APPROVED, BookingStatus.PENDING]},
        "$or": [
            {
                "start_date": {"$lte": end_date},
                "end_date": {"$gte": start_date}
            }
        ]
    }
    
    if exclude_booking_id:
        booking_query["id"] = {"$ne": exclude_booking_id}
    
    existing_booking = await db.bookings.find_one(booking_query)
    if existing_booking:
        return False, "Car is already booked during this period"
    
    return True, "Car is available"

async def get_booking_with_details(booking_id: str):
    """Get booking with car, user, and approver details"""
    booking = await db.bookings.find_one({"id": booking_id})
    if not booking:
        return None
    
    # Get car details
    car = await db.cars.find_one({"id": booking["car_id"]})
    
    # Get user details
    user = await db.users.find_one({"id": booking["user_id"]})
    
    # Get approver details if exists
    approver = None
    if booking.get("approved_by"):
        approver = await db.users.find_one({"id": booking["approved_by"]})
    
    # Build response
    booking_response = BookingResponse(**booking)
    if car:
        booking_response.car_info = {
            "make": car["make"],
            "model": car["model"],
            "year": car["year"],
            "license_plate": car["license_plate"],
            "category": car["category"]
        }
    if user:
        booking_response.user_info = {
            "name": user["name"],
            "email": user["email"],
            "department": user.get("department")
        }
    if approver:
        booking_response.approver_info = {
            "name": approver["name"],
            "email": approver["email"]
        }
    
    return booking_response

# Booking routes
@api_router.get("/bookings", response_model=List[BookingResponse])
async def get_bookings(current_user: User = Depends(get_current_user)):
    """Get bookings - all for managers, own bookings for regular users"""
    if current_user.role == UserRole.FLEET_MANAGER:
        # Managers can see all bookings
        bookings = await db.bookings.find().sort("created_at", -1).to_list(1000)
    else:
        # Regular users can only see their own bookings
        bookings = await db.bookings.find({"user_id": current_user.id}).sort("created_at", -1).to_list(1000)
    
    # Get detailed booking information
    detailed_bookings = []
    for booking in bookings:
        detailed_booking = await get_booking_with_details(booking["id"])
        if detailed_booking:
            detailed_bookings.append(detailed_booking)
    
    return detailed_bookings

@api_router.get("/bookings/{booking_id}", response_model=BookingResponse)
async def get_booking(booking_id: str, current_user: User = Depends(get_current_user)):
    """Get specific booking details"""
    booking = await db.bookings.find_one({"id": booking_id})
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    # Check if user can access this booking
    if current_user.role != UserRole.FLEET_MANAGER and booking["user_id"] != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    detailed_booking = await get_booking_with_details(booking_id)
    return detailed_booking

@api_router.post("/bookings", response_model=BookingResponse)
async def create_booking(booking_data: BookingCreate, current_user: User = Depends(get_current_user)):
    """Create a new booking request"""
    
    # Validate dates
    if booking_data.start_date >= booking_data.end_date:
        raise HTTPException(status_code=400, detail="End date must be after start date")
    
    if booking_data.start_date < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Start date cannot be in the past")
    
    # Check car availability
    available, message = await check_car_availability(
        booking_data.car_id, 
        booking_data.start_date, 
        booking_data.end_date
    )
    
    if not available:
        raise HTTPException(status_code=400, detail=message)
    
    # Create booking
    booking = Booking(
        car_id=booking_data.car_id,
        user_id=current_user.id,
        start_date=booking_data.start_date,
        end_date=booking_data.end_date,
        purpose=booking_data.purpose
    )
    
    await db.bookings.insert_one(booking.dict())
    
    # Return detailed booking
    detailed_booking = await get_booking_with_details(booking.id)
    return detailed_booking

@api_router.put("/bookings/{booking_id}", response_model=BookingResponse)
async def update_booking(booking_id: str, booking_update: BookingUpdate, current_user: User = Depends(get_current_user)):
    """Update booking (only by owner and only if pending)"""
    
    booking = await db.bookings.find_one({"id": booking_id})
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    # Check permissions
    if booking["user_id"] != current_user.id:
        raise HTTPException(status_code=403, detail="You can only update your own bookings")
    
    if booking["status"] != BookingStatus.PENDING:
        raise HTTPException(status_code=400, detail="Only pending bookings can be updated")
    
    # Build update data
    update_data = {k: v for k, v in booking_update.dict().items() if v is not None}
    
    if not update_data:
        raise HTTPException(status_code=400, detail="No update data provided")
    
    # If dates are being updated, check availability
    if "start_date" in update_data or "end_date" in update_data:
        new_start = update_data.get("start_date", booking["start_date"])
        new_end = update_data.get("end_date", booking["end_date"])
        
        if new_start >= new_end:
            raise HTTPException(status_code=400, detail="End date must be after start date")
        
        available, message = await check_car_availability(
            booking["car_id"], 
            new_start, 
            new_end,
            exclude_booking_id=booking_id
        )
        
        if not available:
            raise HTTPException(status_code=400, detail=message)
    
    # Update booking
    result = await db.bookings.update_one({"id": booking_id}, {"$set": update_data})
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    # Return updated booking
    detailed_booking = await get_booking_with_details(booking_id)
    return detailed_booking

@api_router.put("/bookings/{booking_id}/approve", response_model=BookingResponse)
async def approve_reject_booking(booking_id: str, approval_data: BookingApproval, current_manager: User = Depends(get_current_manager)):
    """Approve or reject a booking (managers only)"""
    
    booking = await db.bookings.find_one({"id": booking_id})
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    if booking["status"] != BookingStatus.PENDING:
        raise HTTPException(status_code=400, detail="Only pending bookings can be approved or rejected")
    
    # If approving, check availability again
    if approval_data.status == BookingStatus.APPROVED:
        available, message = await check_car_availability(
            booking["car_id"], 
            booking["start_date"], 
            booking["end_date"],
            exclude_booking_id=booking_id
        )
        
        if not available:
            raise HTTPException(status_code=400, detail=f"Cannot approve: {message}")
    
    # Update booking
    update_data = {
        "status": approval_data.status,
        "approved_by": current_manager.id,
        "approved_at": datetime.utcnow()
    }
    
    if approval_data.status == BookingStatus.REJECTED and approval_data.rejection_reason:
        update_data["rejection_reason"] = approval_data.rejection_reason
    
    result = await db.bookings.update_one({"id": booking_id}, {"$set": update_data})
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    # Return updated booking
    detailed_booking = await get_booking_with_details(booking_id)
    return detailed_booking

@api_router.delete("/bookings/{booking_id}")
async def cancel_booking(booking_id: str, current_user: User = Depends(get_current_user)):
    """Cancel a booking"""
    
    booking = await db.bookings.find_one({"id": booking_id})
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    # Check permissions
    if current_user.role != UserRole.FLEET_MANAGER and booking["user_id"] != current_user.id:
        raise HTTPException(status_code=403, detail="You can only cancel your own bookings")
    
    if booking["status"] in [BookingStatus.COMPLETED, BookingStatus.CANCELLED]:
        raise HTTPException(status_code=400, detail="Cannot cancel completed or already cancelled bookings")
    
    # Update booking status to cancelled
    result = await db.bookings.update_one(
        {"id": booking_id}, 
        {"$set": {"status": BookingStatus.CANCELLED}}
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    return {"message": "Booking cancelled successfully"}

@api_router.get("/cars/{car_id}/availability")
async def check_car_availability_endpoint(car_id: str, start_date: datetime, end_date: datetime, current_user: User = Depends(get_current_user)):
    """Check if a car is available for booking"""
    
    available, message = await check_car_availability(car_id, start_date, end_date)
    
    return {
        "available": available,
        "message": message,
        "car_id": car_id,
        "start_date": start_date,
        "end_date": end_date
    }

# Car routes
@api_router.get("/cars", response_model=List[Car])
async def get_cars(current_user: User = Depends(get_current_user)):
    cars = await db.cars.find({"company_id": current_user.company_id}).to_list(1000)
    return [Car(**car) for car in cars]

@api_router.post("/cars", response_model=Car)
async def create_car(car_data: CarCreate, current_manager: User = Depends(get_current_manager)):
    # Check company vehicle limit
    company = await get_user_company(current_manager)
    current_car_count = await db.cars.count_documents({"company_id": current_manager.company_id})
    
    if company.max_vehicles > 0 and current_car_count >= company.max_vehicles:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Vehicle limit reached. Your plan allows {company.max_vehicles} vehicles."
        )
    
    # Check for duplicate license plate within company
    existing_car = await db.cars.find_one({
        "company_id": current_manager.company_id,
        "license_plate": car_data.license_plate
    })
    if existing_car:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="License plate already exists in your fleet"
        )
    
    car = Car(company_id=current_manager.company_id, **car_data.dict())
    await db.cars.insert_one(car.dict())
    return car

@api_router.get("/cars/{car_id}", response_model=Car)
async def get_car(car_id: str, current_user: User = Depends(get_current_user)):
    car = await db.cars.find_one({"id": car_id, "company_id": current_user.company_id})
    if not car:
        raise HTTPException(status_code=404, detail="Car not found")
    return Car(**car)

@api_router.put("/cars/{car_id}", response_model=Car)
async def update_car(car_id: str, car_update: CarUpdate, current_manager: User = Depends(get_current_manager)):
    update_data = {k: v for k, v in car_update.dict().items() if v is not None}
    if not update_data:
        raise HTTPException(status_code=400, detail="No update data provided")
    
    # Check for duplicate license plate if updating license plate
    if "license_plate" in update_data:
        existing_car = await db.cars.find_one({
            "company_id": current_manager.company_id,
            "license_plate": update_data["license_plate"],
            "id": {"$ne": car_id}
        })
        if existing_car:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="License plate already exists in your fleet"
            )
    
    result = await db.cars.update_one(
        {"id": car_id, "company_id": current_manager.company_id}, 
        {"$set": update_data}
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Car not found")
    
    updated_car = await db.cars.find_one({"id": car_id, "company_id": current_manager.company_id})
    return Car(**updated_car)

@api_router.delete("/cars/{car_id}")
async def delete_car(car_id: str, current_manager: User = Depends(get_current_manager)):
    result = await db.cars.delete_one({"id": car_id, "company_id": current_manager.company_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Car not found")
    
    # Also delete associated downtimes and bookings
    await db.downtimes.delete_many({"car_id": car_id, "company_id": current_manager.company_id})
    await db.bookings.delete_many({"car_id": car_id, "company_id": current_manager.company_id})
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
