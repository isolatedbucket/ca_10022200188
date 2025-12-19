# CloudStore - Architecture Documentation

## System Architecture Overview

This document provides a detailed technical overview of the CloudStore e-commerce application architecture, designed for cloud computing academic projects.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Client Layer                          │
│  (React SPA - Runs in Browser)                              │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐   │
│  │   Auth   │  │   Cart   │  │ Product  │  │  Order  │   │
│  │ Context  │  │ Context  │  │   Pages  │  │  Pages  │   │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTPS/REST API
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Supabase Cloud Platform                   │
│                                                              │
│  ┌────────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │  Auth Service  │  │ Edge Funcs   │  │  PostgreSQL    │ │
│  │  (JWT Tokens)  │  │ (Serverless) │  │   Database     │ │
│  └────────────────┘  └──────────────┘  └────────────────┘ │
│          │                  │                   │           │
│          └──────────────────┴───────────────────┘           │
│                   Row Level Security (RLS)                  │
└─────────────────────────────────────────────────────────────┘
```

## Layer Breakdown

### 1. Client Layer (Frontend)

**Technology**: React 18 + TypeScript + Vite
**Deployment**: Vercel / Netlify

#### Components Structure

```
src/
├── components/           # Reusable UI components
│   └── Navbar.tsx       # Main navigation
├── contexts/            # Global state management
│   ├── AuthContext.tsx  # User authentication state
│   └── CartContext.tsx  # Shopping cart state
├── pages/              # Route-level components
│   ├── HomePage.tsx    # Product catalog
│   ├── ProductDetails.tsx
│   ├── LoginPage.tsx
│   ├── RegisterPage.tsx
│   ├── CartPage.tsx
│   ├── OrdersPage.tsx
│   └── AdminPage.tsx
├── lib/                # Utilities and configurations
│   └── supabase.ts     # Supabase client setup
└── App.tsx            # Root component with routing
```

#### State Management

**Context API Pattern**:
- `AuthContext`: Manages user session, login/logout, role checks
- `CartContext`: Manages shopping cart items, persisted in localStorage

**Why Context API?**
- No external dependencies required
- Suitable for app size and complexity
- Simple to understand for academic projects
- Native React solution

#### Routing Strategy

Custom client-side routing using React state:
```typescript
const [currentPage, setCurrentPage] = useState('home');
const handleNavigate = (page: string) => setCurrentPage(page);
```

**Why not React Router?**
- Reduces bundle size
- Simpler for demonstration purposes
- Full control over navigation logic

### 2. Backend Layer (Supabase)

**Technology**: Supabase (PostgreSQL + Auth + Edge Functions)
**Deployment**: Fully managed cloud service

#### Database (PostgreSQL)

**Schema Design**:

```sql
profiles (extends auth.users)
├── id: uuid (PK, FK to auth.users)
├── email: text
├── full_name: text
├── role: text (user|admin)
└── created_at: timestamptz

products
├── id: uuid (PK)
├── name: text
├── description: text
├── price: numeric(10,2)
├── stock: integer
├── image_url: text
├── category: text
├── created_at: timestamptz
└── updated_at: timestamptz

orders
├── id: uuid (PK)
├── user_id: uuid (FK to profiles)
├── total_amount: numeric(10,2)
├── status: text (pending|processing|shipped|delivered|cancelled)
├── created_at: timestamptz
└── updated_at: timestamptz

order_items
├── id: uuid (PK)
├── order_id: uuid (FK to orders)
├── product_id: uuid (FK to products)
├── quantity: integer
├── price: numeric(10,2)
└── created_at: timestamptz
```

**Indexes** (for query performance):
- `idx_products_category` on products(category)
- `idx_orders_user_id` on orders(user_id)
- `idx_orders_status` on orders(status)
- `idx_order_items_order_id` on order_items(order_id)
- `idx_order_items_product_id` on order_items(product_id)

#### Row Level Security (RLS)

**Purpose**: Enforce data access rules at the database level

**Policy Examples**:

```sql
Products (Public Read, Admin Write):
- Anyone can view products
- Only admins can create/update/delete

Orders (User Isolation):
- Users can only see their own orders
- Admins can see all orders
- Users can only create orders for themselves

Profiles (Self-Management):
- Users can view/update only their own profile
```

**Benefits**:
- Security enforced at database level
- No way to bypass from client
- Reduces server-side logic
- Automatic with Supabase client

#### Authentication Service

**Supabase Auth Features**:
- Email/password authentication
- JWT token generation and validation
- Automatic password hashing (bcrypt)
- Session management
- Token refresh handling

**Flow**:
```
1. User registers → Supabase creates auth.users entry
2. User logs in → Supabase issues JWT token
3. Client stores token → Used for subsequent requests
4. Token expires → Automatic refresh by Supabase client
```

#### Edge Functions (Serverless API)

**Technology**: Deno runtime on Supabase Edge

**Function: create-order**
- **Purpose**: Complex order creation with transactions
- **Why serverless?**:
  - Automatically scales with demand
  - No server management required
  - Pay only for execution time
  - Global distribution (low latency)

**Logic Flow**:
```
1. Validate JWT token
2. Fetch requested products
3. Check stock availability
4. Calculate total amount
5. Create order record
6. Create order_items records
7. Decrease product stock
8. Return order confirmation
```

## Data Flow Examples

### User Registration Flow

```
Client                   Supabase Auth           Database
  │                           │                      │
  ├─ Register(email, pwd) ───►│                      │
  │                           ├─ Hash password       │
  │                           ├─ Create auth.users ─►│
  │◄─── JWT Token ────────────┤                      │
  │                           │                      │
  ├─ Create profile ──────────┼──────────────────────►│
  │                           │                      │
  │◄─── Profile created ──────┼──────────────────────┤
