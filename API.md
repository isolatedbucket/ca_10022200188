# CloudStore API Documentation

This document provides comprehensive API documentation for the CloudStore e-commerce application.

## Base URLs

- **Supabase API**: `{VITE_SUPABASE_URL}/rest/v1`
- **Edge Functions**: `{VITE_SUPABASE_URL}/functions/v1`
- **Auth API**: `{VITE_SUPABASE_URL}/auth/v1`

## Authentication

All protected endpoints require a JWT token in the Authorization header:

```
Authorization: Bearer {jwt-token}
```

The token is automatically managed by the Supabase client library.

## API Endpoints

### Authentication

#### Register User

```
POST /auth/v1/signup
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "session": {
    "access_token": "jwt-token",
    "refresh_token": "refresh-token"
  }
}
```

**Status Codes:**
- `200` - Success
- `400` - Invalid email or weak password
- `422` - User already exists

#### Login

```
POST /auth/v1/token?grant_type=password
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "access_token": "jwt-token",
  "refresh_token": "refresh-token",
  "user": {
    "id": "uuid",
    "email": "user@example.com"
  }
}
```

**Status Codes:**
- `200` - Success
- `400` - Invalid credentials

#### Logout

```
POST /auth/v1/logout
```

**Headers:**
```
Authorization: Bearer {jwt-token}
```

**Response:**
```json
{
  "message": "Successfully logged out"
}
```

### Products

#### Get All Products

```
GET /rest/v1/products?select=*
```

**Query Parameters:**
- `category=eq.electronics` - Filter by category
- `name=ilike.*search*` - Search by name
- `order=created_at.desc` - Sort by field

**Response:**
```json
[
  {
    "id": "uuid",
    "name": "Wireless Headphones",
    "description": "High-quality Bluetooth headphones",
    "price": 79.99,
    "stock": 50,
    "category": "electronics",
    "image_url": "https://...",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
]
```

**Status Codes:**
- `200` - Success
- `401` - Unauthorized (if RLS requires auth)

#### Get Single Product

```
GET /rest/v1/products?id=eq.{product-id}&select=*
```

**Response:**
```json
[
  {
    "id": "uuid",
    "name": "Wireless Headphones",
    "description": "High-quality Bluetooth headphones",
    "price": 79.99,
    "stock": 50,
    "category": "electronics",
    "image_url": "https://...",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
]
```

**Status Codes:**
- `200` - Success
- `404` - Product not found

#### Create Product (Admin Only)

```
POST /rest/v1/products
```

**Headers:**
```
Authorization: Bearer {admin-jwt-token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "name": "New Product",
  "description": "Product description",
  "price": 99.99,
  "stock": 100,
  "category": "electronics",
  "image_url": "https://..."
}
```

