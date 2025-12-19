# CloudStore - Full-Stack E-Commerce Application

A modern, cloud-based e-commerce application built with React, TypeScript, and Supabase. This project demonstrates cloud computing concepts with a production-ready architecture suitable for academic projects and demonstrations.

## Technology Stack

### Frontend
- **React 18** with TypeScript
- **Vite** for fast development and building
- **Tailwind CSS** for styling
- **Lucide React** for icons
- **Context API** for state management

### Backend
- **Supabase** (PostgreSQL database + Authentication + Edge Functions)
- **JWT-based authentication** via Supabase Auth
- **Row Level Security (RLS)** for data protection
- **RESTful API** architecture

### Cloud Architecture
- **Database**: PostgreSQL (hosted on Supabase Cloud)
- **Authentication**: Supabase Auth (JWT tokens, bcrypt password hashing)
- **Backend API**: Serverless Edge Functions (Deno runtime)
- **Storage**: Session storage in browser, cart data in localStorage
- **Deployment Ready**: Optimized for Vercel (frontend) deployment

## Features

### User Features
- User registration and authentication
- Browse products with search and category filters
- View detailed product information
- Shopping cart management (add, update, remove items)
- Place orders with automatic stock management
- View order history with status tracking
- Responsive design for all devices

### Admin Features
- Dashboard with business metrics (total products, orders, revenue, low stock alerts)
- Complete product management (CRUD operations)
- Order management with status updates
- Real-time inventory tracking
- Role-based access control

### Security Features
- JWT-based authentication
- Password hashing (automatic via Supabase Auth)
- Row Level Security policies on all database tables
- Protected admin routes
- CORS-enabled API endpoints
- Secure environment variable management

## Database Schema

### Tables
1. **profiles** - User profiles extending Supabase auth.users
2. **products** - Product catalog
3. **orders** - Customer orders
4. **order_items** - Order line items

### Relationships
- `profiles` -> `auth.users` (one-to-one)
- `orders` -> `profiles` (many-to-one)
- `order_items` -> `orders` (many-to-one)
- `order_items` -> `products` (many-to-one)

## Project Structure

```
project/
├── src/
│   ├── components/
│   │   └── Navbar.tsx           # Navigation component
│   ├── contexts/
│   │   ├── AuthContext.tsx      # Authentication state management
│   │   └── CartContext.tsx      # Shopping cart state management
│   ├── lib/
│   │   └── supabase.ts          # Supabase client and TypeScript types
│   ├── pages/
│   │   ├── HomePage.tsx         # Product listing page
│   │   ├── ProductDetails.tsx   # Single product view
│   │   ├── LoginPage.tsx        # User login
│   │   ├── RegisterPage.tsx     # User registration
│   │   ├── CartPage.tsx         # Shopping cart
│   │   ├── OrdersPage.tsx       # Order history
│   │   └── AdminPage.tsx        # Admin dashboard
│   ├── App.tsx                  # Main application component
│   ├── main.tsx                 # Application entry point
│   └── index.css                # Global styles
├── supabase/
│   └── functions/
│       └── create-order/        # Serverless order processing
├── .env.example                 # Environment variables template
├── package.json
└── README.md
```

## Setup Instructions

### Prerequisites
- Node.js 18+ installed
- A Supabase account (free tier available)

### 1. Clone the Repository
```bash
git clone <repository-url>
cd project
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Set Up Supabase

#### Option A: Using Existing Supabase Project
If you have Supabase credentials:

1. Create a `.env` file in the project root:
```env
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

2. The database schema has already been created. If you need to recreate it, run the migration SQL found in the Supabase dashboard.