```

### Product Browsing Flow

```
Client                   Supabase                Database
  │                           │                      │
  ├─ GET /products ───────────┼──────────────────────►│
  │                           │                   Check RLS
  │                           │                   (Public read)
  │◄─── Products data ────────┼──────────────────────┤
```

### Order Placement Flow

```
Client              Edge Function         Database
  │                      │                    │
  ├─ POST /create-order ►│                    │
  │   (JWT + items)      ├─ Validate token    │
  │                      ├─ Check stock ──────►│
  │                      │◄── Stock data ──────┤
  │                      ├─ Create order ──────►│
  │                      ├─ Create items ──────►│
  │                      ├─ Update stock ──────►│
  │◄─── Order confirm ───┤                    │
```

## Security Architecture

### Authentication & Authorization

**Three-Layer Security**:

1. **JWT Token Validation**
   - Every protected request requires valid JWT
   - Token contains user ID and metadata
   - Automatic validation by Supabase

2. **Row Level Security**
   - Database-level access control
   - Policies check `auth.uid()`
   - Cannot be bypassed from client

3. **Role-Based Access Control**
   - User role stored in profiles table
   - Admin checks in RLS policies
   - Frontend hides/shows features based on role

### Data Protection

**At Rest**:
- PostgreSQL encryption (Supabase managed)
- Passwords hashed with bcrypt
- Environment variables for sensitive config

**In Transit**:
- HTTPS/TLS for all communications
- Secure WebSocket connections
- JWT tokens for stateless auth

**In Use**:
- XSS prevention via React's auto-escaping
- CORS properly configured
- Input validation on client and server

## Performance Optimizations

### Database
- Indexes on frequently queried columns
- Query optimization with proper JOINs
- Connection pooling (Supabase managed)

### Frontend
- Code splitting with Vite
- Lazy loading images
- localStorage for cart persistence
- Memoization of expensive computations

### Backend
- Edge Functions globally distributed
- Automatic caching by CDN
- Efficient SQL queries with proper indexes

## Scalability Considerations

### Horizontal Scaling
- **Frontend**: Static files served via CDN (Vercel)
- **Backend**: Serverless functions auto-scale
- **Database**: Supabase handles connection pooling

### Vertical Scaling
- **Database**: Supabase allows tier upgrades
- **Edge Functions**: Automatic resource allocation
- **Storage**: Unlimited static asset storage

### Load Handling
- CDN for static assets reduces origin load
- Database read replicas (available in Supabase Pro)
- Edge Functions handle burst traffic automatically

## Deployment Architecture

### Production Deployment

```
┌──────────────────────────────────────────────┐
│            Vercel Edge Network               │
│  (CDN - Static Assets & HTML)               │
└──────────────────────────────────────────────┘
                    ▼
┌──────────────────────────────────────────────┐
│          Supabase Global Network             │
│                                              │
│  ┌──────────────┐      ┌─────────────────┐ │
│  │ Edge Runtime │      │   PostgreSQL    │ │
│  │  (US, EU,    │      │   Primary DB    │ │
│  │   Asia)      │      │   (US Region)   │ │
│  └──────────────┘      └─────────────────┘ │
└──────────────────────────────────────────────┘
```

### Environment Configuration

**Development**:
- Local Vite dev server (localhost:5173)
- Supabase cloud database (dev/staging project)
- Hot module replacement for fast iteration

**Production**:
- Vercel static hosting with edge caching
- Supabase production project
- Environment variables injected at build time

## Monitoring & Observability

### Available Metrics

**Supabase Dashboard**:
- Database query performance
- API request rates
- Edge Function invocations
- Authentication events
- Storage usage

**Vercel Analytics**:
- Page load times
- User geography
- Error rates
- Build/deployment status

### Error Handling

**Frontend**:
- Try-catch blocks for async operations
- User-friendly error messages
- Console logging for debugging

**Backend**:
- Edge Function error responses
- Database constraint violations
- Authentication failures

## Cost Optimization

### Free Tier Usage
- Supabase: 500MB database, 50k monthly auth users
- Vercel: Unlimited deployments, 100GB bandwidth
- Perfect for academic projects and small MVPs

### Scaling Costs
- Database: Pay for storage and compute
- Edge Functions: Pay per invocation
- Bandwidth: Pay for data transfer

## Comparison: Traditional vs. This Architecture

### Traditional MERN Stack
```
MongoDB + Express + React + Node.js
- Requires server management
- Manual scaling configuration
- More DevOps overhead
- Separate auth implementation
```

### This Architecture (React + Supabase)
```
React + Supabase (PostgreSQL + Auth + Edge Functions)
- Fully managed services
- Automatic scaling
- Minimal DevOps
- Built-in authentication
- Same learning outcomes
- Better for cloud computing projects
```

## Academic Value

This architecture demonstrates:
1. **Cloud-native design**: Database-as-a-Service, Serverless Functions
2. **Modern security**: JWT, RLS, role-based access
3. **Scalable architecture**: CDN, edge computing, managed database
4. **RESTful APIs**: Standard HTTP methods, JSON responses
5. **Separation of concerns**: Client/server, layers, contexts
6. **Production-ready**: Deployable, secure, performant

## Further Learning

- Supabase Documentation: https://supabase.com/docs
- PostgreSQL Row Level Security: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- Edge Computing: https://www.cloudflare.com/learning/serverless/glossary/what-is-edge-computing/
- JWT Tokens: https://jwt.io/introduction
- React Context API: https://react.dev/reference/react/useContext