**Response:**
```json
{
  "id": "uuid",
  "name": "New Product",
  "description": "Product description",
  "price": 99.99,
  "stock": 100,
  "category": "electronics",
  "image_url": "https://...",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

**Status Codes:**
- `201` - Created
- `401` - Unauthorized
- `403` - Forbidden (not admin)
- `400` - Invalid data

#### Update Product (Admin Only)

```
PATCH /rest/v1/products?id=eq.{product-id}
```

**Headers:**
```
Authorization: Bearer {admin-jwt-token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "name": "Updated Product Name",
  "price": 89.99,
  "stock": 75
}
```

**Response:**
```json
{
  "id": "uuid",
  "name": "Updated Product Name",
  "price": 89.99,
  "stock": 75,
  "updated_at": "2024-01-01T00:00:00Z"
}
```

**Status Codes:**
- `200` - Success
- `401` - Unauthorized
- `403` - Forbidden (not admin)
- `404` - Product not found

#### Delete Product (Admin Only)

```
DELETE /rest/v1/products?id=eq.{product-id}
```

**Headers:**
```
Authorization: Bearer {admin-jwt-token}
```

**Response:**
```
Status: 204 No Content
```

**Status Codes:**
- `204` - Success
- `401` - Unauthorized
- `403` - Forbidden (not admin)
- `404` - Product not found

### Orders

#### Get User Orders

```
GET /rest/v1/orders?user_id=eq.{user-id}&select=*,order_items(*,products(*))
```

**Headers:**
```
Authorization: Bearer {jwt-token}
```

**Response:**
```json
[
  {
    "id": "uuid",
    "user_id": "uuid",
    "total_amount": 159.98,
    "status": "pending",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z",
    "order_items": [
      {
        "id": "uuid",
        "order_id": "uuid",
        "product_id": "uuid",
        "quantity": 2,
        "price": 79.99,
        "products": {
          "id": "uuid",
          "name": "Wireless Headphones",
          "image_url": "https://..."
        }
      }
    ]
  }
]
```

**Status Codes:**
- `200` - Success
- `401` - Unauthorized

#### Get All Orders (Admin Only)

```
GET /rest/v1/orders?select=*,order_items(*)&order=created_at.desc
```

**Headers:**
```
Authorization: Bearer {admin-jwt-token}
```

**Response:**
```json
[
  {
    "id": "uuid",
    "user_id": "uuid",
    "total_amount": 159.98,
    "status": "pending",
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

**Status Codes:**
- `200` - Success
- `401` - Unauthorized
- `403` - Forbidden (not admin)

#### Create Order (Edge Function)

```
POST /functions/v1/create-order
```

**Headers:**
```
Authorization: Bearer {jwt-token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "items": [
    {
      "product_id": "uuid",
      "quantity": 2
    },
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
    "user_id": "uuid",
    "total_amount": 159.98,
    "status": "pending",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

**Error Response:**
```json
{
  "error": "Insufficient stock for Wireless Headphones. Available: 1"
}
```

**Status Codes:**
- `200` - Success
- `400` - Invalid request or insufficient stock
- `401` - Unauthorized
- `404` - Product not found
- `500` - Server error

#### Update Order Status (Admin Only)

```
PATCH /rest/v1/orders?id=eq.{order-id}
```

**Headers:**
```
Authorization: Bearer {admin-jwt-token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "status": "processing"
}
```

**Valid Status Values:**
- `pending`
- `processing`
- `shipped`
- `delivered`
- `cancelled`

**Response:**
```json
{
  "id": "uuid",
  "status": "processing",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

**Status Codes:**
- `200` - Success
- `401` - Unauthorized
- `403` - Forbidden (not admin)
- `400` - Invalid status

### Profiles

#### Get User Profile

```
GET /rest/v1/profiles?id=eq.{user-id}&select=*
```

**Headers:**
```
Authorization: Bearer {jwt-token}
```

**Response:**
```json
[
  {
    "id": "uuid",
    "email": "user@example.com",
    "full_name": "John Doe",
    "role": "user",
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

**Status Codes:**
- `200` - Success
- `401` - Unauthorized

#### Create Profile

```
POST /rest/v1/profiles
```

**Headers:**
```
Authorization: Bearer {jwt-token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "full_name": "John Doe",
  "role": "user"
}
```

**Response:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "full_name": "John Doe",
  "role": "user",
  "created_at": "2024-01-01T00:00:00Z"
}
```

**Status Codes:**
- `201` - Created
- `401` - Unauthorized
- `409` - Profile already exists

#### Update Profile

```
PATCH /rest/v1/profiles?id=eq.{user-id}
```

**Headers:**
```
Authorization: Bearer {jwt-token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "full_name": "Jane Doe"
}
```

**Response:**
```json
{
  "id": "uuid",
  "full_name": "Jane Doe"
}
```

**Status Codes:**
- `200` - Success
- `401` - Unauthorized
- `403` - Forbidden (can only update own profile)

## Error Responses

All endpoints return errors in the following format:

```json
{
  "error": "Error message description",
  "code": "error_code",
  "details": "Additional error details"
}
```

### Common Error Codes

- `400` - Bad Request (invalid data)
- `401` - Unauthorized (missing or invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found (resource doesn't exist)
- `409` - Conflict (duplicate resource)
- `422` - Unprocessable Entity (validation error)
- `500` - Internal Server Error

## Rate Limiting

Supabase applies rate limiting based on your plan:

- **Free Tier**: 500 requests per minute
- **Pro Tier**: 5000 requests per minute

When rate limit is exceeded:
```json
{
  "error": "Too many requests",
  "code": "rate_limit_exceeded"
}
```

## Pagination

Use range headers for pagination:

```
GET /rest/v1/products?select=*
Range: 0-9
```

**Response Headers:**
```
Content-Range: 0-9/100
```

## Filtering

### Exact Match
```
GET /rest/v1/products?category=eq.electronics
```

### Pattern Matching
```
GET /rest/v1/products?name=ilike.*headphones*
```

### Range
```
GET /rest/v1/products?price=gte.50&price=lte.100
```

### Multiple Conditions
```
GET /rest/v1/products?category=eq.electronics&price=lt.100
```

## Ordering

```
GET /rest/v1/products?order=price.asc
GET /rest/v1/products?order=created_at.desc
```

## Relationships

Fetch related data:

```
GET /rest/v1/orders?select=*,order_items(*,products(*))
```

## Using with JavaScript (Supabase Client)

### Initialize Client

```javascript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  SUPABASE_URL,
  SUPABASE_ANON_KEY
);
```

### Fetch Products

```javascript
const { data, error } = await supabase
  .from('products')
  .select('*')
  .eq('category', 'electronics');
```

### Create Order

```javascript
const { data: session } = await supabase.auth.getSession();

const response = await fetch(
  `${SUPABASE_URL}/functions/v1/create-order`,
  {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ items: cartItems }),
  }
);
```

### Update Product (Admin)

```javascript
const { data, error } = await supabase
  .from('products')
  .update({ stock: 100 })
  .eq('id', productId);
```

## Testing APIs

### Using cURL

**Get Products:**
```bash
curl https://your-project.supabase.co/rest/v1/products \
  -H "apikey: your-anon-key"
```

**Create Order:**
```bash
curl -X POST https://your-project.supabase.co/functions/v1/create-order \
  -H "Authorization: Bearer your-jwt-token" \
  -H "Content-Type: application/json" \
  -d '{"items":[{"product_id":"uuid","quantity":1}]}'
```

### Using Postman

1. Create a new request
2. Set URL to endpoint
3. Add headers:
   - `apikey: {your-anon-key}`
   - `Authorization: Bearer {jwt-token}`
4. Set body (for POST/PATCH)
5. Send request

## Best Practices

1. **Always use the Supabase client** instead of direct HTTP calls when possible
2. **Cache frequently accessed data** (products) in frontend
3. **Handle errors gracefully** with user-friendly messages
4. **Use transactions** for multi-step operations (handled by Edge Functions)
5. **Validate input** on both client and server
6. **Monitor API usage** in Supabase dashboard
7. **Keep JWT tokens secure** - never expose in logs or URLs

## Security Notes

1. Row Level Security is enforced at the database level
2. Admin operations require `role = 'admin'` in profiles table
3. JWT tokens expire after 1 hour (automatically refreshed)
4. All passwords are hashed using bcrypt
5. CORS is configured for your frontend domain

## Support

- Supabase API Docs: https://supabase.com/docs/guides/api
- PostgREST Docs: https://postgrest.org/
- Edge Functions: https://supabase.com/docs/guides/functions