#### Option B: Creating New Supabase Project
1. Go to [supabase.com](https://supabase.com) and create a free account
2. Create a new project
3. Go to Project Settings > API
4. Copy your Project URL and anon/public key
5. Create `.env` file with these credentials

### 4. Database Setup
The database is already configured with:
- All necessary tables (profiles, products, orders, order_items)
- Row Level Security policies
- Sample product data
- Indexes for optimized queries

### 5. Create Admin User
After registering your first user, you need to grant admin privileges:

1. Go to Supabase Dashboard > SQL Editor
2. Run this query (replace with your user's email):
```sql
UPDATE profiles
SET role = 'admin'
WHERE email = 'your-email@example.com';
```

### 6. Run the Application
```bash
npm run dev
```

The application will open at `http://localhost:5173`

## Usage Guide

### For Regular Users
1. **Register**: Create an account on the registration page
2. **Browse**: View products on the home page, use search and filters
3. **Add to Cart**: Click "Add to Cart" on any product
4. **Checkout**: Go to cart, review items, and place order
5. **View Orders**: Check order history and status

### For Admin Users
1. **Login**: Sign in with admin account
2. **Access Dashboard**: Click "Admin" in navigation
3. **Manage Products**: Add, edit, or delete products
4. **Manage Orders**: Update order status
5. **View Metrics**: Monitor sales and inventory

## API Documentation

### Edge Functions

#### POST `/functions/v1/create-order`
Creates a new order from cart items.

**Headers:**
- `Authorization: Bearer <jwt-token>`
- `Content-Type: application/json`

**Request Body:**
```json
{
  "items": [
    {
      "product_id": "uuid",
      "quantity": 1
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "order": {
    "id": "uuid",
    "total_amount": 99.99,
    "status": "pending"
  }
}
```

### Direct Database Access
Most operations use direct Supabase client calls with automatic RLS enforcement:
- Product queries (public read access)
- Order queries (user can view own orders, admin can view all)
- Profile management (users can update own profile)

## Deployment

### Frontend (Vercel)
1. Push code to GitHub
2. Connect repository to Vercel
3. Add environment variables in Vercel dashboard:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
4. Deploy automatically

### Backend
The backend (Supabase) is already cloud-hosted. Edge Functions are automatically deployed and available globally.

## Security Considerations

- Passwords are automatically hashed using bcrypt via Supabase Auth
- JWT tokens are stored securely in Supabase session
- All API requests require authentication (except product viewing)
- Row Level Security prevents unauthorized data access
- Admin privileges required for sensitive operations
- CORS configured for secure cross-origin requests

## Testing the Application

### Test User Flow
1. Register a new account
2. Browse products
3. Add items to cart
4. Place an order
5. View order history

### Test Admin Flow
1. Promote a user to admin (via SQL)
2. Login as admin
3. Create a new product
4. Update product details
5. Change order status
6. View dashboard metrics

## Troubleshooting

### "Missing authorization header"
- Ensure user is logged in
- Check if JWT token is valid

### "Insufficient stock"
- Verify product stock in admin dashboard
- Check if another order depleted stock

### Products not loading
- Verify `.env` file has correct Supabase credentials
- Check browser console for errors
- Ensure Row Level Security policies are applied

### Admin panel not accessible
- Confirm user role is 'admin' in profiles table
- Check browser console for authorization errors

## Academic Project Notes

This project demonstrates:

1. **Cloud Computing Concepts**
   - Database-as-a-Service (Supabase/PostgreSQL)
   - Serverless Functions (Edge Functions)
   - Cloud Authentication (Supabase Auth)
   - Cloud Deployment (Vercel)

2. **Software Architecture**
   - Client-Server architecture
   - RESTful API design
   - Microservices pattern (Edge Functions)
   - Separation of concerns

3. **Security Best Practices**
   - Authentication and authorization
   - Password hashing
   - SQL injection prevention (parameterized queries)
   - Role-based access control

4. **Database Design**
   - Normalized schema
   - Foreign key relationships
   - Indexes for performance
   - Row Level Security

## Future Enhancements

- Payment gateway integration (Stripe)
- Email notifications
- Product reviews and ratings
- Wishlist functionality
- Advanced search with filters
- Order tracking with shipping updates
- Multi-language support
- Analytics dashboard

## License

This project is created for academic purposes.

## Support

For issues or questions, please refer to:
- Supabase Documentation: https://supabase.com/docs
- React Documentation: https://react.dev
- Vite Documentation: https://vitejs.dev
